//////////////////////////////////////////////////////////////////////////////////
// CTRL流水线控制
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"
////////////////////////////////
// 0 |    1    |    2    |    3    |    4    |    5    |    6    |
//pc |  if_id  | id_mux  | mux_ex  |  ex_mem |  mem_wb |   wb    |
module ctrl(
    input wire clk,
    input wire rst,

    input wire stallreq_from_mux,
    input wire stallreq_from_ex,
    //分支预测错误时对pc进行清零
    input wire flush_pc_i,
    // stall <= {WB, MEM, EX, MUX, ID, IF, PC}
    output reg[6:0] stall,
    output reg flush_pc_o,//清空流水线pc信号

    // 异常
    input wire[`RegBus] cp0_epc_i,
    input wire exception_occured_i,
    input wire[4:0] exc_code_i,
    output reg[`RegBus] epc_o,
    output reg flush
);
    always @ (*) begin
        stall <= 7'b0000000;
        flush <= 1'b0;
        if(rst == `RstEnable) begin
            epc_o <= `ZeroWord;
        end else if(exception_occured_i) begin
            // 有异常
            flush <= 1'b1;
            case (exc_code_i)
                // 根据异常类型判断pc要写入的值
                5'h10: begin
                    // ERET调用
                    epc_o <= cp0_epc_i;
                end 
                default: begin
                    // 其他异常统一入口
                    epc_o <= 32'h00000040; // TODO
                end
            endcase
        end else if(stallreq_from_ex == `Stop) begin
            stall <= 7'b0011111;
        end else if(stallreq_from_mux == `Stop) begin
            stall <= 7'b0001111;            
        end else begin
            stall <= 7'b0000000;
        end
    end

endmodule