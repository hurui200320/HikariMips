//////////////////////////////////////////////////////////////////////////////////
// PC程序计数器
// 按字节计数
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst, 

    input wire[5:0] stall,

    // 分支跳转信号
    input wire is_branch_i,
    input wire[`RegBus] branch_target_address_i,

    // 异常
    input wire flush,
    input wire[`RegBus] epc,
    output reg[31:0] exceptions_o,

    output reg[`RegBus] pc,
    // 指令存储器使能信号
    output reg ce
    );

    // 先处理复位信号
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
            exceptions_o <= `ZeroWord;
        end else begin
            if (pc[1:0] == 2'b00) begin
                // 地址对齐
                ce <= `ChipEnable;
                exceptions_o[0] <= 1'b0;
            end else begin
                // 地址未对齐
                ce <= `ChipDisable;
                exceptions_o[0] <= 1'b1;
            end
        end
    end
    
    // TODO 取指地址未对齐则产生AdEL异常

    // 两个块并行执行
    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= `ZeroWord;
        end else if (flush) begin
            // 出现异常，使用epc的值
            pc <= epc;
        end else if (stall[0] == `NoStop) begin
            // IF未暂停
            if(is_branch_i) begin
                pc <= branch_target_address_i;
            end else begin
                pc <= pc + 4'h4;
            end
        end else begin
        end
    end
    
endmodule
