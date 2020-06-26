
//////////////////////////////////////////////////////////////////////////////////
// EX/MEM�Ĵ���
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ex_mem(
    input wire clk,
    input wire rst,

    input wire[5:0] stall,
    
    //����ִ�н׶ε���Ϣ    
    input wire[`RegAddrBus] ex_waddr,
    input wire ex_we,
    input wire[`RegBus] ex_wdata,
    input wire ex_we_hilo, 
    input wire[`RegBus] ex_hi,
    input wire[`RegBus] ex_lo,
    // �ô�
    input wire[`AluOpBus] ex_aluop,
    input wire[`RegBus] ex_mem_addr,
    input wire[`RegBus] ex_reg2,
    // ������״̬��ʹ�õ��ź�
    input wire[`DoubleRegBus] mul_result_i,
    input wire[1:0] cnt_i,
    
    //�͵��ô�׶ε���Ϣ
    output reg[`RegAddrBus] mem_waddr,
    output reg mem_we,
    output reg[`RegBus] mem_wdata,
    output reg mem_we_hilo,
    output reg[`RegBus] mem_hi,
    output reg[`RegBus] mem_lo,
    // �ô�
    output reg[`AluOpBus] mem_aluop,
    output reg[`RegBus] mem_mem_addr,
    output reg[`RegBus] mem_reg2,
    // �ͻ�EX����Ϣ����MADD MSUB��״̬��ʹ��
    output reg[`DoubleRegBus] mul_result_o,
    output reg[1:0] cnt_o
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
            mul_result_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
        end else if (stall[3] == `Stop && stall[4] == `NoStop) begin
            // ����EX��MEM����ͣ���紦��NOP
            mem_waddr <= `NOPRegAddr;
            mem_we <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mem_we_hilo <= `WriteDisable;
            mem_hi <= `ZeroWord;
            mem_lo <= `ZeroWord;  
            mem_aluop <= `ALU_OP_NOP;
            mem_mem_addr <= `ZeroWord;
            mem_reg2 <= `ZeroWord; 
            mul_result_o <= mul_result_i;
            cnt_o <= cnt_i;
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
            mul_result_o <= {`ZeroWord, `ZeroWord};
            cnt_o <= 2'b00;
        end else begin
            mul_result_o <= mul_result_i;
            cnt_o <= cnt_i;
        end
    end

endmodule
