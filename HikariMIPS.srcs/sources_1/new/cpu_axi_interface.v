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
reg read_en; // ʹ�ܶ�״̬����Ϊ1ʱ��״̬����ʼ����

reg[31:0] write_addr;
reg[3:0] write_burst;
reg[511:0] write_data;
reg[63:0] write_strb;
reg write_done; // 0 writing, 1 done
reg write_en; // ʹ��д״̬����Ϊ1ʱд״̬����ʼ����

// data��ַ���֣���������Ҫ��״̬��û��ʹ�ܣ���д��Ҫ��д״̬��û��ʹ��
assign data_addr_ok = data_wr ? !write_en : !read_en;
// ��ʾdata�Ѿ���������
wire data_read_req = data_req && !data_wr;
// inst��ַ���֣���״̬��û��ʹ�ܣ���dataû�з�������
assign inst_addr_ok = !read_en && !data_read_req;

// SRAM����
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
        // �����߼�
        if (!write_en) begin
            // ��ǰû��д����
            if (data_wr) begin
                // �����һ����д
                data_data_ok <= 1'b0; // �����������
            end
            if (data_req && data_wr) begin
                // dataҪд
                // ��¼д��Ϣ
                write_addr <= data_addr;
                write_data <= data_wdata;
                write_strb <= data_strb;
                write_burst <= data_burst;

                write_en <= 1'b1; // ����д״̬��
            end else begin
                // ��д��֤д״̬���ر�
                write_en <= 1'b0;
            end
        end else begin
            // ��ǰ��д����
            if (write_done) begin
                // д����
                data_data_ok <= 1'b1; // ������������
                write_en <= 1'b0; // �ر�д״̬��
            end else begin
                // ����д
                data_data_ok <= 1'b0; // ������
                write_en <= 1'b1; // ����д״̬����
            end
        end

        if (!read_en) begin
            // ��ǰû�ж�����
            if (!data_wr) begin
                // �����һ���Ƕ�
                data_data_ok <= 1'b0; // �����������
            end
            inst_data_ok <= 1'b0; // �����������
            if (data_req && !data_wr) begin
                // dataҪ��
                // ��¼����Ϣ
                read_addr <= data_addr;
                read_burst <= data_burst;
                read_if_or_mem[1] <= 1'b1; // ��¼��ǰ��data

                read_en <= 1'b1; // ������״̬��
            end else if (inst_req) begin
                // instҪ��
                read_addr <= inst_addr;
                read_burst <= inst_burst;
                read_if_or_mem[1] <= 1'b0; // ��¼��ǰ��inst

                read_en <= 1'b1; // ������״̬��
            end else begin
                // ��д��֤��״̬���ر�
                read_en <= 1'b0;
            end
        end else begin
            // ��ǰ�ж�����
            if (read_if_or_mem[1]) begin
                // ��data
                if (read_if_or_mem[0]) begin
                    // ������
                    data_rdata <= read_result;
                    data_data_ok <= 1'b1; // ������������
                    read_en <= 1'b0; // �رն�״̬��
                end else begin
                    // ����д
                    data_data_ok <= 1'b0; // ������
                    read_en <= 1'b1; // ���ֶ�״̬����
                end
            end else begin
                // ��inst
                if (read_if_or_mem[0]) begin
                    // ������
                    inst_rdata <= read_result;
                    inst_data_ok <= 1'b1; // ������������
                    read_en <= 1'b0; // �رն�״̬��
                end else begin
                    // ����д
                    inst_data_ok <= 1'b0; // ������
                    read_en <= 1'b1; // ���ֶ�״̬����
                end
            end
        end
    end
end

