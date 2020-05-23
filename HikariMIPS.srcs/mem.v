
//////////////////////////////////////////////////////////////////////////////////
// 访存阶段
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mem(
    input wire clk,
    input wire rst,
    
    //来自执行阶段的信息    
    input wire[`RegAddrBus] waddr_i,
    input wire we_i,
    input wire[`RegBus] wdata_i,
    input wire we_hilo_i,   
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,
    
    //送到回写阶段的信息
    output reg[`RegAddrBus] waddr_o,
    output reg we_o,
    output reg[`RegBus] wdata_o,
    output reg we_hilo_o,   
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o
    );

    // 由于访存还没有实装，这里只是简单的将信号传递下去
    always @ (*) begin
        if(rst == `RstEnable) begin
            waddr_o <= `NOPRegAddr;
            we_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;   
        end else begin
            waddr_o <= waddr_i;
            we_o <= we_i;
            wdata_o <= wdata_i;
            we_hilo_o <= we_hilo_i; 
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
    
endmodule
