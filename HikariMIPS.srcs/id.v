//////////////////////////////////////////////////////////////////////////////////
// 译码模块
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module id(
    input wire clk,
    input wire rst,

    // 约定_i结尾的变量是输入
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,
    
    // 读regfile的控制信号
    output reg re1_o,
    output reg[`RegAddrBus] raddr1_o,
    input wire[`RegBus] rdata1_i,

    output reg re2_o,
    output reg[`RegAddrBus] raddr2_o,
    input wire[`RegBus] rdata2_i,

    //来自执行阶段的反馈，解决相邻两条指令的写后读
    input wire ex_we_i,
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_waddr_i,

    //来自访存阶段的反馈，解决相隔一条指令的写后读
    input wire mem_we_i,
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_waddr_i,

    // 执行阶段所需信号
    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] reg1_data_o,
    output reg[`RegBus] reg2_data_o,
    // 写寄存器阶段需要在执行完毕后写回阶段完成，但当前阶段应产生写目标的信息
    output reg we_o,
    output reg[`RegAddrBus] waddr_o
    );

    // opcode
    wire[5:0] opcode = inst_i[31:26];
    // R、I
    wire[4:0] rs = inst_i[25:21];
    wire[4:0] rt = inst_i[20:16];
    // R
    wire[4:0] rd = inst_i[15:11];
    wire[4:0] sa = inst_i[10:6];
    wire[5:0] func = inst_i[5:0];
    // 有符号扩展立即数
    wire[`RegBus] signed_imm = {{16{inst_i[15]}}, inst_i[15:0]};
    wire[`RegBus] unsigned_imm = {16'h0, inst_i[15:0]};
    // 最终需要的立即数，作为中间变量用于译码与输出之间解耦合
    reg[`RegBus] imm;
    // 指令游标标志位
    reg inst_valid;
  
    // 对所有输入敏感，因为译码是组合逻辑电路
    // 译码并获取操作数（产生regfile控制信号）
    always @ (*) begin    
        if (rst == `RstEnable) begin
            // 复位
            aluop_o <= `ALU_OP_NOP;
            alusel_o <= `ALU_SEL_NOP;
            waddr_o <= `NOPRegAddr;
            we_o <= `WriteDisable;
            inst_valid <= `InstValid;
            re1_o <= `ReadDisable;
            re2_o <= `ReadDisable;
            raddr1_o <= `NOPRegAddr;
            raddr2_o <= `NOPRegAddr;
        end else begin
            aluop_o <= `ALU_OP_NOP;
            alusel_o <= `ALU_SEL_NOP;
            we_o <= `WriteDisable;
            inst_valid <= `InstInvalid;       
            re1_o <= `ReadDisable;
            re2_o <= `ReadDisable;
            raddr1_o <= rs;
            raddr2_o <= rt;        
            imm <= `ZeroWord;
            // 根据OPCODE译码
            case (opcode)
                `OP_ORI: begin
                    // ORI
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_OR;
                    alusel_o <= `ALU_SEL_LOGIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;          
                    imm <= unsigned_imm;        
                    inst_valid <= `InstValid;    
                end
                default: begin
                    // 默认，没什么可做的
                end
            endcase
        end
    end
    
    // 处理第一个操作数
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg1_data_o <= `ZeroWord;
        end else if(re1_o == `ReadEnable && ex_we_i == `WriteEnable && ex_waddr_i == raddr1_o) begin
            // 端口1请求的数据正好是执行阶段（比访存阶段新）产生的将写入的数据
            reg1_data_o <= ex_wdata_i; 
        end else if(re1_o == `ReadEnable && mem_we_i == `WriteEnable && mem_waddr_i == raddr1_o) begin
            // 端口1请求的数据正好是访存阶段（比寄存器堆新）产生的将写入数据
            reg1_data_o <= mem_wdata_i;  
        end else if(re1_o == `ReadEnable) begin
            // 读端口1
            reg1_data_o <= rdata1_i;
        end else if(re1_o == `ReadDisable) begin
            // 如果端口1不需要读，就用给立即数
            // 目前来说端口1无论如何都是要读的（rs）
            // 这样写只是为了与端口2比较规整
            reg1_data_o <= imm;
        end else begin
            // 一般不会出现这种情况，但是完备的if..else if..else语句综合后更高效
            reg1_data_o <= `ZeroWord;
        end
    end

    // 同上，处理第二个操作数，第二个操作数可能来源于立即数
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg2_data_o <= `ZeroWord;
        end else if(re2_o == `ReadEnable && ex_we_i == `WriteEnable && ex_waddr_i == raddr2_o) begin
            // 端口2请求的数据正好是执行阶段（比访存阶段新）产生的将写入的数据
            reg2_data_o <= ex_wdata_i; 
        end else if(re2_o == `ReadEnable && mem_we_i == `WriteEnable && mem_waddr_i == raddr2_o) begin
            // 端口2请求的数据正好是访存阶段（比寄存器堆新）产生的将写入数据
            reg2_data_o <= mem_wdata_i;  
        end else if(re2_o == `ReadEnable) begin
            // 读端口2
            reg2_data_o <= rdata1_i;
        end else if(re2_o == `ReadDisable) begin
            // 如果端口2不需要读，就用给立即数
            reg2_data_o <= imm;
        end else begin
            // 一般不会出现这种情况，但是完备的if..else if..else语句综合后更高效
            reg2_data_o <= `ZeroWord;
        end
    end

endmodule