// AXI��״̬��
reg[1:0] read_status;
assign araddr = {3'b000, read_addr[28:0]}; // Fixed map
assign arlen  = {4'b0000, read_burst};
assign arsize = 3'b010; // always transfer 4 bytes
assign arburst = 2'b01; // incr
assign arcache = (read_addr[31:29] == 3'b101) ? 4'b0000 : 4'b1111;
reg[3:0] read_counter;

always @ (posedge clk) begin
    if (!read_en) begin
        // û�ж�ʹ�ܣ���һֱ��λ
        read_status <= 2'b00;
        read_if_or_mem[0] <= 1'b0; // ȡ��done��λ
        read_counter <= 4'b0000;
        arvalid <= 1'b0;
        rready <= 1'b0;
    end else begin
        // ����״̬
        case (read_status)
            2'b00: begin
                // AR��������
                read_status <= 2'b01;
                arvalid <= 1'b1; // ����AR����
            end 
            2'b01: begin
                // дARͨ������AXI��ַ����
                if (arready && arvalid) begin
                    // AR���ֳɹ�
                    read_counter <= (4'b1111 - arlen[3:0]); // ����counter  
                    read_result <= 512'd0;
                    // ���arlen��burst���䣬���λ��f����ȥ��counter����Ϊ0
                    // �������burst���䣬��֤���һ�δ���һ��д��31:0��
                    arvalid <= 1'b0; // ���������ź�
                    read_status <= 2'b10;
                    rready <= 1'b1; // ׼����������
                end else begin
                    arvalid <= 1'b1; // ����AR����
                    read_status <= 2'b01;
                    rready <= 1'b0;
                end
            end 
            2'b10: begin
                // �ȴ�Rͨ������������
                if (rready && rvalid) begin
                    // �������ֳɹ�
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
                    
                    // ���һ�����������
                    if (rlast) begin
                        // �������ö���������һ������Ӧ�ùرն�״̬��ʹ��
                        // �Ӷ��ж�״̬����ִ�У������ԭ�صȴ�
                        read_if_or_mem[0] <= 1'b1; // ��ʾ������
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

// AXIд״̬��
reg[2:0] write_status;
assign awaddr = {3'b000, write_addr[28:0]}; // Fixed map
assign awlen  = {4'b0000, write_burst};
assign awsize = 3'b010; // always transfer 4 bytes
assign awburst = 2'b01; // incr
assign awcache = (write_addr[31:29] == 3'b101) ? 4'b0000 : 4'b1111;
reg[3:0] write_counter;

always @ (posedge clk) begin
    if (!write_en) begin
        // û��дʹ����λ
        write_status <= 3'b000;
        write_counter <= 4'b0000;
        write_done <= 1'b0;
        awvalid <= 1'b0;
        wvalid <= 1'b0;
        bready <= 1'b0;
    end else begin
        case (write_status)
            3'b000: begin
                // ����AW����
                write_status <= 3'b001;
                awvalid <= 1'b1; // ����AW����
            end 
            3'b001: begin
                // дAWͨ������д��ַ����
                if (awvalid && awready) begin
                    // AW���ֳɹ�
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
                // дWͨ���������ݴ���
                // ����ֻ����counter�Ȼ���reg
                // strb��wdata�ź����߼���·��ʱ���½�����ǰ����
                if (wvalid && wready) begin
                    // ���ֳɹ���׼����һ�δ���
                    if (write_counter != 4'b1111) begin
                        // �������һ�δ���
                        write_counter <= write_counter + 1;
                    end else begin
                        // �����һ�δ���
                        write_status <= 3'b011;
                        wvalid <= 1'b0;
                        bready <= 1'b1;
                    end
                end
            end 
            3'b011: begin
                // �ȴ�Bͨ������д����
                if (bready && bvalid) begin
                    // Bͨ�����ֳɹ������Խ��
                    // �պ����CPUʵ�������쳣
                    // �����ڴ˴��ж�д���Ƿ�ɹ�
                    bready <= 1'b0;
                    // д��������һ������Ӧ���ر�дʹ�ܽ��и�λ
                    // �����ԭ�صȴ�
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

// ����wdata��wstrb��wlast
always @ (*) begin
    if (!write_en) begin
        wdata <= 32'd0;
        wstrb <= 4'b0000;
        wlast <= 1'b0;
    end else begin
        if (wvalid) begin
            // ����״̬����Ҫд�������
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

