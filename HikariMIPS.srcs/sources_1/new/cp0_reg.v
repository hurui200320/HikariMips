//////////////////////////////////////////////////////////////////////////////////
// CP0寄存器
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
    input wire[4:0] init_i // 硬件中断输入
    );

    // CP0内部的寄存器
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

    // 写数据
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            // 复位，按照指令集赋值
            // 只有需要清零的才有，如果reset后为undefined则不需要清零
            status <= 32'b0001_0000_0100_0000_0000_0000_0000_0100;
            cause <= `ZeroWord;
            // TODO TLB chache things...
            config0 <= 32'b1000_0000_0000_0000_0000_0000_0000_0000;
            config1 <= `ZeroWord;
        end else if (we_i == `WriteEnable) begin
            // count自增
            count <= count + 1;
            // 写外部硬件中断至casue
            cause[14:10] = init_i;
            if (count == compare) begin
                // 引发定时器中断
                cause[15] = 1'b1;
                // MIPS32R1中将定时器和性能计数器中断与IP7合并
                // 合并方式取决于具体实现，HikariMIPS直接使定时器中断独占IP7
            end

            // 根据Addr写数据
            case (waddr_i)
                `CountAddr: begin
                    count <= wdata_i;
                end
                `CompareAddr: begin
                    compare <= wdata_i;
                    cause[15] = 1'b0;
                end
                `StatusAddr: begin
                    status[31:29] <= wdata_i[31:29]; // CP0始终可用，不允许写入
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
                    config0[24:16] <= wdata_i[24:16]; // 具体实现使用
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

    // 读数据
    always @ (*) begin
        if (rst == `RstEnable) begin
            // 复位输出0
            rdata_o <= `ZeroWord;
        end else if (we_i == `WriteEnable && raddr_i == waddr_i) begin
            // 写优先
            rdata_o <= wdata_i;
        end else begin
            // 正常读
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
