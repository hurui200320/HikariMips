//////////////////////////////////////////////////////////////////////////////////
// MEM/WB寄存器
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mem_wb(
    input wire clk,
    input wire rst,

    input wire[5:0] stall,

    //来自访存阶段的信息    
    input wire[`RegAddrBus] mem_waddr,
    input wire mem_we,
    input wire[`RegBus] mem_wdata,
    input wire mem_we_hilo, 
    input wire[`RegBus] mem_hi,
    input wire[`RegBus] mem_lo,

    //送到回写阶段的信息
    output reg[`RegAddrBus] wb_waddr,
    output reg wb_we,
    output reg[`RegBus] wb_wdata,
    output reg wb_we_hilo,  
    output reg[`RegBus] wb_hi,
    output reg[`RegBus] wb_lo   
    );

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            wb_waddr <= `NOPRegAddr;
            wb_we <= `WriteDisable;
            wb_wdata <= `ZeroWord;  
            wb_we_hilo <= `WriteDisable;  
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;    
        end else if (stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_waddr <= `NOPRegAddr;
            wb_we <= `WriteDisable;
            wb_wdata <= `ZeroWord;  
            wb_we_hilo <= `WriteDisable;  
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
        end else if (stall[4] == `NoStop) begin
            wb_waddr <= mem_waddr;
            wb_we <= mem_we;
            wb_wdata <= mem_wdata;
            wb_we_hilo <= mem_we_hilo;  
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
        end else begin
        end
    end 

endmodule
