/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

module cpu_axi_interface
(
    input  wire        clk,
    input  wire        resetn, 

    //inst sram-like 
    input  wire        inst_req     ,
    input  wire        inst_wr      ,
    input  wire[3 :0]  inst_strb    ,
    input  wire[31:0]  inst_addr    ,
    input  wire[31:0]  inst_wdata   ,
    output wire[31:0]  inst_rdata   ,
    output wire        inst_addr_ok ,
    output wire        inst_data_ok ,
    
    //data sram-like 
    input  wire        data_req     ,
    input  wire        data_wr      ,
    input  wire[3 :0]  data_strb    ,
    input  wire[31:0]  data_addr    ,
    input  wire[31:0]  data_wdata   ,
    output wire[31:0]  data_rdata   ,
    output wire        data_addr_ok ,
    output wire        data_data_ok ,

    //axi
    //ar
    output wire[3 :0]  arid         ,
    output wire[31:0]  araddr       ,
    output wire[7 :0]  arlen        ,
    output wire[2 :0]  arsize       ,
    output wire[1 :0]  arburst      ,
    output wire[1 :0]  arlock       ,
    output wire[3 :0]  arcache      ,
    output wire[2 :0]  arprot       ,
    output wire        arvalid      ,
    input  wire        arready      ,
    //r           
    input  wire[3 :0]  rid          ,
    input  wire[31:0]  rdata        ,
    input  wire[1 :0]  rresp        ,
    input  wire        rlast        ,
    input  wire        rvalid       ,
    output wire        rready       ,
    //aw          
    output wire[3 :0]  awid         ,
    output wire[31:0]  awaddr       ,
    output wire[7 :0]  awlen        ,
    output wire[2 :0]  awsize       ,
    output wire[1 :0]  awburst      ,
    output wire[1 :0]  awlock       ,
    output wire[3 :0]  awcache      ,
    output wire[2 :0]  awprot       ,
    output wire        awvalid      ,
    input  wire        awready      ,
    //w          
    output wire[3 :0]  wid          ,
    output wire[31:0]  wdata        ,
    output wire[3 :0]  wstrb        ,
    output wire        wlast        ,
    output wire        wvalid       ,
    input  wire        wready       ,
    //b           
    input  wire[3 :0]  bid          ,
    input  wire[1 :0]  bresp        ,
    input  wire        bvalid       ,
    output wire        bready       
);

// TODO 加地址转换和Cache，然后上板看一下性能，不行的话就给IF加brust和小Cache
//  取指先看小Cache有没有覆盖，有就直接给数据，没有再通过新的信号线高速IF进行常规请求

//addr
reg  do_req;
reg  do_req_or; //req is inst or data;1:data,0:inst
reg         do_wr_r;
reg[3 :0]   do_strb_r;
reg[31:0]   do_addr_r;
reg[31:0]   do_wdata_r;
wire data_back;

assign inst_addr_ok = !do_req&&!data_req;
assign data_addr_ok = !do_req;
always @(posedge clk)
begin
    do_req     <= !resetn                       ? 1'b0 : 
                  (inst_req||data_req)&&!do_req ? 1'b1 :
                  data_back                     ? 1'b0 : do_req;
    do_req_or  <= !resetn ? 1'b0 : 
                  !do_req ? data_req : do_req_or;

    do_wr_r    <= data_req&&data_addr_ok ? data_wr :
                  inst_req&&inst_addr_ok ? inst_wr : do_wr_r;
    do_strb_r  <= data_req&&data_addr_ok ? data_strb :
                  inst_req&&inst_addr_ok ? inst_strb : do_strb_r;
    do_addr_r  <= data_req&&data_addr_ok ? data_addr :
                  inst_req&&inst_addr_ok ? inst_addr : do_addr_r;
    // handle addr map
    case (do_addr_r[31:28])
        4'b1000, 4'b1001: begin
            do_addr_r[31] <= 1'b0;
        end 
        4'b1010, 4'b1011: begin
            do_addr_r[31:29] <= 3'b000;
        end
        default: begin
        end
    endcase
    do_wdata_r <= data_req&&data_addr_ok ? data_wdata :
                  inst_req&&inst_addr_ok ? inst_wdata :do_wdata_r;
end

//inst sram-like
assign inst_data_ok = do_req&&!do_req_or&&data_back;
assign data_data_ok = do_req&& do_req_or&&data_back;
assign inst_rdata   = rdata;
assign data_rdata   = rdata;

//---axi
reg  addr_rcv;
reg  wdata_rcv;

assign data_back = addr_rcv && (rvalid&&rready||bvalid&&bready);
always @(posedge clk)
begin
    addr_rcv  <= !resetn          ? 1'b0 :
                 arvalid&&arready ? 1'b1 :
                 awvalid&&awready ? 1'b1 :
                 data_back        ? 1'b0 : addr_rcv;
    wdata_rcv <= !resetn        ? 1'b0 :
                 wvalid&&wready ? 1'b1 :
                 data_back      ? 1'b0 : wdata_rcv;
end
//ar
assign arid    = 4'd0;
assign araddr  = do_addr_r;
assign arlen   = 8'd0;
assign arsize  = 2'd4; // 一次固定读四字节，MEM模块内筛选
assign arburst = 2'd0;
assign arlock  = 2'd0;
assign arcache = 4'd0;
assign arprot  = 3'd0;
assign arvalid = do_req&&!do_wr_r&&!addr_rcv;
//r
assign rready  = 1'b1;

//aw
assign awid    = 4'd0;
assign awaddr  = do_addr_r;
assign awlen   = 8'd0;
assign awsize  = 2'd4; // 一次传输4字节，固定的，依靠strb筛选
assign awburst = 2'd0;
assign awlock  = 2'd0;
assign awcache = 4'd0;
assign awprot  = 3'd0;
assign awvalid = do_req&&do_wr_r&&!addr_rcv;
//w
assign wid    = 4'd0;
assign wdata  = do_wdata_r;
assign wstrb  = do_strb_r;
assign wlast  = 1'd1;
assign wvalid = do_req&&do_wr_r&&!wdata_rcv;
//b
assign bready  = 1'b1;

endmodule

