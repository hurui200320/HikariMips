// `default_nettype none
module cpu_axi_interface
(
    input  wire        clk,
    input  wire        resetn, 

    //inst sram-like 
    input  wire        inst_req     ,
    input  wire[3:0]   inst_burst   , // 0000 -> 1 word, 1111 -> 16 words
    input  wire[31:0]  inst_addr    ,
    output reg [511:0] inst_rdata   ,
    output wire        inst_addr_ok ,
    output reg         inst_data_ok ,
    
    //data sram-like 
    input  wire        data_req     ,
    input  wire[3:0]   data_burst   , // 0000 -> 1 word, 1111 -> 16 words
    input  wire        data_wr      ,
    input  wire[63:0]  data_strb    ,
    input  wire[31:0]  data_addr    ,
    input  wire[511:0] data_wdata   ,
    output reg [511:0] data_rdata   ,
    output wire        data_addr_ok ,
    output reg         data_data_ok ,

    //axi
    //ar
    output wire[31:0]  araddr       ,
    output wire[7 :0]  arlen        ,
    output wire[2 :0]  arsize       ,
    output wire[1 :0]  arburst      ,
    output wire[3 :0]  arcache      ,
    output reg         arvalid      ,
    input  wire        arready      ,
    //r
    input  wire[31:0]  rdata        ,
    input  wire[1 :0]  rresp        ,
    input  wire        rlast        ,
    input  wire        rvalid       ,
    output reg         rready       ,
    //aw          
    output wire[31:0]  awaddr       ,
    output wire[7 :0]  awlen        ,
    output wire[2 :0]  awsize       ,
    output wire[1 :0]  awburst      ,
    output wire[3 :0]  awcache      ,
    output reg         awvalid      ,
    input  wire        awready      ,
    //w          
    output reg [31:0]  wdata        ,
    output reg [3 :0]  wstrb        ,
    output reg         wlast        ,
    output reg         wvalid       ,
    input  wire        wready       ,
    //b           
    input  wire[1 :0]  bresp        ,
    input  wire        bvalid       ,
    output reg         bready       
);

reg[31:0] read_addr;
reg[3:0] read_burst;
reg[511:0] read_result;
// [1]: 0 inst, 1 data; [0]: 0 reading, 1 done.
reg[1:0] read_if_or_mem;
reg read_en; // 使能读状态机，为1时读状态机开始启动

reg[31:0] write_addr;
reg[3:0] write_burst;
reg[511:0] write_data;
reg[63:0] write_strb;
reg write_done; // 0 writing, 1 done
reg write_en; // 使能写状态机，为1时写状态机开始启动

// data地址握手：若读则需要读状态机没有使能，若写则要求写状态机没有使能
assign data_addr_ok = data_wr ? !write_en : !read_en;
// 表示data已经发起请求
wire data_read_req = data_req && !data_wr;
// inst地址握手：读状态机没有使能，且data没有发起请求
assign inst_addr_ok = !read_en && !data_read_req;

// SRAM握手
always @ (posedge clk) begin
    if (!resetn) begin
        read_en <= 1'b0;
        write_en <= 1'b0;
        read_addr <= 32'd0;
        write_addr <= 32'd0;
        inst_data_ok <= 1'b0;
        data_data_ok <= 1'b0;
        read_burst <= 4'b0000;
        write_burst <= 4'b0000;
    end else begin
        // 正常逻辑
        if (!write_en) begin
            // 当前没有写操作
            if (data_wr) begin
                // 如果上一个是写
                data_data_ok <= 1'b0; // 清除数据握手
            end
            if (data_req && data_wr) begin
                // data要写
                // 记录写信息
                write_addr <= data_addr;
                write_data <= data_wdata;
                write_strb <= data_strb;
                write_burst <= data_burst;

                write_en <= 1'b1; // 启动写状态机
            end else begin
                // 不写则保证写状态机关闭
                write_en <= 1'b0;
            end
        end else begin
            // 当前有写操作
            if (write_done) begin
                // 写完了
                data_data_ok <= 1'b1; // 进行数据握手
                write_en <= 1'b0; // 关闭写状态机
            end else begin
                // 还在写
                data_data_ok <= 1'b0; // 不握手
                write_en <= 1'b1; // 保持写状态机打开
            end
        end

        if (!read_en) begin
            // 当前没有读操作
            if (!data_wr) begin
                // 如果上一个是读
                data_data_ok <= 1'b0; // 清除数据握手
            end
            inst_data_ok <= 1'b0; // 清除数据握手
            if (data_req && !data_wr) begin
                // data要读
                // 记录读信息
                read_addr <= data_addr;
                read_burst <= data_burst;
                read_if_or_mem[1] <= 1'b1; // 记录当前读data

                read_en <= 1'b1; // 启动读状态机
            end else if (inst_req) begin
                // inst要读
                read_addr <= inst_addr;
                read_burst <= inst_burst;
                read_if_or_mem[1] <= 1'b0; // 记录当前读inst

                read_en <= 1'b1; // 启动读状态机
            end else begin
                // 不写则保证读状态机关闭
                read_en <= 1'b0;
            end
        end else begin
            // 当前有读操作
            if (read_if_or_mem[1]) begin
                // 读data
                if (read_if_or_mem[0]) begin
                    // 读完了
                    data_rdata <= read_result;
                    data_data_ok <= 1'b1; // 进行数据握手
                    read_en <= 1'b0; // 关闭读状态机
                end else begin
                    // 还在写
                    data_data_ok <= 1'b0; // 不握手
                    read_en <= 1'b1; // 保持读状态机打开
                end
            end else begin
                // 读inst
                if (read_if_or_mem[0]) begin
                    // 读完了
                    inst_rdata <= read_result;
                    inst_data_ok <= 1'b1; // 进行数据握手
                    read_en <= 1'b0; // 关闭读状态机
                end else begin
                    // 还在写
                    inst_data_ok <= 1'b0; // 不握手
                    read_en <= 1'b1; // 保持读状态机打开
                end
            end
        end
    end
