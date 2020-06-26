//////////////////////////////////////////////////////////////////////////////////
// 执行阶段
// 内含ALU功能
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ex(
    input wire clk,
    input wire rst,
    
    //送到执行阶段的信息
    input wire[`AluOpBus] aluop_i,
    input wire[`AluSelBus] alusel_i,
    input wire[`RegBus] reg1_i,
    input wire[`RegBus] reg2_i,
    input wire[`RegAddrBus] waddr_i,
    input wire we_i,
    input wire[`RegBus] inst_i,

    // hi/LO寄存器
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,

    // 来自访存与回写的反馈，同ID模块解决数据相关的思路
    input wire[`RegBus] wb_hi_i,
    input wire[`RegBus] wb_lo_i,
    input wire wb_we_hilo_i,
    
    input wire[`RegBus] mem_hi_i,
    input wire[`RegBus] mem_lo_i,
    input wire mem_we_hilo_i,

    // 送到访存阶段的信息
    // 访存转给写回的数据
    output reg[`RegAddrBus] waddr_o,
    output reg we_o,
    output reg[`RegBus] wdata_o,
    output reg we_hilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,
    // 决定访存模块行为的参数
    output wire[`AluOpBus] aluop_o,
    output wire[`RegBus] mem_addr_o,
    // rt寄存器内容，LWL这些命令修改寄存器的一部分
    output wire[`RegBus] reg2_o, 

    // 延迟槽和跳转
    input wire[`RegBus] link_address_i,
    input wire is_in_delayslot_i, // 这个是异常处理部分使用的，目前尚未实装

    // 除法模块
    input wire[`DoubleRegBus] div_result_i,
    input wire div_ready_i,

    output reg[`RegBus] div_opdata1_o,
    output reg[`RegBus] div_opdata2_o,
    output reg div_start_o,
    output reg signed_div_o,

    output reg stallreq // TODO 实现除法和累加乘法时
    );

    reg[`RegBus] logic_result;
    reg[`RegBus] shift_result;
    reg[`RegBus] move_result;
    reg[`RegBus] arithmetic_result;
    reg[`DoubleRegBus] mult_result;

    reg stallreq_for_div; // 因除法暂停流水线   

    // 这里存储排除数据相关后的HI/LO寄存器值
    reg[`RegBus] HI;
    reg[`RegBus] LO;

    // 传递到MEM的参数
    assign aluop_o = aluop_i;
    // reg1_i = base，与低16位offset有符号拓展后相加
    assign mem_addr_o = reg1_i + { {16{inst_i[15]}}, inst_i[15:0]};
    // 被覆盖的寄存器原内容，供LWL等指令使用
    assign reg2_o = reg2_i;

    // 组合逻辑电路，对所有信号敏感
    // 逻辑运算
    always @ (*) begin
        if(rst == `RstEnable) begin
            logic_result <= `ZeroWord;
        end else begin
        case (aluop_i)
            `ALU_OP_OR: begin
                logic_result <= reg1_i | reg2_i;
            end
            `ALU_OP_AND: begin
                logic_result <= reg1_i & reg2_i;
            end
            `ALU_OP_NOR: begin
                logic_result <= ~(reg1_i | reg2_i);
            end
            `ALU_OP_XOR: begin
                logic_result <= reg1_i ^ reg2_i;
            end
            default: begin
                logic_result <= `ZeroWord;
            end
        endcase
        end
    end

    // 位移运算
    always @ (*) begin
        if(rst == `RstEnable) begin
            shift_result <= `ZeroWord;
        end else begin
        case (aluop_i)
            `ALU_OP_SLL: begin
                shift_result <= reg2_i << reg1_i[4:0];
            end
            `ALU_OP_SRL: begin
                shift_result <= reg2_i >> reg1_i[4:0];
            end
            `ALU_OP_SRA: begin
                // 先根据符号位计算出补的部分，左移是为了方便与计算结果拼接
                shift_result <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
            end
            default: begin
                shift_result <= `ZeroWord;
            end
        endcase
        end
    end

    // 排除HI/LO数据相关
    always @ (*) begin
        if(rst == `RstEnable) begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
        end else if(mem_we_hilo_i == `WriteEnable) begin
            {HI,LO} <= {mem_hi_i,mem_lo_i};
        end else if(wb_we_hilo_i == `WriteEnable) begin
            {HI,LO} <= {wb_hi_i,wb_lo_i};
        end else begin
            {HI,LO} <= {hi_i,lo_i};            
        end
    end

    // 数据移动，写Regfile部分，只涉及MFxx指令
    always @ (*) begin
        if(rst == `RstEnable) begin
            move_result <= `ZeroWord;
        end else begin
            move_result <= `ZeroWord;
            case (aluop_i)
                `ALU_OP_MFHI: begin
                    move_result <= HI;
                end
                `ALU_OP_MFLO: begin
                    move_result <= LO;
                end
                `ALU_OP_MOV: begin
                    move_result <= reg1_i;
                end
                default : begin
                end
            endcase
        end
    end

    // 算数运算部分
    // 首先计算出第二个操作数，即减法和SLT（小于置1）时相当于+[-y]补
    wire[`RegBus] reg2_i_mux;
    assign reg2_i_mux = ( aluop_i == `ALU_OP_SUB || aluop_i == `ALU_OP_SUBU || aluop_i == `ALU_OP_SLT ) ? ~reg2_i + 1 : reg2_i;
    // 计算加减和，如果是加法，则这里是求和，如果是减法或比较，则这里就是差
    wire[`RegBus] result_sum;
    assign result_sum = reg1_i + reg2_i_mux;
    // 检查溢出：两数为正和为负，及两数为负和为正
    wire sum_overflow;
    assign sum_overflow = (!reg1_i[31] && !reg2_i_mux && result_sum[31]) || ( reg1_i[31] && reg2_i_mux[31] && !result_sum[31]);
    // reg1是否小于reg2，情况有两种
    // 有符号数看reg1 2的符号和result_sum的符号，其中一负一正则必然小于
    // 无符号数直接比较两者符号
    wire reg1_lt_reg2;
    assign reg1_lt_reg2 = (aluop_i == `ALU_OP_SLTU) ? (reg1_i < reg2_i) : ( (reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31]) );
    // reg1取反
    wire[`RegBus] reg1_not;
    assign reg1_not = ~reg1_i;

    // 产生简单运算结果
    always @ (*) begin
        if(rst == `RstEnable) begin
            arithmetic_result <= `ZeroWord;
        end else begin
            case (aluop_i)
                `ALU_OP_SLT, `ALU_OP_SLTU: begin
                    arithmetic_result <= reg1_lt_reg2 ;
                end
                `ALU_OP_ADD, `ALU_OP_ADDU: begin
                    arithmetic_result <= result_sum; 
                end
                `ALU_OP_SUB, `ALU_OP_SUBU: begin
                    arithmetic_result <= result_sum; 
                end
                `ALU_OP_CLZ: begin
                    arithmetic_result <= reg1_i[31] ? 0 : 
                                         reg1_i[30] ? 1 : 
                                         reg1_i[29] ? 2 :
                                         reg1_i[28] ? 3 : 
                                         reg1_i[27] ? 4 : 
                                         reg1_i[26] ? 5 :
                                         reg1_i[25] ? 6 : 
                                         reg1_i[24] ? 7 : 
                                         reg1_i[23] ? 8 : 
                                         reg1_i[22] ? 9 : 
                                         reg1_i[21] ? 10 : 
                                         reg1_i[20] ? 11 :
                                         reg1_i[19] ? 12 : 
                                         reg1_i[18] ? 13 : 
                                         reg1_i[17] ? 14 : 
                                         reg1_i[16] ? 15 : 
                                         reg1_i[15] ? 16 : 
                                         reg1_i[14] ? 17 : 
                                         reg1_i[13] ? 18 : 
                                         reg1_i[12] ? 19 : 
                                         reg1_i[11] ? 20 :
                                         reg1_i[10] ? 21 : 
                                         reg1_i[9] ? 22 : 
                                         reg1_i[8] ? 23 : 
                                         reg1_i[7] ? 24 : 
                                         reg1_i[6] ? 25 : 
                                         reg1_i[5] ? 26 : 
                                         reg1_i[4] ? 27 : 
                                         reg1_i[3] ? 28 : 
                                         reg1_i[2] ? 29 : 
                                         reg1_i[1] ? 30 : 
                                         reg1_i[0] ? 31 : 32 ;
                end
                `ALU_OP_CLO: begin
                    arithmetic_result <= reg1_not[31] ? 0 :
                                         reg1_not[30] ? 1 :
                                         reg1_not[29] ? 2 :
                                         reg1_not[28] ? 3 :
                                         reg1_not[27] ? 4 : 
                                         reg1_not[26] ? 5 :
                                         reg1_not[25] ? 6 :
                                         reg1_not[24] ? 7 : 
                                         reg1_not[23] ? 8 : 
                                         reg1_not[22] ? 9 :
                                         reg1_not[21] ? 10 : 
                                         reg1_not[20] ? 11 :
                                         reg1_not[19] ? 12 : 
                                         reg1_not[18] ? 13 : 
                                         reg1_not[17] ? 14 : 
                                         reg1_not[16] ? 15 : 
                                         reg1_not[15] ? 16 : 
                                         reg1_not[14] ? 17 : 
                                         reg1_not[13] ? 18 : 
                                         reg1_not[12] ? 19 : 
                                         reg1_not[11] ? 20 :
                                         reg1_not[10] ? 21 : 
                                         reg1_not[9] ? 22 : 
                                         reg1_not[8] ? 23 : 
                                         reg1_not[7] ? 24 : 
                                         reg1_not[6] ? 25 : 
                                         reg1_not[5] ? 26 : 
                                         reg1_not[4] ? 27 : 
                                         reg1_not[3] ? 28 : 
                                         reg1_not[2] ? 29 : 
                                         reg1_not[1] ? 30 : 
                                         reg1_not[0] ? 31 : 32 ;
                end
                default: begin
                    arithmetic_result <= `ZeroWord;
                end
            endcase
        end
    end

    // 计算修正的乘法运算数，如果是有符号乘法且参数为负，求补码
    wire[`RegBus] opdata1_mult;
    assign opdata1_mult = ( aluop_i == `ALU_OP_MULT && reg1_i[31]) ? ~reg1_i + 1 : reg1_i;
    wire[`RegBus] opdata2_mult;
    assign opdata2_mult = ( aluop_i == `ALU_OP_MULT && reg2_i[31]) ? ~reg2_i + 1 : reg2_i;
    // 计算乘法
    wire[`DoubleRegBus] hilo_temp;
    assign hilo_temp = opdata1_mult * opdata2_mult;
    // 对结果修正并产生乘法结果
    always @ (*) begin
        if(rst == `RstEnable) begin
            mult_result <= {`ZeroWord,`ZeroWord};
        end else if (aluop_i == `ALU_OP_MULT)begin
            // 如果是有符号乘法，且两操作数一正一负
            if(reg1_i[31] ^ reg2_i[31]) begin
                // 结果也应该是负，对结果求补码
                mult_result <= ~hilo_temp + 1;
            end else begin
                mult_result <= hilo_temp;
            end
        end else begin
                mult_result <= hilo_temp;
        end
    end

    // 处理除法
    always @ (*) begin
        if(rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;     
            case (aluop_i) 
                `ALU_OP_DIV: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                         
                end
                `ALU_OP_DIVU: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                         
                end
                default: begin
                end
            endcase
        end
    end

    // 处理暂停请求
    always @ (*) begin
        // 各可能的暂停请求之或
        stallreq = stallreq_for_div;
    end

    // 数据移动，写HI/LO部分，只涉及MTxx指令
    // 同时负责写入乘除法结果
    always @ (*) begin
        if(rst == `RstEnable) begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end else if(alusel_i != `ALU_SEL_MUL && (aluop_i == `ALU_OP_MULT || aluop_i == `ALU_OP_MULTU)) begin
            // 是乘法，结果写入HILO，MUL指令除外
            we_hilo_o = `WriteEnable;
            hi_o <= mult_result[63:32];
            lo_o <= mult_result[31:0];
        end else if (aluop_i == `ALU_OP_DIV || aluop_i == `ALU_OP_DIVU) begin
            // 除法
            we_hilo_o <= `WriteEnable;
            hi_o <= div_result_i[63:32];
            lo_o <= div_result_i[31:0];
        end else if(aluop_i == `ALU_OP_MTHI) begin
            we_hilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= LO;
        end else if(aluop_i == `ALU_OP_MTLO) begin
            we_hilo_o <= `WriteEnable;
            hi_o <= HI;
            lo_o <= reg1_i;
        end else begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end                
    end

    // 按照运算类型选择一个结果输出
    always @ (*) begin
        // 传递写相关信号
        waddr_o <= waddr_i;
        // 是有符号运算则检查溢出（参考MIPS指令集手册）
        if((aluop_i == `ALU_OP_ADD || aluop_i == `ALU_OP_SUB) && sum_overflow) begin
            // 有溢出则禁止写 + 产生例外/异常
            we_o <= `WriteDisable;
        end else begin
            we_o <= we_i;
        end
        case (alusel_i) 
            `ALU_SEL_LOGIC: begin
                wdata_o <= logic_result;
            end
            `ALU_SEL_SHIFT: begin
                wdata_o <= shift_result;
            end   
            `ALU_SEL_MOVE: begin
                wdata_o <= move_result;
            end   
            `ALU_SEL_ARITHMETIC: begin
                wdata_o <= arithmetic_result;
            end   
            `ALU_SEL_JUMP_BRANCH: begin
                // 写保存地址，实际是否写由ID产生的we_o决定
                wdata_o <= link_address_i;
            end
            `ALU_SEL_MUL: begin
                // 写寄存器的乘法
                wdata_o <= mult_result[31:0];
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule
