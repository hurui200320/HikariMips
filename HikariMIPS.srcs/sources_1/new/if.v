`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// IF
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module sram_if(
    input wire clk,
    input wire rst, 

    input wire[5:0] stall,

    // ��֧��ת�ź�
    input wire is_branch_i,
    input wire[`RegBus] branch_target_address_i,

    // �쳣
    input wire flush,
    input wire[`RegBus] epc,
    output wire[31:0] exceptions_o,

    output wire[`RegBus] pc,
    
    // ָ��洢��ʹ���ź�
    output wire req,
    input wire addr_ok,
    input wire data_ok,

    output reg stallreq
    );
    wire ce;

    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst), 
        .stall(stall),
        .is_branch_i(is_branch_i),
        .branch_target_address_i(branch_target_address_i),

        .flush(flush),
        .epc(epc),
        .exceptions_o(exceptions_o),

        .pc(pc),
        .ce(ce)
    );
    
    reg req_en;
    assign req = ce & req_en;

    reg[1:0] status;

    // ����״̬��
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            req_en <= `False_v;
            status <= 2'b00;
        end else begin
            case (status)
                2'b00: begin // ���н׶�
                    if (ce && !flush) begin
                        // ���CE���ã�Ҫ���ʣ�����flush�ź�
                        // ����ȴ���ַ���ֽ׶�
                        req_en <= `True_v;
                        status <= 2'b01;
                    end else begin
                        // ԭ�صȴ�
                        req_en <= `False_v;
                    end
                end
                2'b01: begin // �ȴ���ַ����
                    if (!addr_ok) begin
                        // ��ַ���ֲ��ɹ���ԭ�صȴ�
                    end else begin
                        // ��ַ���ֳɹ�������req����ת���ַ����
                        req_en <= `False_v;
                        status <= 2'b10;
                    end
                end
                2'b10: begin // �ȴ���������
                    if (!data_ok) begin
                        // �������ֲ��ɹ���ԭ�صȴ�
                    end else begin
                        // �������ֳɹ���������ˮ����ͣ
                        // ת����н׶�
                        status <= 2'b00;
                    end
                end
                default: begin
                    req_en <= `True_v;
                    status <= 2'b00;
                end
            endcase
        end
    end

    // ������ˮ����ͣ�ź�
    always @ (*) begin
        if (rst == `RstEnable) begin
            stallreq <= `False_v;
        end else begin
            case (status)
                2'b00: begin // ���н׶�
                    if (ce && !flush) begin
                        // ���CE���ã�Ҫ���ʣ�����flush�ź�
                        // ������ͣ��ˮ�ߣ�������ȴ���ַ���ֽ׶�
                        stallreq <= `True_v;
                    end else begin
                        // ԭ�صȴ�
                        stallreq <= `False_v;
                    end
                end
                2'b01: begin // �ȴ���ַ����
                    // ��ַ�����ڼ�ʼ�ձ�����ˮ����ͣ
                    stallreq <= `True_v;
                end
                2'b10: begin // �ȴ���������
                    if (!data_ok) begin
                        // �������ֲ��ɹ���ԭ�صȴ�
                        stallreq <= `True_v;
                    end else begin
                        // �������ֳɹ������̳�����ˮ����ͣ
                        // ת����н׶�
                        stallreq <= `False_v;
                    end
                end
                default: begin
                    stallreq <= `False_v;
                end
            endcase
        end
    end

endmodule
