
//////////////////////////////////////////////////////////////////////////////////
// EX/MEM寄存器
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ex_mem(
    input wire clk,
    input wire rst,
    
    //来自执行阶段的信息    
    input wire[`RegAddrBus] ex_waddr,
    input wire ex_we,
    input wire[`RegBus] ex_wdata,
    input wire ex_we_hilo, 
    input wire[`RegBus] ex_hi,
    input wire[`RegBus] ex_lo,
    
    //送到访存阶段的信息
    output reg[`RegAddrBus] mem_waddr,
    output reg mem_we,
    output reg[`RegBus] mem_wdata,
    output reg mem_we_hilo,
    output reg[`RegBus] mem_hi,
    output reg[`RegBus] mem_lo
    );

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            mem_waddr <= `NOPRegAddr;
            mem_we <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_we_hilo <= `WriteDisable;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;    
        end else begin
            mem_waddr <= ex_waddr;
            mem_we <= ex_we;
            mem_wdata <= ex_wdata;
            mem_we_hilo <= ex_we_hilo;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo; 
        end
    end

endmodule
