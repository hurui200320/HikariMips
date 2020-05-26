
//////////////////////////////////////////////////////////////////////////////////
// EX/MEM寄存器
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ex_mem(
    input wire clk,
    input wire rst,

    input wire[5:0] stall,
    
    //来自执行阶段的信息    
    input wire[`RegAddrBus] ex_waddr,
    input wire ex_we,
    input wire[`RegBus] ex_wdata,
    input wire ex_we_hilo, 
    input wire[`RegBus] ex_hi,
    input wire[`RegBus] ex_lo,
    // 访存
    input wire[`AluOpBus] ex_aluop,
    input wire[`RegBus] ex_mem_addr,
    input wire[`RegBus] ex_reg2,
    
    //送到访存阶段的信息
    output reg[`RegAddrBus] mem_waddr,
    output reg mem_we,
    output reg[`RegBus] mem_wdata,
    output reg mem_we_hilo,
    output reg[`RegBus] mem_hi,
    output reg[`RegBus] mem_lo,
    // 访存
    output reg[`AluOpBus] mem_aluop,
    output reg[`RegBus] mem_mem_addr,
    output reg[`RegBus] mem_reg2
    );

    always @ (posedge clk) begin
        if(rst == `RstEnable) begin
            mem_waddr <= `NOPRegAddr;
            mem_we <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_we_hilo <= `WriteDisable;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;   
            mem_aluop <= `ALU_OP_NOP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord;
        end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            // 处于EX和MEM的暂停交界处，NOP
            mem_waddr <= `NOPRegAddr;
            mem_we <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_we_hilo <= `WriteDisable;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;  
            mem_aluop <= `ALU_OP_NOP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord; 
        end else if (stall[3] == `NoStop) begin
            mem_waddr <= ex_waddr;
            mem_we <= ex_we;
            mem_wdata <= ex_wdata;
            mem_we_hilo <= ex_we_hilo;
            mem_hi <= ex_hi;
            mem_lo <= ex_lo; 
            mem_aluop <= ex_aluop;
            mem_mem_addr <= ex_mem_addr;
            mem_reg2 <= ex_reg2;
        end else begin
        end
    end

endmodule