end

// AXI读状态机
reg[1:0] read_status;
assign araddr = {3'b000, read_addr[28:0]}; // Fixed map
assign arlen  = {4'b0000, read_burst};
assign arsize = 3'b010; // always transfer 4 bytes
assign arburst = 2'b01; // incr
assign arcache = (read_addr[31:29] == 3'b101) ? 4'b0000 : 4'b1111;
reg[3:0] read_counter;

always @ (posedge clk) begin
    if (!read_en) begin
        // 没有读使能，就一直复位
        read_status <= 2'b00;
        read_if_or_mem[0] <= 1'b0; // 取消done置位
        read_counter <= 4'b0000;
        arvalid <= 1'b0;
        rready <= 1'b0;
    end else begin
        // 正常状态
        case (read_status)
            2'b00: begin
                // AR发出请求
                read_status <= 2'b01;
                arvalid <= 1'b1; // 允许AR握手
            end 
            2'b01: begin
                // 写AR通道进行AXI地址握手
                if (arready && arvalid) begin
                    // AR握手成功
                    read_counter <= (4'b1111 - arlen[3:0]); // 清零counter  
                    read_result <= 512'd0;
                    // 如果arlen是burst传输，则低位是f，减去后counter正好为0
                    // 如果不是burst传输，保证最后一次传输一定写在31:0处
                    arvalid <= 1'b0; // 撤销握手信号
                    read_status <= 2'b10;
                    rready <= 1'b1; // 准备接收数据
                end else begin
                    arvalid <= 1'b1; // 保持AR握手
                    read_status <= 2'b01;
                    rready <= 1'b0;
                end
            end 
            2'b10: begin
                // 等待R通道的数据握手
                if (rready && rvalid) begin
                    // 本次握手成功
                    case (read_counter)
                        4'b0000: begin
                            read_result[511:480] <= rdata;
                        end 
                        4'b0001: begin
                            read_result[479:448] <= rdata;
                        end 
                        4'b0010: begin
                            read_result[447:416] <= rdata;
                        end 
                        4'b0011: begin
                            read_result[415:384] <= rdata;
                        end 
                        4'b0100: begin
                            read_result[383:352] <= rdata;
                        end 
                        4'b0101: begin
                            read_result[351:320] <= rdata;
                        end 
                        4'b0110: begin
                            read_result[319:288] <= rdata;
                        end 
                        4'b0111: begin
                            read_result[287:256] <= rdata;
                        end 
                        4'b1000: begin
                            read_result[255:224] <= rdata;
                        end 
                        4'b1001: begin
                            read_result[223:192] <= rdata;
                        end 
                        4'b1010: begin
                            read_result[191:160] <= rdata;
                        end 
                        4'b1011: begin
                            read_result[159:128] <= rdata;
                        end 
                        4'b1100: begin
                            read_result[127:96] <= rdata;
                        end 
                        4'b1101: begin
                            read_result[95:64] <= rdata;
                        end 
                        4'b1110: begin
                            read_result[63:32] <= rdata;
                        end 
                        4'b1111: begin
                            read_result[31:0] <= rdata;
                        end 
                        default: begin
                            // do nothing
                        end
                    endcase
                    read_counter <= read_counter + 1;
                    
                    // 最后一个则结束传输
                    if (rlast) begin
                        // 这里设置读结束，下一个周期应该关闭读状态机使能
                        // 从而中断状态机的执行，否则就原地等待
                        read_if_or_mem[0] <= 1'b1; // 表示读结束
                        rready <= 1'b0;
                    end
                end
            end 
            default: begin
                read_if_or_mem[0] <= 1'b0;
                read_status <= 2'b00;
                read_counter <= 4'b0000;
            end
        endcase
    end
end

// AXI写状态机
reg[2:0] write_status;
assign awaddr = {3'b000, write_addr[28:0]}; // Fixed map
assign awlen  = {4'b0000, write_burst};
assign awsize = 3'b010; // always transfer 4 bytes
assign awburst = 2'b01; // incr
assign awcache = (write_addr[31:29] == 3'b101) ? 4'b0000 : 4'b1111;
reg[3:0] write_counter;

always @ (posedge clk) begin
    if (!write_en) begin
        // 没有写使能则复位
        write_status <= 3'b000;
        write_counter <= 4'b0000;
        write_done <= 1'b0;
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        bready <= 1'b0;
    end else begin
        case (write_status)
            3'b000: begin
                // 发起AW请求
                write_status <= 3'b001;
                awvalid <= 1'b1; // 允许AW握手
            end 
            3'b001: begin
                // 写AW通道进行写地址握手
                if (awvalid && awready) begin
                    // AW握手成功
                    write_counter <= (4'b1111 - awlen[3:0]);
                    awvalid <= 1'b0;
                    write_status <= 3'b010;
                    wvalid <= 1'b1;
                end else begin
                    awvalid <= 1'b1;
                    write_status <= 3'b001;
                    wvalid <= 1'b0;
                end
            end 
            3'b010: begin
                // 写W通道进行数据传输
                // 这里只更新counter等基础reg
                // strb和wdata信号由逻辑电路在时钟下降沿提前产生
                if (wvalid && wready) begin
                    // 握手成功，准备下一次传输
                    if (write_counter != 4'b1111) begin
                        // 不是最后一次传输
                        write_counter <= write_counter + 1;
                    end else begin
                        // 是最后一次传输
                        write_status <= 3'b011;
                        wvalid <= 1'b0;
                        bready <= 1'b1;
                    end
                end
            end 
            3'b011: begin
                // 等待B通道返回写入结果
                if (bready && bvalid) begin
                    // B通道握手成功，忽略结果
                    // 日后如果CPU实现总线异常
                    // 可以在此处判断写入是否成功
                    bready <= 1'b0;
                    // 写结束，下一个周期应当关闭写使能进行复位
                    // 否则就原地等待
                    write_done <= 1'b1; 
                end else begin
                    write_status <= 3'b011;
                end
            end 
            default: begin
                write_done <= 1'b0;
                write_status <= 3'b000;
                write_counter <= 4'b0000;
            end
        endcase
    end
end

// 生成wdata、wstrb和wlast
always @ (*) begin
    if (!write_en) begin
        wdata <= 32'd0;
        wstrb <= 4'b0000;
        wlast <= 1'b0;
    end else begin
        if (wvalid) begin
            // 根据状态生成要写入的数据
            case (write_counter)
                4'b0000: begin
                    wdata <= data_wdata[511:480];
                    wstrb <= data_strb[63:60];
                    wlast <= 1'b0;
                end 
                4'b0001: begin
                    wdata <= data_wdata[479:448];
                    wstrb <= data_strb[59:56];
                    wlast <= 1'b0;
                end 
                4'b0010: begin
                    wdata <= data_wdata[447:416];
                    wstrb <= data_strb[55:52];
                    wlast <= 1'b0;
                end 
                4'b0011: begin
                    wdata <= data_wdata[415:384];
                    wstrb <= data_strb[51:48];
                    wlast <= 1'b0;
                end 
                4'b0100: begin
                    wdata <= data_wdata[383:352];
                    wstrb <= data_strb[47:44];
                    wlast <= 1'b0;
                end 
                4'b0101: begin
                    wdata <= data_wdata[351:320];
                    wstrb <= data_strb[43:40];
                    wlast <= 1'b0;
                end 
                4'b0110: begin
                    wdata <= data_wdata[319:288];
                    wstrb <= data_strb[39:36];
                    wlast <= 1'b0;
                end 
                4'b0111: begin
                    wdata <= data_wdata[287:256];
                    wstrb <= data_strb[35:32];
                    wlast <= 1'b0;
                end 
                4'b1000: begin
                    wdata <= data_wdata[255:224];
                    wstrb <= data_strb[31:28];
                    wlast <= 1'b0;
                end 
                4'b1001: begin
                    wdata <= data_wdata[223:192];
                    wstrb <= data_strb[27:24];
                    wlast <= 1'b0;
                end 
                4'b1010: begin
                    wdata <= data_wdata[191:160];
                    wstrb <= data_strb[23:20];
                    wlast <= 1'b0;
                end 
                4'b1011: begin
                    wdata <= data_wdata[159:128];
                    wstrb <= data_strb[19:16];
                    wlast <= 1'b0;
                end 
                4'b1100: begin
                    wdata <= data_wdata[127:96];
                    wstrb <= data_strb[15:12];
                    wlast <= 1'b0;
                end 
                4'b1101: begin
                    wdata <= data_wdata[95:64];
                    wstrb <= data_strb[11:8];
                    wlast <= 1'b0;
                end 
                4'b1110: begin
                    wdata <= data_wdata[63:32];
                    wstrb <= data_strb[7:4];
                    wlast <= 1'b0;
                end 
                4'b1111: begin
                    wdata <= data_wdata[31:0];
                    wstrb <= data_strb[3:0];
                    wlast <= 1'b1;
                end 
                default: begin
                    wdata <= 32'd0;
                    wstrb <= 4'b0000;
                    wlast <= 1'b0;
                end
            endcase
        end else begin
            wdata <= 32'd0;
            wstrb <= 4'b0000;
            wlast <= 1'b0;
        end
    end
end

endmodule

