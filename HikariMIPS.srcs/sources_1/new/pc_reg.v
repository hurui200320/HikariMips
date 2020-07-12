//////////////////////////////////////////////////////////////////////////////////
// PC���������
// ���ֽڼ���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst, 

    input wire[5:0] stall,

    // ��֧��ת�ź�
    input wire is_branch_i,
    input wire[`RegBus] branch_target_address_i,

    // �쳣
    input wire flush,
    input wire[`RegBus] epc,
    output reg[31:0] exceptions_o,

    output reg[`RegBus] pc,
    // ָ��洢��ʹ���ź�
    output reg ce
    );

    // �ȴ���λ�ź�
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
            exceptions_o <= `ZeroWord;
        end else begin
            if (pc[1:0] == 2'b00) begin
                // ��ַ����
                ce <= `ChipEnable;
                exceptions_o[0] <= 1'b0;
            end else begin
                // ��ַδ����
                ce <= `ChipDisable;
                exceptions_o[0] <= 1'b1;
            end
        end
    end
    
    // TODO ȡָ��ַδ���������AdEL�쳣

    // �����鲢��ִ��
    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= `ZeroWord;
        end else if (flush) begin
            // �����쳣��ʹ��epc��ֵ
            pc <= epc;
        end else if (stall[0] == `NoStop) begin
            // IFδ��ͣ
            if(is_branch_i) begin
                pc <= branch_target_address_i;
            end else begin
                pc <= pc + 4'h4;
            end
        end else begin
        end
    end
    
endmodule
