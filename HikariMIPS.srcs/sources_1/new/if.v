`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// IF
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module sram_if(
    input wire clk,
    input wire rst, 

    input wire[5:0] stall,

    // 分支跳转信号
    input wire is_branch_i,
    input wire[`RegBus] branch_target_address_i,

    // 异常
    input wire flush,
    input wire[`RegBus] epc,
    output wire[31:0] exceptions_o,

    output wire[`RegBus] pc,
    
    // 指令存储器使能信号
    output wire req,
    input wire addr_ok,
    input wire data_ok,

    output reg stallreq
    );
    wire ce;

    pc_reg pc_reg0(
        .clk(clk),
        .rst(rst), 
        .stall(stall),
        .is_branch_i(is_branch_i),
        .branch_target_address_i(branch_target_address_i),

        .flush(flush),
        .epc(epc),
        .exceptions_o(exceptions_o),

        .pc(pc),
        .ce(ce)
    );
    
    reg req_en;
    assign req = ce & req_en;

    reg[1:0] status;

    // 握手状态机
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            req_en <= `False_v;
            status <= 2'b00;
        end else begin
            case (status)
                2'b00: begin // 空闲阶段
                    if (ce && !flush) begin
                        // 如果CE启用（要访问）且无flush信号
                        // 进入等待地址握手阶段
                        req_en <= `True_v;
                        status <= 2'b01;
                    end else begin
                        // 原地等待
                        req_en <= `False_v;
                    end
                end
                2'b01: begin // 等待地址握手
                    if (!addr_ok) begin
                        // 地址握手不成功，原地等待
                    end else begin
                        // 地址握手成功，撤销req请求并转入地址握手
                        req_en <= `False_v;
                        status <= 2'b10;
                    end
                end
                2'b10: begin // 等待数据握手
                    if (!data_ok) begin
                        // 数据握手不成功，原地等待
                    end else begin
                        // 数据握手成功，撤销流水线暂停
                        // 转入空闲阶段
                        status <= 2'b00;
                    end
                end
                default: begin
                    req_en <= `True_v;
                    status <= 2'b00;
                end
            endcase
        end
    end

    // 产生流水线暂停信号
    always @ (*) begin
        if (rst == `RstEnable) begin
            stallreq <= `False_v;
        end else begin
            case (status)
                2'b00: begin // 空闲阶段
                    if (ce && !flush) begin
                        // 如果CE启用（要访问）且无flush信号
                        // 立刻暂停流水线，随后进入等待地址握手阶段
                        stallreq <= `True_v;
                    end else begin
                        // 原地等待
                        stallreq <= `False_v;
                    end
                end
                2'b01: begin // 等待地址握手
                    // 地址握手期间始终保持流水线暂停
                    stallreq <= `True_v;
                end
                2'b10: begin // 等待数据握手
                    if (!data_ok) begin
                        // 数据握手不成功，原地等待
                        stallreq <= `True_v;
                    end else begin
                        // 数据握手成功，立刻撤销流水线暂停
                        // 转入空闲阶段
                        stallreq <= `False_v;
                    end
                end
                default: begin
                    stallreq <= `False_v;
                end
            endcase
        end
    end

endmodule
