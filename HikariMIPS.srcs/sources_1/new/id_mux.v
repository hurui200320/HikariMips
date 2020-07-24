`include "defines.v"
module id_mux(
    input wire clk,
    input wire rst,
    input wire flush,

    input wire[6:0] stall,

    input wire[`RegBus] id_pc,
    input wire[`RegBus] id_inst,
    input wire[`AluOpBus] id_aluop,
    input wire[`AluSelBus] id_alusel,
    input wire[`RegAddrBus] id_waddr,
    input wire id_we,
    input wire[`RegBus] id_imm,
    input wire[`RegBus] id_link_addr,
    input wire[`RegBus] id_exceptions,
    input wire id_taken,
    input wire[`RegBus] id_branch_target_address,//间接跳转时用于地址比较

    //regfile得到的数据和相关信号
    input wire id_re1,
    input wire[`RegAddrBus] id_raddr1,
    input wire[`RegBus] rdata1_i,
    input wire id_re2,
    input wire[`RegAddrBus] id_raddr2,
    input wire[`RegBus] rdata2_i,

    //cp0寄存器访问
    input wire[7:0] id_cp0_raddr,
    input wire[`RegBus] id_cp0_rdata,

    //输出信号
    output reg[`RegBus] mux_pc,
    output reg[`RegBus] mux_inst,
    output reg[`AluOpBus] mux_aluop,
    output reg[`AluSelBus] mux_alusel,
    output reg[`RegAddrBus] mux_waddr,
    output reg mux_we,
    output reg[`RegBus] mux_imm,
    output reg[`RegBus] mux_link_addr,
    output reg[`RegBus] mux_exceptions,
    output reg mux_taken,
    output reg[`RegBus] mux_branch_target_address,

    output reg mux_re1,
    output reg[`RegAddrBus] mux_raddr1,
    output reg[`RegBus] mux_rdata1,
    output reg mux_re2,
    output reg[`RegAddrBus] mux_raddr2,
    output reg[`RegBus] mux_rdata2,
    //cp0寄存器输出
    output reg[7:0] mux_cp0_raddr,
    output reg[`RegBus] mux_cp0_rdata
    
);

    always @ (posedge clk) begin
        if (rst == `RstEnable || flush) begin
            mux_pc <= `ZeroWord;
            mux_inst <= `ZeroWord;
            mux_aluop <= `ALU_OP_NOP;
            mux_alusel <= `ALU_SEL_NOP;
            mux_waddr <= `NOPRegAddr;
            mux_we <= `WriteDisable;
            mux_imm <= `ZeroWord;
            mux_link_addr <= `ZeroWord;
            mux_exceptions <= `ZeroWord;
            mux_taken <= 1'b0;
            mux_re1 <= `WriteDisable;
            mux_raddr1 <= `NOPRegAddr;
            mux_rdata1 <= `ZeroWord;
            mux_re2 <= `WriteDisable;
            mux_raddr2 <= `NOPRegAddr;
            mux_rdata2 <= `ZeroWord;
            mux_cp0_raddr <= 8'h00;
            mux_cp0_rdata <= `ZeroWord;
            mux_branch_target_address <= `ZeroWord;
        end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
            mux_pc <= `ZeroWord;
            mux_inst <= `ZeroWord;
            mux_aluop <= `ALU_OP_NOP;
            mux_alusel <= `ALU_SEL_NOP;
            mux_waddr <= `NOPRegAddr;
            mux_we <= `WriteDisable;
            mux_imm <= `ZeroWord;
            mux_link_addr <= `ZeroWord;
            mux_exceptions <= `ZeroWord;
            mux_taken <= 1'b0;
            mux_branch_target_address <= `ZeroWord;
            mux_re1 <= `WriteDisable;
            mux_raddr1 <= `NOPRegAddr;
            mux_rdata1 <= `ZeroWord;
            mux_re2 <= `WriteDisable;
            mux_raddr2 <= `NOPRegAddr;
            mux_rdata2 <= `ZeroWord;
            mux_cp0_raddr <= 8'h00;
            mux_cp0_rdata <= `ZeroWord;
        end else if (stall[2] == `NoStop) begin
            mux_pc <= id_pc;
            mux_inst <= id_inst;
            mux_aluop <= id_aluop;
            mux_alusel <= id_alusel;
            mux_waddr <= id_waddr;
            mux_we <= id_we;
            mux_imm <= id_imm;
            mux_link_addr <= id_link_addr;
            mux_exceptions <= id_exceptions;
            mux_taken <= id_taken;
            mux_branch_target_address <= id_branch_target_address;
            mux_re1 <= id_re1;
            mux_raddr1 <= id_raddr1;
            mux_rdata1 <= rdata1_i;
            mux_re2 <= id_re2;
            mux_raddr2 <= id_raddr2;
            mux_rdata2 <= rdata2_i;
            mux_cp0_raddr <= id_cp0_raddr;
            mux_cp0_rdata <= id_cp0_rdata;
        end
    end

    
endmodule