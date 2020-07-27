
//////////////////////////////////////////////////////////////////////////////////
// 访存阶段
// 寄存器： 31:24   23:16   15:8   7:0
// 地址：   0x03    0x02    0x01   0x00
// 所以按字节写入0x03时是写入寄存器高8位，sel为1000
// 半字写入时，例如写0x00，实际上写入的数据是寄存器低16位
// 由于这里RAM是32位的位宽，可以选择编址使得其字节地址与寄存器相对应：
// RAM：| 0x03 0x02 0x01 0x00 | 0x07 0x06 0x05 0x04 | ...
// 因为0x00~0x03访问的都是第一个32位的单元，其内部字节如何安排如何编地址就可以随意了
// 最终半字写0x00时sel即为0011，若半字写0x10则sel就是1100了
// 如果最终在外部写入8字节RAM，最终AXI接口的SRAM控制器会做转换（会的吧）
// 关于LWL和LWR，需要按字节顺序想：
// 物理地址下0x01~0x04是一个非对齐的字，要读取进寄存器：
// | 0x00 0x01 0x02 0x03 | 0x04 0x05 0x06 0x07 |
// | a+1  a+2  a+3       |                 a   |
// 转换成上面说的自定义编址（以32位的块访问，块内地址自定义）：
// | 0x03 0x02 0x01 0x00 | 0x07 0x06 0x05 0x04 |
//        a+3  a+2  a+1     a  
// 这时候lwl 0x02 -> a+3 a+2 a+1 ...
//      lwr 0x07 -> ... ... ...  a 
// SWL和SWR刚好是LWL和LWR的逆操作，读哪里写哪里就是了。
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module mem(
    input wire clk,
    input wire rst,
    
    // 来自执行阶段的信息    
    input wire[`RegAddrBus] waddr_i,
    input wire we_i,
    input wire[`RegBus] wdata_i,
    input wire we_hilo_i,
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,
    input wire[`AluOpBus] aluop_i,
    input wire[`RegBus] mem_addr_i,
    input wire[`RegBus] reg2_i,
    input wire cp0_we_i,
    input wire[7:0] cp0_waddr_i,
    input wire[`RegBus] cp0_wdata_i,
    input wire[31:0] exceptions_i,
    input wire[`RegBus] pc_i,
    input wire is_in_delayslot_i,

    // CP0，用以判断中断能否发生（未被屏蔽）
    input wire[`RegBus] cp0_status_i,
    input wire[`RegBus] cp0_cause_i,
    input wire[`RegBus] cp0_epc_i,

    // 异常
    output wire[`RegBus] pc_o,
    output wire is_in_delayslot_o,
    (*mark_debug = "true"*)output reg exception_occured_o, // 发生异常时下面的字段才有效
    (*mark_debug = "true"*)output reg[4:0] exc_code_o,
    (*mark_debug = "true"*)output reg[`RegBus] bad_addr_o,
    
    // 送到回写阶段的信息
    output reg[`RegAddrBus] waddr_o,
    output wire we_o,
    output reg[`RegBus] wdata_o,
    output reg we_hilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,
    output reg cp0_we_o,
    output reg[7:0] cp0_waddr_o,
    output reg[`RegBus] cp0_wdata_o,
    
    // 数据RAM
    input wire[`RegBus] mem_data_i,
    input wire mem_addr_ok,
    input wire mem_data_ok,
    // 送往数据RAM的信号
    output reg[`RegBus] mem_addr_o,
    output reg mem_wr_o,
    // 寄存器： 31:24   23:16   15:8   7:0
    // strb     1000    0100   0010   0001
    output reg[3:0] mem_strb_o,
    output reg[`RegBus] mem_data_o,
    output wire mem_req_o,
    output reg stallreq
    );

    reg req_en;    
    reg mem_ce;

    assign we_o = exception_occured_o ? `WriteDisable : we_i;

    reg[1:0] status;

    // 握手状态机
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            req_en <= `False_v;
            status <= 2'b00;
        end else begin
            case (status)
                2'b00: begin // 空闲阶段
                    if (mem_ce) begin
                        // 如果CE启用（要访问）
                        // 进入等待地址握手阶段
                        req_en <= `True_v;
                        status <= 2'b01;
                    end else begin
                        // 原地等待
                        req_en <= `False_v;
                    end
                end
                2'b01: begin // 等待地址握手
                    if (!mem_addr_ok) begin
                        // 地址握手不成功，原地等待
                    end else begin
                        // 地址握手成功，撤销req请求并转入地址握手
                        req_en <= `False_v;
                        status <= 2'b10;
                    end
                end
                2'b10: begin // 等待数据握手
                    if (!mem_data_ok) begin
                        // 数据握手不成功，原地等待
                    end else begin
                        // 数据握手成功，撤销流水线暂停
                        // 转入空闲阶段
                        status <= 2'b00;
                    end
                end
                default: begin
                    req_en <= `True_v;
                    status <= 2'b00;
                end
            endcase
        end
    end

    // 产生流水线暂停信号
    always @ (*) begin
        if (rst == `RstEnable) begin
            stallreq <= `False_v;
        end else begin
            case (status)
                2'b00: begin // 空闲阶段
                    if (mem_ce) begin
                        // 如果CE启用（要访问）
                        // 立刻暂停流水线，随后进入等待地址握手阶段
                        stallreq <= `True_v;
                    end else begin
                        // 原地等待
                        stallreq <= `False_v;
                    end
                end
                2'b01: begin // 等待地址握手
                    // 地址握手期间始终保持流水线暂停
                    stallreq <= `True_v;
                end
                2'b10: begin // 等待数据握手
                    if (!mem_data_ok) begin
                        // 数据握手不成功，原地等待
                        stallreq <= `True_v;
                    end else begin
                        // 数据握手成功，立刻撤销流水线暂停
                        // 转入空闲阶段
                        stallreq <= `False_v;
                    end
                end
                default: begin
                    stallreq <= `False_v;
                end
            endcase
        end
    end

    // 没有发生异常才允许存储器操作
    assign mem_req_o = req_en && mem_ce && (~exception_occured_o);
    assign is_in_delayslot_o = is_in_delayslot_i;
    assign pc_o = pc_i;
    reg read_exception;
    reg write_exception;

    // 产生异常ExcCode
    always @ (*) begin
        if (rst == `RstEnable) begin
            exception_occured_o <= `False_v;
        end else begin
            // 等待cpu复位或清空流水线
            if (pc_i != `ZeroWord) begin
                exception_occured_o <= `True_v; // 默认有异常
                if (((cp0_cause_i[15:8] & cp0_status_i[15:8]) != 8'd0) // 有未被屏蔽的中断申请
                && cp0_status_i[2] == 1'b0 && cp0_status_i[1] == 1'b0 // 不在异常级或错误级中
                && cp0_status_i[0] == 1'b1 /* 总中断开启 */)  begin
                    exc_code_o <= 5'h00;
                end else if (exceptions_i[0]) begin
                    // PC取指未对齐
                    exc_code_o <= 5'h04;
                    bad_addr_o <= pc_i;
                end else if (exceptions_i[1]) begin
                    // 无效指令
                    exc_code_o <= 5'h0a;
                end else if (exceptions_i[5]) begin
                    // 溢出
                    exc_code_o <= 5'h0c;
                end else if (exceptions_i[6]) begin
                    // 自陷
                    exc_code_o <= 5'h0d;
                end else if (exceptions_i[4]) begin
                    // Syscall调用
                    exc_code_o <= 5'h08;
                end else if (exceptions_i[3]) begin
                    // Break调用
                    exc_code_o <= 5'h09;
                end else if (read_exception) begin
                    exc_code_o <= 5'h04;
                    bad_addr_o <= mem_addr_i;
                end else if (write_exception) begin
                    exc_code_o <= 5'h05;
                    bad_addr_o <= mem_addr_i;
                end else if (exceptions_i[2]) begin
                    // ERET调用
                    exc_code_o <= 5'h10; // MIPS32并未定义ERET，这里使用implementation dependent use
                end else begin
                    exception_occured_o <= `False_v;
                end
            end else begin
                exception_occured_o <= `False_v;
            end
        end
    end

    wire[`RegBus] zero32 = `ZeroWord;

    always @ (*) begin
        read_exception <= `False_v;
        write_exception <= `False_v;
        mem_addr_o <= `ZeroWord;
        mem_wr_o <= `WriteDisable;
        mem_ce <= `ChipDisable;
        if(rst == `RstEnable) begin
            waddr_o <= `NOPRegAddr;
            wdata_o <= `ZeroWord;
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
            mem_strb_o <= 4'b0000;
            mem_data_o <= `ZeroWord;
            cp0_we_o <= `WriteDisable;
            cp0_waddr_o <= 8'b00000000;
            cp0_wdata_o <= `ZeroWord;
        end else begin
            waddr_o <= waddr_i;
            wdata_o <= wdata_i;
            we_hilo_o <= we_hilo_i;
            hi_o <= hi_i;
            lo_o <= lo_i;
            mem_strb_o <= 4'b1111;
            cp0_we_o <= cp0_we_i;
            cp0_waddr_o <= cp0_waddr_i;
            cp0_wdata_o <= cp0_wdata_i;
            // 下面根据MEM_OP决定wdata、mem_data和mem_sel及片选和写使能
            case (aluop_i)
                // LB
                `MEM_OP_LB: begin
                    mem_addr_o <= mem_addr_i;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{24{mem_data_i[7]}},mem_data_i[7:0]};
                            mem_strb_o <= 4'b0001;
                        end
                        2'b01: begin
                            wdata_o <= {{24{mem_data_i[15]}},mem_data_i[15:8]};
                            mem_strb_o <= 4'b0010;
                        end
                        2'b10: begin
                            wdata_o <= {{24{mem_data_i[23]}},mem_data_i[23:16]};
                            mem_strb_o <= 4'b0100;
                        end
                        2'b11: begin
                            wdata_o <= {{24{mem_data_i[31]}},mem_data_i[31:24]};
                            mem_strb_o <= 4'b1000;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                // LH
                `MEM_OP_LH: begin
                    mem_addr_o <= mem_addr_i;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{16{mem_data_i[15]}}, mem_data_i[15:0]};
                            mem_strb_o <= 4'b0011;
                        end
                        2'b10: begin
                            wdata_o <= {{16{mem_data_i[31]}}, mem_data_i[31:16]};
                            mem_strb_o <= 4'b1100;
                        end
                        default: begin
                            // 此时一定是最低没有对齐，应当抛地址异常
                            read_exception <= `True_v;
                            wdata_o <= `ZeroWord;
                            mem_ce <= `ChipDisable;
                        end
                    endcase
                end
                // LWL
                `MEM_OP_LWL: begin
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_strb_o <= 4'b1111;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {mem_data_i[7:0],reg2_i[23:0]};
                        end
                        2'b01: begin
                            wdata_o <= {mem_data_i[15:0],reg2_i[15:0]};
                        end
                        2'b10: begin
                            wdata_o <= {mem_data_i[23:0],reg2_i[7:0]};
                        end
                        2'b11: begin
                            wdata_o <= mem_data_i[31:0];
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                // LW
                `MEM_OP_LW: begin
                    mem_addr_o <= mem_addr_i;
                    wdata_o <= mem_data_i;
                    mem_strb_o <= 4'b1111;
                    mem_ce <= `ChipEnable;
                    if (mem_addr_i[1:0] != 2'b00) begin 
                        read_exception <= `True_v;
                        mem_ce <= `ChipDisable;
                    end
                end
                // LBU
                `MEM_OP_LBU: begin
                    mem_addr_o <= mem_addr_i;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{24{1'b0}},mem_data_i[7:0]};
                            mem_strb_o <= 4'b0001;
                        end
                        2'b01: begin
                            wdata_o <= {{24{1'b0}},mem_data_i[15:8]};
                            mem_strb_o <= 4'b0010;
                        end
                        2'b10: begin
                            wdata_o <= {{24{1'b0}},mem_data_i[23:16]};
                            mem_strb_o <= 4'b0100;
                        end
                        2'b11: begin
                            wdata_o <= {{24{1'b0}},mem_data_i[31:24]};
                            mem_strb_o <= 4'b1000;
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                // LHU
                `MEM_OP_LHU: begin
                    mem_addr_o <= mem_addr_i;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[15:0]};
                            mem_strb_o <= 4'b0011;
                        end
                        2'b10: begin
                            wdata_o <= {{16{1'b0}}, mem_data_i[31:16]};
                            mem_strb_o <= 4'b1100;
                        end
                        default: begin
                            read_exception <= `True_v;
                            wdata_o <= `ZeroWord;
                            mem_ce <= `ChipDisable;
                        end
                    endcase
                end
                // LWR
                `MEM_OP_LWR: begin
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_strb_o <= 4'b1111;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            wdata_o <= mem_data_i;
                        end
                        2'b01: begin
                            wdata_o <= {reg2_i[31:24],mem_data_i[31:8]};
                        end
                        2'b10: begin
                            wdata_o <= {reg2_i[31:16],mem_data_i[31:16]};
                        end
                        2'b11: begin
                            wdata_o <= {reg2_i[31:8],mem_data_i[31:24]};
                        end
                        default: begin
                            wdata_o <= `ZeroWord;
                        end
                    endcase
                end
                // SB
                `MEM_OP_SB: begin
                    mem_addr_o <= mem_addr_i;
                    mem_wr_o <= `WriteEnable;
                    // 因为只写入1byte，因此全部复制最低位要写入的数据
                    mem_data_o <= {reg2_i[7:0],reg2_i[7:0],reg2_i[7:0],reg2_i[7:0]};
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_strb_o <= 4'b0001;
                        end
                        2'b01: begin
                            mem_strb_o <= 4'b0010;
                        end
                        2'b10: begin
                            mem_strb_o <= 4'b0100;
                        end
                        2'b11: begin
                            mem_strb_o <= 4'b1000;
                        end
                        default: begin
                            mem_strb_o <= 4'b0000;
                        end
                    endcase
                end
                // SH
                `MEM_OP_SH: begin
                    mem_addr_o <= mem_addr_i;
                    mem_wr_o <= `WriteEnable;
                    mem_data_o <= {reg2_i[15:0], reg2_i[15:0]};
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_strb_o <= 4'b0011;
                        end
                        2'b10: begin
                            mem_strb_o <= 4'b1100;
                        end
                        default: begin
                            write_exception <= `True_v;
                            mem_strb_o <= 4'b0000;
                            mem_ce <= `ChipDisable;
                        end
                    endcase
                end
                // SWL
                `MEM_OP_SWL: begin
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_wr_o <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_strb_o <= 4'b0001;
                            mem_data_o <= {zero32[23:0],reg2_i[31:24]};
                        end
                        2'b01: begin
                            mem_strb_o <= 4'b0011;
                            mem_data_o <= {zero32[15:0],reg2_i[31:16]};
                        end
                        2'b10: begin
                            mem_strb_o <= 4'b0111;
                            mem_data_o <= {zero32[7:0],reg2_i[31:8]};
                        end
                        2'b11: begin
                            mem_strb_o <= 4'b1111;
                            mem_data_o <= reg2_i;
                        end
                        default: begin
                            mem_strb_o <= 4'b0000;
                        end
                    endcase
                end
                // SW
                `MEM_OP_SW: begin
                    mem_addr_o <= mem_addr_i;
                    mem_wr_o <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_strb_o <= 4'b1111;
                    mem_ce <= `ChipEnable;
                    if (mem_addr_i[1:0] != 2'b00) begin
                        write_exception <= `True_v;
                        mem_ce <= `ChipDisable;
                    end
                end
                // SWR
                `MEM_OP_SWR: begin
                    mem_addr_o <= {mem_addr_i[31:2], 2'b00};
                    mem_wr_o <= `WriteEnable;
                    mem_data_o <= reg2_i;
                    mem_ce <= `ChipEnable;
                    case (mem_addr_i[1:0])
                        2'b00: begin
                            mem_strb_o <= 4'b1111;
                            mem_data_o <= reg2_i[31:0];
                        end
                        2'b01: begin
                            mem_strb_o <= 4'b1110;
                            mem_data_o <= {reg2_i[23:0],zero32[7:0]};
                        end
                        2'b10: begin
                            mem_strb_o <= 4'b1100;
                            mem_data_o <= {reg2_i[15:0],zero32[15:0]};
                        end
                        2'b11: begin
                            mem_strb_o <= 4'b1000;
                            mem_data_o <= {reg2_i[7:0],zero32[23:0]};
                        end
                        default: begin
                            mem_strb_o <= 4'b0000;
                        end
                    endcase
                end
                // LL
                `MEM_OP_LL: begin
                    // TODO LL
                end
                // SC
                `MEM_OP_SC: begin
                    // TODO SC
                end
                default: begin
                end
            endcase
        end
    end
    
endmodule
