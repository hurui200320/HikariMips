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
    output reg req,
    input wire addr_ok,
    input wire data_ok,
    output wire[3:0] burst,
    output wire[`RegBus] addr,
    input wire[511:0] inst_rdata_i,
    output wire[`RegBus] inst_rdata_o,

    output wire stallreq
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

    //--------------- icache部分 ---------------
    // icache代替原来的if握手
    assign addr = {pc[31:6],6'b000000};
    assign burst = 4'b1111;

    reg[2:0] state;
    wire[17:0] tag = pc[31:14];
    wire[9:0] index = pc[13:6];
    wire[3:0] offset = pc[5:2];

    wire[31:0] block[0:15];//临时存储取到的块
    wire[17:0] tag_out;
    wire valid_out;
    wire hit = valid_out & (tag_out == tag);//判断是否hit

    assign inst_rdata_o = (hit == 1'b1) ? block[offset] : 32'h00000000;
    assign stallreq = ce && (~hit || state == 2'b01 || state == 2'b10);

    reg flush_wait;

    wire cache_we = flush_wait ? 1'b0 : data_ok;
    `define IDLE 3'b000
    `define WAITADDROK 3'b001
    `define ADDROK 3'b010
    `define DATAOK 3'b011
    `define FLUSHWAIT 3'b100

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            state <= `IDLE;
            req <= 1'b0;
            flush_wait <= 1'b0;
        end else if (flush) begin
            if(state != `IDLE && state != `DATAOK) begin
                state <= `FLUSHWAIT;
                flush_wait <= 1'b1;
            end 
        end else if (ce == 1'b1) begin
            case (state)
                `IDLE: begin
                    if(pc[1:0] != 2'b00) begin
                        req <= 1'b0;
                    end else if(!hit) begin//cache读缺失
                        state <= `WAITADDROK;//进入等待地址确认状态
                        req <= 1'b1;
                    end else begin
                        req <= 1'b0;
                    end
                end
                `WAITADDROK: begin
                    if(addr_ok == 1'b1) begin
                        req <= 1'b0;
                        state <= `ADDROK;
                    end
                end
                `ADDROK: begin
                    if(data_ok == 1'b1) begin
                        state <= `DATAOK;
                    end 
                end
                `DATAOK: begin
                    state <= `IDLE;
                end
                `FLUSHWAIT: begin
                    if(data_ok) begin
                        state <= `IDLE;
                        flush_wait <= 1'b0;
                    end
                end
            endcase
        end
    end

    valid_ram valid(//给index获得vaild
        .a(index),
        .d(1'b1),
        .clk(clk),
        .we(cache_we),
        .spo(valid_out)
    );

    tag_ram tag0(
        .a(index),
        .d(tag),
        .clk(clk),
        .we(cache_we),
        .spo(tag_out)
    );
    //数据寄存器
    block_ram data0(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[511:480]),
        .douta(block[0]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data1(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[479:448]),
        .douta(block[1]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data2(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[447:416]),
        .douta(block[2]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data3(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[415:384]),
        .douta(block[3]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data4(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[383:352]),
        .douta(block[4]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data5(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[351:320]),
        .douta(block[5]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data6(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[319:288]),
        .douta(block[6]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data7(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[287:256]),
        .douta(block[7]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data8(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[255:224]),
        .douta(block[8]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data9(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[223:192]),
        .douta(block[9]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data10(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[191:160]),
        .douta(block[10]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data11(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[159:128]),
        .douta(block[11]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data12(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[127:96]),
        .douta(block[12]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data13(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[95:64]),
        .douta(block[13]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data14(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[63:32]),
        .douta(block[14]),
        .ena(ce),
        .wea(cache_we)
    );
    block_ram data15(
        .addra(index),
        .clka(~clk),
        .dina(inst_rdata_i[31:0]),
        .douta(block[15]),
        .ena(ce),
        .wea(cache_we)
    );

endmodule
