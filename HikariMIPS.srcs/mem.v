
//////////////////////////////////////////////////////////////////////////////////
// �ô�׶�
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mem(
    input wire clk,
    input wire rst,
    
    //����ִ�н׶ε���Ϣ    
    input wire[`RegAddrBus] waddr_i,
    input wire we_i,
    input wire[`RegBus] wdata_i,
    input wire we_hilo_i,   
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,
    
    //�͵���д�׶ε���Ϣ
    output reg[`RegAddrBus] waddr_o,
    output reg we_o,
    output reg[`RegBus] wdata_o,
    output reg we_hilo_o,   
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o
    );

    // ���ڷô滹û��ʵװ������ֻ�Ǽ򵥵Ľ��źŴ�����ȥ
    always @ (*) begin
        if(rst == `RstEnable) begin
            waddr_o <= `NOPRegAddr;
            we_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;   
        end else begin
            waddr_o <= waddr_i;
            we_o <= we_i;
            wdata_o <= wdata_i;
            we_hilo_o <= we_hilo_i; 
            hi_o <= hi_i;
            lo_o <= lo_i;
        end
    end
    
endmodule
