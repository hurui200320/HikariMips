//////////////////////////////////////////////////////////////////////////////////
// PC程序计数器
// 按字节计数
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst, 

    output reg[`InstAddrBus] pc,
    // 指令存储器使能信号
    output reg ce
    );

    // 先处理复位信号
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end

    // 两个块并行执行
    always @ (posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= `ZeroWord;
        end else begin
            pc <= pc + 4'h4;
        end
    end
    
endmodule
