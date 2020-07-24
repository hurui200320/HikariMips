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
    input wire[`RegBus] pc_i,
    input wire[`RegBus] exceptions_i,

    // hi/LO寄存器
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,

    
    // 延迟槽和跳转
    input wire[`RegBus] link_address_i,
    input wire is_in_delayslot_i,

    // CP0寄存器
    input wire[`RegBus] cp0_rdata_i,


    output reg cp0_we_o,
    output reg[7:0] cp0_waddr_o,
    output reg[`RegBus] cp0_wdata_o,

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

    // 异常
    output wire[`RegBus] pc_o,
    output wire[`RegBus] exceptions_o,
    output wire is_in_delayslot_o,

    // 除法模块
    input wire[`DoubleRegBus] div_result_i,
    input wire div_ready_i,
    output reg[`RegBus] div_opdata1_o,
    output reg[`RegBus] div_opdata2_o,
    output reg div_start_o,
    output reg signed_div_o,
    
    // 乘法模块
    input wire[`DoubleRegBus] mult_result_i,
    input wire mult_ready_i,
    output reg[`RegBus] mult_opdata1_o,
    output reg[`RegBus] mult_opdata2_o,
    output reg mult_start_o,
    output reg signed_mult_o,

    output reg stallreq
    );

    reg trap_occured;
    reg overflow_occured;
    assign pc_o = pc_i;
    assign is_in_delayslot_o = is_in_delayslot_i;
    // IF ID使用了低五位，这里第六、七位表示溢出和自陷，其余应当为0
    assign exceptions_o = {exceptions_i[31:7], trap_occured, overflow_occured, exceptions_i[4:0]};

    reg[`RegBus] logic_result;
    reg[`RegBus] shift_result;
    reg[`RegBus] move_result;
    reg[`RegBus] arithmetic_result;

    reg stallreq_for_div; // 因除法暂停流水线
    reg stallreq_for_mult; // 因乘法暂停流水线

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

    // 数据移动，写Regfile部分，只涉及MFxx指令
    wire[7:0] cp0_addr = {inst_i[15:11], inst_i[2:0]};
    always @ (*) begin
        if(rst == `RstEnable) begin
            move_result <= `ZeroWord;
        end else begin
            move_result <= `ZeroWord;
            case (aluop_i)
                `ALU_OP_MFHI: begin
                    move_result <= hi_i;
                end
                `ALU_OP_MFLO: begin
                    move_result <= lo_i;
                end
                `ALU_OP_MOV: begin
                    move_result <= reg1_i;
                end
                `ALU_OP_MFC0: begin
                    move_result <= cp0_rdata_i;
                end
                default : begin
                end
            endcase
        end
    end

    // 算数运算部分
    // 首先计算出第二个操作数，即减法和SLT（小于置1）时相当于+[-y]补
    wire[`RegBus] reg2_i_mux = ( aluop_i == `ALU_OP_SUB 
                                || aluop_i == `ALU_OP_SUBU
                                || aluop_i == `ALU_OP_SLT 
                                || aluop_i == `ALU_OP_TLT 
                                || aluop_i == `ALU_OP_TGE ) ? ~reg2_i + 1 : reg2_i;
    // 计算加减和，如果是加法，则这里是求和，如果是减法或比较，则这里就是差
    wire[`RegBus] result_sum = reg1_i + reg2_i_mux;
    // 检查溢出：两数为正和为负，及两数为负和为正
    wire sum_overflow = (!reg1_i[31] && !reg2_i_mux && result_sum[31]) || ( reg1_i[31] && reg2_i_mux[31] && !result_sum[31]);
    // reg1是否小于reg2，情况有两种
    // 有符号数看reg1 2的符号和result_sum的符号，其中一负一正则必然小于
    // 无符号数直接比较两者符号
    wire reg1_lt_reg2 = (aluop_i == `ALU_OP_SLTU || aluop_i == `ALU_OP_TLTU || aluop_i == `ALU_OP_TGEU ) ? (reg1_i < reg2_i) : ( (reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31]) );
    // reg1取反
    wire[`RegBus] reg1_not = ~reg1_i;

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
                default: begin
                    arithmetic_result <= `ZeroWord;
                end
            endcase
        end
    end
    // 利用上面的结果判断是否自陷
    always @ (*) begin
        if (rst == `RstEnable) begin
            trap_occured <= `False_v;
        end else begin
            case (aluop_i)
                // TEQ TEQI
                `ALU_OP_TEQ: begin
                    trap_occured <= (reg1_i == reg2_i);
                end 
                // TEG TEGI TEGU TEGIU
                `ALU_OP_TGE, `ALU_OP_TGEU: begin
                    trap_occured <= (~reg1_lt_reg2); // not less than -> great equal than
                end
                // TLT TLTU TLTI TLTIU
                `ALU_OP_TLT, `ALU_OP_TLTU: begin
                    trap_occured <= reg1_lt_reg2;
                end
                // TNE TNEI
                `ALU_OP_TNE: begin
                    trap_occured <= (reg1_i != reg2_i);
                end
                default: begin
                    trap_occured <= `False_v; // 默认没有
                end
            endcase
        end
    end

    // 处理乘法
    always @ (*) begin
        if(rst == `RstEnable) begin
            stallreq_for_mult <= `NoStop;
            mult_opdata1_o <= `ZeroWord;
            mult_opdata2_o <= `ZeroWord;
            mult_start_o <= `ComputeStop;
            signed_mult_o <= 1'b0;
        end else begin
            stallreq_for_mult <= `NoStop;
            mult_opdata1_o <= `ZeroWord;
            mult_opdata2_o <= `ZeroWord;
            mult_start_o <= `ComputeStop;
            signed_mult_o <= 1'b0;     
            case (aluop_i) 
                `ALU_OP_MULT, `ALU_OP_MUL, `ALU_OP_MADD, `ALU_OP_MSUB: begin
                    if(mult_ready_i == `ResultNotReady) begin
                        mult_opdata1_o <= reg1_i;
                        mult_opdata2_o <= reg2_i;
                        mult_start_o <= `ComputeStart;
                        signed_mult_o <= 1'b1;
                        stallreq_for_mult <= `Stop;
                    end else if(mult_ready_i == `ResultReady) begin
                        mult_opdata1_o <= reg1_i;
                        mult_opdata2_o <= reg2_i;
                        mult_start_o <= `ComputeStop;
                        signed_mult_o <= 1'b1;
                        stallreq_for_mult <= `NoStop;
                    end else begin
                        mult_opdata1_o <= `ZeroWord;
                        mult_opdata2_o <= `ZeroWord;
                        mult_start_o <= `ComputeStop;
                        signed_mult_o <= 1'b0;
                        stallreq_for_mult <= `NoStop;
                    end                         
                end
                `ALU_OP_MULTU, `ALU_OP_MADDU, `ALU_OP_MSUBU: begin
                    if(mult_ready_i == `ResultNotReady) begin
                        mult_opdata1_o <= reg1_i;
                        mult_opdata2_o <= reg2_i;
                        mult_start_o <= `ComputeStart;
                        signed_mult_o <= 1'b0;
                        stallreq_for_mult <= `Stop;
                    end else if(mult_ready_i == `ResultReady) begin
                        mult_opdata1_o <= reg1_i;
                        mult_opdata2_o <= reg2_i;
                        mult_start_o <= `ComputeStop;
                        signed_mult_o <= 1'b0;
                        stallreq_for_mult <= `NoStop;
                    end else begin
                        mult_opdata1_o <= `ZeroWord;
                        mult_opdata2_o <= `ZeroWord;
                        mult_start_o <= `ComputeStop;
                        signed_mult_o <= 1'b0;
                        stallreq_for_mult <= `NoStop;
                    end                         
                end
                default: begin
                end
            endcase
        end
    end

    // 处理累加累减乘法
    reg[`DoubleRegBus] accu_temp;
    always @ (*) begin
        if (rst == `RstEnable) begin
            // 复位
            accu_temp <= {`ZeroWord, `ZeroWord};
        end else begin
            case (aluop_i)
                // MADD MADDU
                `ALU_OP_MADD, `ALU_OP_MADDU: begin
                    // 等待乘法结束
                    if (stallreq_for_mult != `Stop) begin
                        // 累加
                        accu_temp <= mult_result_i + {hi_i, lo_i};
                    end begin
                        // do nothing
                    end
                end 
                // MSUB MSUBU
                `ALU_OP_MSUB, `ALU_OP_MSUBU: begin
                    // 等待乘法结束
                    if (stallreq_for_mult != `Stop) begin
                        accu_temp <= ~mult_result_i + 1 + {hi_i, lo_i}; // 累减
                    end begin
                        // do nothing
                    end
                end 
                default: begin
                    // 非累加指令，同复位
                    accu_temp <= {`ZeroWord, `ZeroWord};
                end
            endcase
        end
    end

    // 处理除法
    always @ (*) begin
        if(rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `ComputeStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `ComputeStop;
            signed_div_o <= 1'b0;     
            case (aluop_i) 
                `ALU_OP_DIV: begin
                    if(div_ready_i == `ResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `ComputeStart;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `ResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `ComputeStop;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `ComputeStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                         
                end
                `ALU_OP_DIVU: begin
                    if(div_ready_i == `ResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `ComputeStart;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `ResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `ComputeStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `ComputeStop;
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
        stallreq = stallreq_for_div || stallreq_for_mult;
    end

    // 数据移动，写HI/LO部分，只涉及MTHI/LO指令
    // 同时负责写入乘除法结果
    always @ (*) begin
        if(rst == `RstEnable) begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end else if(aluop_i == `ALU_OP_MULT || aluop_i == `ALU_OP_MULTU) begin
            // 是乘法，结果写入HILO，MUL指令除外
            we_hilo_o <= `WriteEnable;
            hi_o <= mult_result_i[63:32];
            lo_o <= mult_result_i[31:0];
        end else if (aluop_i == `ALU_OP_DIV || aluop_i == `ALU_OP_DIVU) begin
            // 除法 高32位是商，低32位是余数
            we_hilo_o <= `WriteEnable;
            hi_o <= div_result_i[31:0];
            lo_o <= div_result_i[63:32];
        end else if (aluop_i == `ALU_OP_MADD || aluop_i == `ALU_OP_MADDU || aluop_i == `ALU_OP_MSUB || aluop_i == `ALU_OP_MSUBU) begin
            // 累加、累减
            we_hilo_o <= `WriteEnable;
            hi_o <= accu_temp[63:32];
            lo_o <= accu_temp[31:0];
            // 这里在各阶段都会传递出accu_temp写入HILO
            // 但是流水线暂停使得EX/MEM传出NOP，取消暂停之后正常传出accu_temp
        end else if(aluop_i == `ALU_OP_MTHI) begin
            we_hilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= lo_i;
        end else if(aluop_i == `ALU_OP_MTLO) begin
            we_hilo_o <= `WriteEnable;
            hi_o <= hi_i;
            lo_o <= reg1_i;
        end else begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end                
    end

    // 数据移动，写CP0部分，只涉及MTC0指令
    always @ (*) begin
        if (rst == `RstEnable) begin
            cp0_waddr_o <= 8'b00000000;
            cp0_we_o <= `WriteDisable;
            cp0_wdata_o <= `ZeroWord;
        end else if (aluop_i == `ALU_OP_MTC0) begin
            cp0_waddr_o <= cp0_addr;
            cp0_we_o <= `WriteEnable;
            cp0_wdata_o <= reg1_i;
        end else begin
            cp0_waddr_o <= 8'b00000000;
            cp0_we_o <= `WriteDisable;
            cp0_wdata_o <= `ZeroWord;
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
            overflow_occured <= `True_v;
        end else begin
            we_o <= we_i;
            overflow_occured <= `False_v;
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
                wdata_o <= mult_result_i[31:0];
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule
