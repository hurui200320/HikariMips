//////////////////////////////////////////////////////////////////////////////////
// ID/EX寄存器
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mux_ex(
    input wire clk,
    input wire rst,
    input wire flush,

    input wire[6:0] stall,
    
    //从译码阶段传递的信息
    input wire[`AluOpBus] mux_aluop,
    input wire[`AluSelBus] mux_alusel,
    input wire[`RegBus] mux_reg1,
    input wire[`RegBus] mux_reg2,
    input wire[`RegAddrBus] mux_waddr,
    input wire mux_we,
    input wire mux_is_in_delayslot,
    input wire[`RegBus] mux_link_address,
    input wire next_inst_in_delayslot_i,
    input wire next_inst_is_nullified_i,
    input wire[`RegBus] mux_inst,
    input wire[`RegBus] mux_pc,
    input wire[31:0] mux_exceptions,
    //hilo
    input wire[`RegBus] mux_hi,
    input wire[`RegBus] mux_lo,
    //cp0
    input wire[`RegBus] mux_cp0_rdata,
    
    //传递到执行阶段的信息
    output reg[`AluOpBus] ex_aluop,
    output reg[`AluSelBus] ex_alusel,
    output reg[`RegBus] ex_reg1,
    output reg[`RegBus] ex_reg2,
    output reg[`RegAddrBus] ex_waddr,
    output reg ex_we,
    output reg ex_is_in_delayslot,
    output reg[`RegBus] ex_link_address,
    output reg is_in_delayslot_o,
    output reg is_nullified_o,
    output reg[`RegBus] ex_inst,
    output reg[`RegBus] ex_pc,
    output reg[31:0] ex_exceptions,
    //hilo和cp0
    output reg[`RegBus] ex_hi,
    output reg[`RegBus] ex_lo,
    //cp0
    output reg[`RegBus] ex_cp0_rdata
    );

    always @ (posedge clk) begin
        if (rst == `RstEnable || flush) begin
            ex_aluop <= `ALU_OP_NOP;
            ex_alusel <= `ALU_SEL_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_waddr <= `NOPRegAddr;
            ex_we <= `WriteDisable;
            ex_is_in_delayslot <= `False_v;
            ex_link_address <= `ZeroWord;
            is_in_delayslot_o <= `False_v;
            is_nullified_o <= `False_v;
            ex_inst <= `ZeroWord;
            ex_pc <= `ZeroWord;
            ex_exceptions <= `ZeroWord;
            ex_hi <= `ZeroWord;
            ex_lo <= `ZeroWord;
            ex_cp0_rdata <= `ZeroWord;
        end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            // ID暂停而EX没有暂停，输出NOP状态
            ex_aluop <= `ALU_OP_NOP;
            ex_alusel <= `ALU_SEL_NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            ex_waddr <= `NOPRegAddr;
            ex_we <= `WriteDisable;
            ex_is_in_delayslot <= `False_v;
            ex_link_address <= `ZeroWord;
            ex_inst <= `ZeroWord;
            ex_pc <= `ZeroWord;
            ex_exceptions <= `ZeroWord;
            ex_hi <= `ZeroWord;
            ex_lo <= `ZeroWord;
            ex_cp0_rdata <= `ZeroWord;
            // ID当前指令是否在延迟槽中状态不变
        end else if (stall[3] == `NoStop) begin        
            ex_aluop <= mux_aluop;
            ex_alusel <= mux_alusel;
            ex_reg1 <= mux_reg1;
            ex_reg2 <= mux_reg2;
            ex_waddr <= mux_waddr;
            ex_we <= mux_we;
            ex_is_in_delayslot <= mux_is_in_delayslot;
            ex_link_address <= mux_link_address;
            is_in_delayslot_o <= next_inst_in_delayslot_i;
            is_nullified_o <= next_inst_is_nullified_i;
            ex_inst <= mux_inst;
            ex_pc <= mux_pc;
            ex_exceptions <= mux_exceptions;
            ex_hi <= mux_hi;
            ex_lo <= mux_lo;
            ex_cp0_rdata <= mux_cp0_rdata;
        end else begin
        end
    end
endmodule
