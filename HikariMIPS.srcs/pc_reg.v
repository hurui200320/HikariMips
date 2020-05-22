//////////////////////////////////////////////////////////////////////////////////
// PC���������
// ���ֽڼ���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst, 

    output reg[`InstAddrBus] pc,
    // ָ��洢��ʹ���ź�
    output reg ce
    );

    // �ȴ���λ�ź�
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

    // �����鲢��ִ��
    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= `ZeroWord;
        end else begin
            pc <= pc + 4'h4;
        end
    end
    
endmodule
