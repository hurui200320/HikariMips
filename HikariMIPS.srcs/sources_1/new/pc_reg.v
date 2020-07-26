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
    output reg ce
    );
    
    // �����ô������ź�ce
    always @ (*) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
            exceptions_o <= `ZeroWord;
        end else begin
            // ��������branchд�룬Ȼ���pc�жϡ���������JR 0x1233�������쳣
            // ������ȡ0x1233������Ϊ�쳣��MEM�׶ο���ֱ�Ӷ�ȡPC=0x1233��ΪBadVAddr
            // Ҳ����ͨ����������exceptionsλ����ʾ��ת�쳣����ͨ���µ��ź������ݸõ�ַ
            // ���й��ܲ��Գ��ڴ��븴���ԵĿ��ǣ����޸����⣬�����Ż�ʱ��˵
            ce <= (pc[1:0] == 2'b00) ? `ChipEnable : `ChipDisable;
            exceptions_o[0] <= (pc[1:0] != 2'b00) ? 1'b1 : 1'b0;
        end
    end
    
    // �޸�PC
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            pc <= 32'hbfc00000;
        end else if (flush) begin
            // �����쳣��ʹ��epc��ֵ
            if (stall[0] == `Stop) begin
                pc <= epc - 4'h4;
            end else begin
                pc <= epc;
            end
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
