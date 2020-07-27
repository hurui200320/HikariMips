//////////////////////////////////////////////////////////////////////////////////
// PC���������
// ���ֽڼ���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst, 

    (*mark_debug = "true"*)input wire[5:0] stall,

    // ��֧��ת�ź�
    (*mark_debug = "true"*)input wire is_branch_i,
    (*mark_debug = "true"*)input wire[`RegBus] branch_target_address_i,

    // �쳣
    (*mark_debug = "true"*)input wire flush,
    (*mark_debug = "true"*)input wire[`RegBus] epc,
    (*mark_debug = "true"*)output wire[31:0] exceptions_o,

    (*mark_debug = "true"*)output reg[`RegBus] pc,
    (*mark_debug = "true"*)output wire ce
    );

    assign ce = (pc[1:0] == 2'b00) ? `ChipEnable : `ChipDisable;
    assign exceptions_o = (pc[1:0] != 2'b00) ? 1'b1 : 1'b0;
    
    // �޸�PC
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            pc <= 32'hbfc00000;
        end else if (flush) begin
            // �����쳣��ʹ��epc��ֵ
            if (stall[0] == `Stop) begin
                pc <= epc - 4;
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
