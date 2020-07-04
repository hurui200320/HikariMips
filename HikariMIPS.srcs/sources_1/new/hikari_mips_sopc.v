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
        #200 rst= `RstDisable;
        // #5000 $stop;
    end

    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;

    wire[`RegBus] ram_data_i;
    wire[`RegBus] ram_data_o;
    wire[`RegBus] ram_addr;
    wire ram_ce;
    wire ram_we;
    wire[3:0] ram_sel;

    hikari_mips hiraki0(
    .clk(clk),
    .rst(rst),

    // 指令ROM 类SRAM接口
    .rom_data_i(inst),
    .rom_addr_o(inst_addr),
    .rom_ce_o(rom_ce),

    // 数据RAM 类SRAM接口
    .ram_data_i(ram_data_i),
    .ram_data_o(ram_data_o),
    .ram_addr_o(ram_addr),
    .ram_ce_o(ram_ce),
    .ram_we_o(ram_we),
    .ram_sel_o(ram_sel)
    );

    inst_rom rom(
        .addra(inst_addr),
        .clka(~clk), // 反转时钟：上升沿CPU给地址，下降沿ROM给数据，下一个上升沿CPU取数据
        .douta(inst),
        .ena(rom_ce)
    );
    
    data_ram ram(
        .addra(ram_addr),
        .clka(~clk),
        .dina(ram_data_o),
        .douta(ram_data_i),
        .ena(ram_ce),
        .wea(ram_we ? ram_sel : 4'b0000)
    );

endmodule
