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
    output reg[`RegBus] rdata_o
    );

    // CP0内部的寄存器
    `define IndexAddr 8'b00000000
    reg[`RegBus] index;

    `define RandomAddr 8'b00001000
    reg[`RegBus] random;

    `define EntryLo0Addr 8'b00010000
    reg[`RegBus] entryLo0;

    `define EntryLo1Addr 8'b00011000
    reg[`RegBus] entryLo1;

    `define ContextAddr 8'b00100000
    reg[`RegBus] context;

    `define PageMaskAddr 8'b00101000
    reg[`RegBus] pageMask;

    `define WiredAddr 8'b00110000
    reg[`RegBus] wired;

    `define BadVAddrAddr 8'b01000000
    reg[`RegBus] badVAddr;

    `define CountAddr 8'b01001000
    reg[`RegBus] count;

    `define EntryHiAddr 8'b01010000
    reg[`RegBus] entryHi;

    `define CompareAddr 8'b01011000
    reg[`RegBus] compare;

    `define StatusAddr 8'b01100000
    reg[`RegBus] status;

    `define CauseAddr 8'b01101000
    reg[`RegBus] cause;

    `define EPCAddr 8'b01110000
    reg[`RegBus] ePC;

    `define PRIdAddr 8'b01111000
    reg[`RegBus] pRId;

    `define Config0Addr 8'b10000000
    reg[`RegBus] config0;

    `define Config1Addr 8'b10000001
    reg[`RegBus] config1;

    `define TagLo0Addr 8'b11100000
    reg[`RegBus] tagLo0;

    `define DataLo0Addr 8'b11100001
    reg[`RegBus] dataLo0;

    `define TagHi0Addr 8'b11101000
    reg[`RegBus] tagHi0;

    `define DataHi0Addr 8'b11101001
    reg[`RegBus] dataHi0;

    `define TagLo1Addr 8'b11100010
    reg[`RegBus] tagLo1;

    `define DataLo1Addr 8'b11100011
    reg[`RegBus] dataLo1;

    `define TagHi1Addr 8'b11101010
    reg[`RegBus] tagHi1;

    `define DataHi1Addr 8'b11101011
    reg[`RegBus] dataHi1;

    `define TagLo2Addr 8'b11100100
    reg[`RegBus] tagLo2;

    `define DataLo2Addr 8'b11100101
    reg[`RegBus] dataLo2;

    `define TagHi2Addr 8'b11101100
    reg[`RegBus] tagHi2;

    `define DataHi2Addr 8'b11101101
    reg[`RegBus] dataHi2;

    `define TagLo3Addr 8'b11100110
    reg[`RegBus] tagLo3;

    `define DataLo3Addr 8'b11100111
    reg[`RegBus] dataLo3;

    `define TagHi3Addr 8'b11101110
    reg[`RegBus] tagHi3;

    `define DataHi3Addr 8'b11101111
    reg[`RegBus] dataHi3;

    `define ErrorEPCAddr 8'b11110000
    reg[`RegBus] errorEPC;

    // 写数据
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            // 复位，按照指令集赋值
            // TODO 按照指令集赋值
            index <= `ZeroWord;
            random <= `ZeroWord;
            entryLo0 <= `ZeroWord;
            entryLo1 <= `ZeroWord;
            context <= `ZeroWord;
            pageMask <= `ZeroWord;
            wired <= `ZeroWord;
            badVAddr <= `ZeroWord;
            count <= `ZeroWord;
            entryHi <= `ZeroWord;
            compare <= `ZeroWord;
            status <= `ZeroWord;
            cause <= `ZeroWord;
            ePC <= `ZeroWord;
            pRId <= `ZeroWord;
            config0 <= `ZeroWord;
            config1 <= `ZeroWord;
            tagLo0 <= `ZeroWord;
            dataLo0 <= `ZeroWord;
            tagHi0 <= `ZeroWord;
            dataHi0 <= `ZeroWord;
            tagLo1 <= `ZeroWord;
            dataLo1 <= `ZeroWord;
            tagHi1 <= `ZeroWord;
            dataHi1 <= `ZeroWord;
            tagLo2 <= `ZeroWord;
            dataLo2 <= `ZeroWord;
            tagHi2 <= `ZeroWord;
            dataHi2 <= `ZeroWord;
            tagLo3 <= `ZeroWord;
            dataLo3 <= `ZeroWord;
            tagHi3 <= `ZeroWord;
            dataHi3 <= `ZeroWord;
            errorEPC <= `ZeroWord;
        end else if (we_i == `WriteEnable) begin
            // 根据Addr写数据
            // TODO 筛选只读及部分可写
            case (waddr_i)
                `IndexAddr: begin
                    index <= wdata_i;
                end
                `RandomAddr: begin
                    random <= wdata_i;
                end
                `EntryLo0Addr: begin
                    entryLo0 <= wdata_i;
                end
                `EntryLo1Addr: begin
                    entryLo1 <= wdata_i;
                end
                `ContextAddr: begin
                    context <= wdata_i;
                end
                `PageMaskAddr: begin
                    pageMask <= wdata_i;
                end
                `WiredAddr: begin
                    wired <= wdata_i;
                end
                `BadVAddrAddr: begin
                    badVAddr <= wdata_i;
                end
                `CountAddr: begin
                    count <= wdata_i;
                end
                `EntryHiAddr: begin
                    entryHi <= wdata_i;
                end
                `CompareAddr: begin
                    compare <= wdata_i;
                end
                `StatusAddr: begin
                    status <= wdata_i;
                end
                `CauseAddr: begin
                    cause <= wdata_i;
                end
                `EPCAddr: begin
                    ePC <= wdata_i;
                end
                `PRIdAddr: begin
                    pRId <= wdata_i;
                end
                `Config0Addr: begin
                    config0 <= wdata_i;
                end
                `Config1Addr: begin
                    config1 <= wdata_i;
                end
                `TagLo0Addr: begin
                    tagLo0 <= wdata_i;
                end
                `DataLo0Addr: begin
                    dataLo0 <= wdata_i;
                end
                `TagHi0Addr: begin
                    tagHi0 <= wdata_i;
                end
                `DataHi0Addr: begin
                    dataHi0 <= wdata_i;
                end
                `TagLo1Addr: begin
                    tagLo1 <= wdata_i;
                end
                `DataLo1Addr: begin
                    dataLo1 <= wdata_i;
                end
                `TagHi1Addr: begin
                    tagHi1 <= wdata_i;
                end
                `DataHi1Addr: begin
                    dataHi1 <= wdata_i;
                end
                `TagLo2Addr: begin
                    tagLo2 <= wdata_i;
                end
                `DataLo2Addr: begin
                    dataLo2 <= wdata_i;
                end
                `TagHi2Addr: begin
                    tagHi2 <= wdata_i;
                end
                `DataHi2Addr: begin
                    dataHi2 <= wdata_i;
                end
                `TagLo3Addr: begin
                    tagLo3 <= wdata_i;
                end
                `DataLo3Addr: begin
                    dataLo3 <= wdata_i;
                end
                `TagHi3Addr: begin
                    tagHi3 <= wdata_i;
                end
                `DataHi3Addr: begin
                    dataHi3 <= wdata_i;
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
                `IndexAddr: begin
                    rdata_o <= index;
                end
                `RandomAddr: begin
                    rdata_o <= random;
                end
                `EntryLo0Addr: begin
                    rdata_o <= entryLo0;
                end
                `EntryLo1Addr: begin
                    rdata_o <= entryLo1;
                end
                `ContextAddr: begin
                    rdata_o <= context;
                end
                `PageMaskAddr: begin
                    rdata_o <= pageMask;
                end
                `WiredAddr: begin
                    rdata_o <= wired;
                end
                `BadVAddrAddr: begin
                    rdata_o <= badVAddr;
                end
                `CountAddr: begin
                    rdata_o <= count;
                end
                `EntryHiAddr: begin
                    rdata_o <= entryHi;
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
                `PRIdAddr: begin
                    rdata_o <= pRId;
                end
                `Config0Addr: begin
                    rdata_o <= config0;
                end
                `Config1Addr: begin
                    rdata_o <= config1;
                end
                `TagLo0Addr: begin
                    rdata_o <= tagLo0;
                end
                `DataLo0Addr: begin
                    rdata_o <= dataLo0;
                end
                `TagHi0Addr: begin
                    rdata_o <= tagHi0;
                end
                `DataHi0Addr: begin
                    rdata_o <= dataHi0;
                end
                `TagLo1Addr: begin
                    rdata_o <= tagLo1;
                end
                `DataLo1Addr: begin
                    rdata_o <= dataLo1;
                end
                `TagHi1Addr: begin
                    rdata_o <= tagHi1;
                end
                `DataHi1Addr: begin
                    rdata_o <= dataHi1;
                end
                `TagLo2Addr: begin
                    rdata_o <= tagLo2;
                end
                `DataLo2Addr: begin
                    rdata_o <= dataLo2;
                end
                `TagHi2Addr: begin
                    rdata_o <= tagHi2;
                end
                `DataHi2Addr: begin
                    rdata_o <= dataHi2;
                end
                `TagLo3Addr: begin
                    rdata_o <= tagLo3;
                end
                `DataLo3Addr: begin
                    rdata_o <= dataLo3;
                end
                `TagHi3Addr: begin
                    rdata_o <= tagHi3;
                end
                `DataHi3Addr: begin
                    rdata_o <= dataHi3;
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
