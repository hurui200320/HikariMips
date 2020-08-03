`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// HikariMIPS顶层文件
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mycpu_top(
    input wire[5:0] ext_int,   //high active

    input wire aclk,
    input wire aresetn,   //low active

    output wire[3 :0]  arid,
    output wire[31:0]  araddr,
    output wire[7 :0]  arlen,
    output wire[2 :0]  arsize,
    output wire[1 :0]  arburst,
    output wire[1 :0]  arlock,
    output wire[3 :0]  arcache,
    output wire[2 :0]  arprot,
    output wire        arvalid,
    input  wire        arready,
    //r           
    input  wire[3 :0]  rid,
    input  wire[31:0]  rdata,
    input  wire[1 :0]  rresp,
    input  wire        rlast,
    input  wire        rvalid,
    output wire        rready,
    //aw          
    output wire[3 :0]  awid,
    output wire[31:0]  awaddr,
    output wire[7 :0]  awlen,
    output wire[2 :0]  awsize,
    output wire[1 :0]  awburst,
    output wire[1 :0]  awlock,
    output wire[3 :0]  awcache,
    output wire[2 :0]  awprot,
    output wire        awvalid,
    input  wire        awready,
    //w          
    output wire[3 :0]  wid,
    output wire[31:0]  wdata,
    output wire[3 :0]  wstrb,
    output wire        wlast,
    output wire        wvalid,
    input  wire        wready,
    //b           
    input  wire[3 :0]  bid,
    input  wire[1 :0]  bresp,
    input  wire        bvalid,
    output wire        bready,

    //debug interface
    (*mark_debug = "true"*)output wire[31:0] debug_wb_pc,
    (*mark_debug = "true"*)output wire[3:0] debug_wb_rf_wen,
    (*mark_debug = "true"*)output wire[4:0] debug_wb_rf_wnum,
    (*mark_debug = "true"*)output wire[31:0] debug_wb_rf_wdata
    );

    wire[`RegBus] inst_addr;
    wire[511:0] inst_rdata;
    wire[3:0] inst_burst;
    wire inst_req;
    wire inst_addr_ok;
    wire inst_data_ok;

    wire[`RegBus] data_addr;
    wire[511:0] data_wdata;
    wire[511:0] data_rdata;
    wire[63:0] data_strb;
    wire[3:0] data_burst;
    wire data_req;
    wire data_wr;
    wire data_addr_ok;
    wire data_data_ok;

    hikari_mips hiraki0(
    .clk(aclk),
    .rst(~aresetn),

    // TODO

    // 指令ROM类SRAM接口
    .inst_req(inst_req),
    .inst_burst(inst_burst),
    .inst_addr(inst_addr),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),

    // 数据RAM类SRAM接口
    .data_req(data_req),
    .data_burst(data_burst),
    .data_wr(data_wr),
    .data_strb(data_strb),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),
    
    .init_i(ext_int[4:0]),
    .debug_wb_pc(debug_wb_pc),
    .debug_wb_rf_wen(debug_wb_rf_wen),
    .debug_wb_rf_wnum(debug_wb_rf_wnum),
    .debug_wb_rf_wdata(debug_wb_rf_wdata)
    );

    assign arid = 4'b0000;
    assign awid = 4'b0000;
    assign wid = 4'b0000;
    assign awprot = 3'b000;
    assign arprot = 3'b000;
    assign awlock = 2'b00;
    assign arlock = 2'b00;

    cpu_axi_interface cpu_axi_interface0(
    .clk(aclk),
    .resetn(aresetn), 

    .inst_req(inst_req),
    .inst_burst(inst_burst),
    .inst_addr(inst_addr),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),

    .data_req(data_req),
    .data_burst(data_burst),
    .data_wr(data_wr),
    .data_strb(data_strb),
    .data_addr(data_addr),
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),

    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arcache(arcache),
    .arvalid(arvalid),
    .arready(arready),
    
    .rdata(rdata),
    .rresp(rresp),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),
    
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awcache(awcache),
    .awvalid(awvalid),
    .awready(awready),
    
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
    
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready)
    );

endmodule
