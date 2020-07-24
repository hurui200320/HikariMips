
//////////////////////////////////////////////////////////////////////////////////
// IF/ID寄存器
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module if_id(
    input wire clk,
    input wire rst,

    input wire flush,
    input wire flush_pc,

    input wire[6:0] stall,
    
    input wire[`RegBus] if_pc,
    input wire[`RegBus] if_inst,
    input wire[`RegBus] if_exceptions,
    output reg[`RegBus] id_pc,
    output reg[`RegBus] id_inst,  
    output reg[`RegBus] id_exceptions
    );

    always @ (posedge clk) begin
        if (rst == `RstEnable || flush) begin
            // 复位或异常时往下传0和NOP
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            id_exceptions <= `ZeroWord;
        end else if (flush_pc) begin//分支预测失败插入nop
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            id_exceptions <= `ZeroWord;
        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin
            // IF暂停了而ID没暂停，插入NOP
            id_pc <= `ZeroWord;
            id_inst <= `ZeroWord;
            id_exceptions <= `ZeroWord;
        end else if (stall[1] == `NoStop) begin
            // 正常时传出IF的数据
            id_pc <= if_pc;
            id_inst <= if_inst;
            id_exceptions <= if_exceptions;
        end else begin
            // 其余情况（不在被暂停的交界处）则原封不动，其他交界寄存器类似
        end
    end

endmodule
