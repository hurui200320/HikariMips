//////////////////////////////////////////////////////////////////////////////////
// ִ�н׶�
// �ں�ALU����
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ex(
    input wire clk,
    input wire rst,
    
    //�͵�ִ�н׶ε���Ϣ
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

    // ����߼���·���������ź�����
    // ��һ��ִ���߼����㣬��������ɷ��մ˽ṹ���һ��always
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

    // ������������ѡ��һ��������
    always @ (*) begin
        // ����д����ź�
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
