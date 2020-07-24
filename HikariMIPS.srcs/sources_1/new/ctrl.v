//////////////////////////////////////////////////////////////////////////////////
// CTRL��ˮ�߿���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"
////////////////////////////////
// 0 |    1    |    2    |    3    |    4    |    5    |    6    |
//pc |  if_id  | id_mux  | mux_ex  |  ex_mem |  mem_wb |   wb    |
module ctrl(
    input wire clk,
    input wire rst,

    input wire stallreq_from_mux,
    input wire stallreq_from_ex,
    //��֧Ԥ�����ʱ��pc��������
    input wire flush_pc_i,
    // stall <= {WB, MEM, EX, MUX, ID, IF, PC}
    output reg[6:0] stall,
    output reg flush_pc_o,//�����ˮ��pc�ź�

    // �쳣
    input wire[`RegBus] cp0_epc_i,
    input wire exception_occured_i,
    input wire[4:0] exc_code_i,
    output reg[`RegBus] epc_o,
    output reg flush
);
    always @ (*) begin
        stall <= 7'b0000000;
        flush <= 1'b0;
        if(rst == `RstEnable) begin
            epc_o <= `ZeroWord;
        end else if(exception_occured_i) begin
            // ���쳣
            flush <= 1'b1;
            case (exc_code_i)
                // �����쳣�����ж�pcҪд���ֵ
                5'h10: begin
                    // ERET����
                    epc_o <= cp0_epc_i;
                end 
                default: begin
                    // �����쳣ͳһ���
                    epc_o <= 32'h00000040; // TODO
                end
            endcase
        end else if(stallreq_from_ex == `Stop) begin
            stall <= 7'b0011111;
        end else if(stallreq_from_mux == `Stop) begin
            stall <= 7'b0001111;            
        end else begin
            stall <= 7'b0000000;
        end
    end

endmodule