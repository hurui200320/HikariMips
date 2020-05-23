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
    output reg[`RegAddrBus] waddr_o,
    output reg we_o,
    output reg[`RegBus] wdata_o,

    output reg we_hilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o
    );

    reg[`RegBus] logic_result;
    reg[`RegBus] shift_result;
    reg[`RegBus] move_result;

    // 这里存储排除数据相关后的HI/LO寄存器值
    reg[`RegBus] HI;
    reg[`RegBus] LO;

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
                default : begin
                end
            endcase
        end
    end

    // 数据移动，写HI/LO部分，只涉及MTxx指令
    always @ (*) begin
        if(rst == `RstEnable) begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;        
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
        we_o <= we_i;
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
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule
