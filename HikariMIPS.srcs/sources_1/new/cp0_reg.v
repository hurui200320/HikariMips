//////////////////////////////////////////////////////////////////////////////////
// CP0�Ĵ���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module cp0_reg(
    input wire clk,
    input wire rst,

    input wire we_i,
    input wire[7:0] waddr_i, // [7:3] number, [2:0] sel
    input wire[`RegBus] wdata_i,

    input wire[7:0] raddr_i,
    output reg[`RegBus] rdata_o,
    input wire[4:0] init_i // Ӳ���ж�����
    );

    // CP0�ڲ��ļĴ���
    `define BadVAddrAddr 8'b01000000
    reg[`RegBus] badVAddr;

    `define CountAddr 8'b01001000
    reg[`RegBus] count;

    `define CompareAddr 8'b01011000
    reg[`RegBus] compare;

    `define StatusAddr 8'b01100000
    reg[`RegBus] status;

    `define CauseAddr 8'b01101000
    reg[`RegBus] cause;

    `define EPCAddr 8'b01110000
    reg[`RegBus] ePC;

    `define Config0Addr 8'b10000000
    reg[`RegBus] config0;

    `define Config1Addr 8'b10000001
    reg[`RegBus] config1;

    `define ErrorEPCAddr 8'b11110000
    reg[`RegBus] errorEPC;

    // д����
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            // ��λ������ָ���ֵ
            // ֻ����Ҫ����Ĳ��У����reset��Ϊundefined����Ҫ����
            status <= 32'b0001_0000_0100_0000_0000_0000_0000_0100;
            cause <= `ZeroWord;
            // TODO TLB chache things...
            config0 <= 32'b1000_0000_0000_0000_0000_0000_0000_0000;
            config1 <= `ZeroWord;
        end else if (we_i == `WriteEnable) begin
            // count����
            count <= count + 1;
            // д�ⲿӲ���ж���casue
            cause[14:10] = init_i;
            if (count == compare) begin
                // ������ʱ���ж�
                cause[15] = 1'b1;
                // MIPS32R1�н���ʱ�������ܼ������ж���IP7�ϲ�
                // �ϲ���ʽȡ���ھ���ʵ�֣�HikariMIPSֱ��ʹ��ʱ���ж϶�ռIP7
            end

            // ����Addrд����
            case (waddr_i)
                `CountAddr: begin
                    count <= wdata_i;
                end
                `CompareAddr: begin
                    compare <= wdata_i;
                    cause[15] = 1'b0;
                end
                `StatusAddr: begin
                    status[31:29] <= wdata_i[31:29]; // CP0ʼ�տ��ã�������д��
                    status[22] <= wdata_i[22];
                    status[15:8] <= wdata_i[15:8];
                    status[4] <= wdata_i[4];
                    status[2:0] <= wdata_i[2:0];
                end
                `CauseAddr: begin
                    cause[23] <= wdata_i[23];
                    cause[9:8] <= wdata_i[9:8];
                end
                `EPCAddr: begin
                    ePC <= wdata_i;
                end
                `Config0Addr: begin
                    config0[30:25] <= wdata_i[30:25];
                    config0[24:16] <= wdata_i[24:16]; // ����ʵ��ʹ��
                    config0[2:0] <= wdata_i[2:0];
                end
                `ErrorEPCAddr: begin
                    errorEPC <= wdata_i;
                end
                default: begin
                    // unknown register
                end
            endcase 
        end else begin
            // do nothing
        end
    end

    // ������
    always @ (*) begin
        if (rst == `RstEnable) begin
            // ��λ���0
            rdata_o <= `ZeroWord;
        end else if (we_i == `WriteEnable && raddr_i == waddr_i) begin
            // д����
            rdata_o <= wdata_i;
        end else begin
            // ������
            case (raddr_i)
                `BadVAddrAddr: begin
                    rdata_o <= badVAddr;
                end
                `CountAddr: begin
                    rdata_o <= count;
                end
                `CompareAddr: begin
                    rdata_o <= compare;
                end
                `StatusAddr: begin
                    rdata_o <= status;
                end
                `CauseAddr: begin
                    rdata_o <= cause;
                end
                `EPCAddr: begin
                    rdata_o <= ePC;
                end
                `Config0Addr: begin
                    rdata_o <= config0;
                end
                `Config1Addr: begin
                    rdata_o <= config1;
                end
                `ErrorEPCAddr: begin
                    rdata_o <= errorEPC;
                end
                default: begin
                    // unknown register
                    rdata_o <= `ZeroWord;
                end
            endcase 
        end
    end

endmodule
