`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// SOPC测试模块
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module hikari_mips_sopc();
    reg rst;
    reg clk;

    initial begin
        clk = 1'b0;
        forever #10 clk = ~clk;
    end
        
    initial begin
        rst = `RstEnable;
        #200 rst= `RstDisable;
        // #5000 $stop;
    end

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
    .clk(clk),
    .rst(rst),

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
    
    .init_i(5'b00000)
    );

    wire[3:0] arid;
    wire[31:0] araddr;
    wire[7:0] arlen;
    wire[2:0] arsize;
    wire[1:0] arburst;
    wire[1:0] arlock;
    wire[3:0] arcache;
    wire[2:0] arprot;
    wire arvalid;
    wire arready;
           
    wire[3:0] rid;
    wire[31:0] rdata;
    wire[1:0] rresp;
    wire rlast;
    wire rvalid;
    wire rready;
           
    wire[3:0] awid;
    wire[31:0] awaddr;
    wire[7:0] awlen;
    wire[2:0] awsize;
    wire[1:0] awburst;
    wire[1:0] awlock;
    wire[3:0] awcache;
    wire[2:0] awprot;
    wire awvalid;
    wire awready;
          
    wire[3:0] wid;
    wire[31:0] wdata;
    wire[3:0] wstrb;
    wire wlast;
    wire wvalid;
    wire wready;
           
    wire[3:0] bid;
    wire[1:0] bresp;
    wire bvalid;
    wire bready;

    cpu_axi_interface cpu_axi_interface0(
    .clk(clk),
    .resetn(~rst), 

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
    .data_addr(data_addr),
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

    axi_ram flash(
        .s_aclk(clk),
        .s_aresetn(~rst), // 反转时钟：上升沿CPU给地址，下降沿ROM给数据，下一个上升沿CPU取数据
        .s_axi_arid(arid),
        .s_axi_araddr(araddr),
        .s_axi_arlen(arlen),
        .s_axi_arsize(arsize),
        .s_axi_arburst(arburst),
        // .s_axi_arlock(arlock),
        // .s_axi_arcache(arcache),
        // .s_axi_arprot(arprot),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),

        .s_axi_rid(rid),
        .s_axi_rdata(rdata),
        .s_axi_rresp(rresp),
        .s_axi_rlast(rlast),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),

        .s_axi_awid(awid),
        .s_axi_awaddr(awaddr),
        .s_axi_awlen(awlen),
        .s_axi_awsize(awsize),
        .s_axi_awburst(awburst),
        // .s_axi_awlock(awlock),
        // .s_axi_awcache(awcache),
        // .s_axi_awprot(awprot),
        .s_axi_awvalid(awvalid),
        .s_axi_awready(awready),
        
        // .s_axi_wid(wid),
        .s_axi_wdata(wdata),
        .s_axi_wstrb(wstrb),
        .s_axi_wlast(wlast),
        .s_axi_wvalid(wvalid),
        .s_axi_wready(wready),

        .s_axi_bid(bid),
        .s_axi_bresp(bresp),
        .s_axi_bvalid(bvalid),
        .s_axi_bready(bready)
    );

endmodule
