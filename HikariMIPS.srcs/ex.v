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

    output reg[`RegAddrBus] waddr_o,
    output reg we_o,
    output reg[`RegBus] wdata_o
    );

    reg[`RegBus] logicout;

    // 组合逻辑电路，对所有信号敏感
    // 这一块执行逻辑运算，其他运算可仿照此结构另加一块always
    always @ (*) begin
        if(rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
        case (aluop_i)
            `ALU_OP_OR: begin
                logicout <= reg1_i | reg2_i;
            end
            default: begin
                logicout <= `ZeroWord;
            end
        endcase
        end
    end

    // 按照运算类型选择一个结果输出
    always @ (*) begin
        // 传递写相关信号
        waddr_o <= waddr_i;
        we_o <= we_i;
        case (alusel_i) 
            `ALU_SEL_LOGIC: begin
                wdata_o <= logicout;
            end
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule
