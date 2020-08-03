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
    output wire[3:0] burst,
    output wire[`RegBus] addr,
    input wire[511:0] inst_rdata_i,
    output wire[`RegBus] inst_rdata_o,

    output reg stallreq
    );
    wire ce;

    // TODO
    assign addr = pc;
    assign burst = 4'b0000;
    assign inst_rdata_o = inst_rdata_i[31:0];

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

    reg cancled;

    reg[1:0] status;

    // 处理flush信号导致的返回数据无效
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            cancled <= 1'b0;
        end else begin
            if (status != 2'b00 && flush) begin
                // 已经开始握手且此时有flush信号
                cancled <= 1'b1;
            end else if (status == 2'b00) begin
                // 等待握手阶段清零
                cancled <= 1'b0;
            end
        end
    end

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
                        // 数据握手成功
                        // 无Cancle则立刻撤销流水线暂停
                        // 转入空闲阶段
                        stallreq <= cancled ? `True_v : `False_v;
                    end
                end
                default: begin
                    stallreq <= `False_v;
                end
            endcase
        end
    end

endmodule
