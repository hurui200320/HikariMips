//////////////////////////////////////////////////////////////////////////////////
// MEM/WB�Ĵ���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mem_wb(
    input wire clk,
    input wire rst,
    input wire flush,

    input wire[5:0] stall,

    //���Էô�׶ε���Ϣ    
    input wire[`RegAddrBus] mem_waddr,
    input wire mem_we,
    input wire[`RegBus] mem_wdata,
    input wire mem_we_hilo, 
    input wire[`RegBus] mem_hi,
    input wire[`RegBus] mem_lo,
    input wire mem_cp0_we,
    input wire[7:0] mem_cp0_waddr,
    input wire[`RegBus] mem_cp0_wdata,

    //�͵���д�׶ε���Ϣ
    output reg[`RegAddrBus] wb_waddr,
    output reg wb_we,
    output reg[`RegBus] wb_wdata,
    output reg wb_we_hilo,  
    output reg[`RegBus] wb_hi,
    output reg[`RegBus] wb_lo,
    output reg wb_cp0_we,
    output reg[7:0] wb_cp0_waddr,
    output reg[`RegBus] wb_cp0_wdata   
    );

    always @ (posedge clk) begin
        if(rst == `RstEnable || flush) begin
            wb_waddr <= `NOPRegAddr;
            wb_we <= `WriteDisable;
            wb_wdata <= `ZeroWord;  
            wb_we_hilo <= `WriteDisable;  
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_cp0_we <= `WriteDisable;
            wb_cp0_waddr <= 8'b00000000;
            wb_cp0_wdata <= `ZeroWord;
        end else if (stall[4] == `Stop && stall[5] == `NoStop) begin
            wb_waddr <= `NOPRegAddr;
            wb_we <= `WriteDisable;
            wb_wdata <= `ZeroWord;  
            wb_we_hilo <= `WriteDisable;  
            wb_hi <= `ZeroWord;
            wb_lo <= `ZeroWord;
            wb_cp0_we <= `WriteDisable;
            wb_cp0_waddr <= 8'b00000000;
            wb_cp0_wdata <= `ZeroWord;
        end else if (stall[4] == `NoStop) begin
            wb_waddr <= mem_waddr;
            wb_we <= mem_we;
            wb_wdata <= mem_wdata;
            wb_we_hilo <= mem_we_hilo;  
            wb_hi <= mem_hi;
            wb_lo <= mem_lo;
            wb_cp0_we <= mem_cp0_we;
            wb_cp0_waddr <= mem_cp0_waddr;
            wb_cp0_wdata <= mem_cp0_wdata;
        end else begin
        end
    end 

endmodule
