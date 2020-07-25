`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// HikariMIPS顶层文件
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module my_cpu(
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
    output wire[31:0] debug_wb_pc,
    output wire[3:0] debug_wb_rf_wen,
    output wire[4:0] debug_wb_rf_wnum,
    output wire[31:0] debug_wb_rf_wdata
    );

    wire[`RegBus] inst_addr;
    wire[`RegBus] inst_wdata;
    wire[`RegBus] inst_rdata;
    wire inst_req;
    wire inst_wr;
    wire inst_addr_ok;
    wire inst_data_ok;
    wire[3:0] inst_strb;

    wire[`RegBus] data_addr;
    wire[`RegBus] data_wdata;
    wire[`RegBus] data_rdata;
    wire data_req;
    wire data_wr;
    wire data_addr_ok;
    wire data_data_ok;
    wire[3:0] data_strb;

    hikari_mips hiraki0(
    .clk(aclk),
    .rst(~aresetn),

    // 指令ROM类SRAM接口
    .inst_req(inst_req),
    .inst_wr(inst_wr),
    .inst_strb(inst_strb),
    .inst_addr(inst_addr),
    .inst_wdata(inst_wdata),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),

    // 数据RAM类SRAM接口
    .data_req(data_req),
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

    cpu_axi_interface cpu_axi_interface0(
    .clk(aclk),
    .resetn(aresetn), 

    .inst_req(inst_req),
    .inst_wr(inst_wr),
    .inst_strb(inst_strb),
    .inst_addr(inst_addr),
    .inst_wdata(inst_wdata),
    .inst_rdata(inst_rdata),
    .inst_addr_ok(inst_addr_ok),
    .inst_data_ok(inst_data_ok),

    .data_req(data_req),
    .data_wr(data_wr),
    .data_strb(data_strb),
    .data_addr({3'b000, data_addr[28:0]}), // 学去年，数据直接高三位抹0
    .data_wdata(data_wdata),
    .data_rdata(data_rdata),
    .data_addr_ok(data_addr_ok),
    .data_data_ok(data_data_ok),

    .arid(arid),
    .araddr(araddr),
    .arlen(arlen),
    .arsize(arsize),
    .arburst(arburst),
    .arlock(arlock),
    .arcache(arcache),
    .arprot(arprot),
    .arvalid(arvalid),
    .arready(arready),
    
    .rid(rid),
    .rdata(rdata),
    .rresp(rresp),
    .rlast(rlast),
    .rvalid(rvalid),
    .rready(rready),
    
    .awid(awid),
    .awaddr(awaddr),
    .awlen(awlen),
    .awsize(awsize),
    .awburst(awburst),
    .awlock(awlock),
    .awcache(awcache),
    .awprot(awprot),
    .awvalid(awvalid),
    .awready(awready),
    
    .wid(wid),
    .wdata(wdata),
    .wstrb(wstrb),
    .wlast(wlast),
    .wvalid(wvalid),
    .wready(wready),
    
    .bid(bid),
    .bresp(bresp),
    .bvalid(bvalid),
    .bready(bready)
    );

endmodule
