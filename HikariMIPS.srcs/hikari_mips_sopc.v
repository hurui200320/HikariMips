`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// SOPC测试模块
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module hikari_mips_sopc();
    reg rst;
    reg clk;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end
        
    initial begin
        rst = `RstEnable;
        #50 rst= `RstDisable;
        #5000 $stop;
    end

    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;

    hikari_mips hiraki0(
    .clk(clk),
    .rst(rst),

    // 指令寄存器类SRAM接口
    .rom_data_i(inst),
    .rom_addr_o(inst_addr),
    .rom_ce_o(rom_ce)
    );

    inst_rom rom(
        .addra(inst_addr[19:2]),
        .clka(clk),
        .douta(inst),
        .ena(rom_ce)
    );
endmodule
