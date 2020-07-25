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
    output reg ce
    );
    
    // 产生访存请求信号ce
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
            exceptions_o <= `ZeroWord;
        end else begin
            if (is_branch_i) begin
                ce <= (branch_target_address_i[1:0] == 2'b00) ? `ChipEnable : `ChipDisable;
                exceptions_o[0] <= (branch_target_address_i[1:0] != 2'b00) ? 1'b1 : 1'b0;
            end else begin
                ce <= (pc[1:0] == 2'b00) ? `ChipEnable : `ChipDisable;
                exceptions_o[0] <= (pc[1:0] != 2'b00) ? 1'b1 : 1'b0;
            end
        end
    end
    
    // 修改PC
    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin
            // pc <= 32'hbfc00000;
            pc <= `ZeroWord;
        end else if (flush) begin
            // 出现异常，使用epc的值
            if (stall[0] == `Stop) begin
                pc <= epc - 4'h4;
            end else begin
                pc <= epc;
            end
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
