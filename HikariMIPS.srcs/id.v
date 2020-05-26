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
    
    // 传递指令给EX，便于EX计算访存指令的地址
    output wire[`InstBus] inst_o,

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

    // ID/EX反馈指示当前指令是否在延迟槽内
    input wire is_in_delayslot_i,
    // 标识下一条指令是否在延迟槽内
    output reg next_inst_in_delayslot_o,
    // 产生的分支跳转信号
    output reg branch_flag_o,
    // 跳转的绝对地址
    output reg[`RegBus] branch_target_address_o,       
    // 要保存的返回地址
    output reg[`RegBus] link_addr_o,
    // 告诉EX当前指令是否在延迟槽内
    output reg is_in_delayslot_o,

    // 执行阶段所需信号
    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] reg1_data_o,
    output reg[`RegBus] reg2_data_o,
    // 写寄存器阶段需要在执行完毕后写回阶段完成，但当前阶段应产生写目标的信息
    output reg we_o,
    output reg[`RegAddrBus] waddr_o,

    output reg stallreq
    );

    // 中继指令，EX通过指令计算出内存地址
    assign inst_o = inst_i;

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
    // 指令有效标志位
    reg inst_valid;

    // 计算分支跳转相关的数据
    // PC下一条指令和下两条指令的地址，后者用于保存返回地址
    wire[`RegBus] pc_next;
    wire[`RegBus] pc_next_2;
    assign pc_next = pc_i + 4;
    assign pc_next_2 = pc_i + 8;
    // 用于地址的立即数，左移两位并有符号扩展到32位
    wire[`RegBus] addr_offset_imm;
    assign addr_offset_imm = {{14{inst_i[15]}}, inst_i[15:0], 2'b00};
    wire[`RegBus] b_addr_imm;
    assign b_addr_imm = {pc_next[31:28], inst_i[25:0], 2'b00};

  
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
            stallreq <= `NoStop;// TODO
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
        end else begin
            aluop_o <= `ALU_OP_NOP;
            alusel_o <= `ALU_SEL_NOP;
            we_o <= `WriteDisable;
            waddr_o <= rd;
            inst_valid <= `InstInvalid;
            re1_o <= `ReadDisable;
            re2_o <= `ReadDisable;
            raddr1_o <= rs;
            raddr2_o <= rt;
            // 默认不需要暂停流水线
            stallreq <= `NoStop;
            imm <= `ZeroWord;
            link_addr_o <= `ZeroWord;
            branch_target_address_o <= `ZeroWord;
            branch_flag_o <= `NotBranch;
            next_inst_in_delayslot_o <= `NotInDelaySlot;
            // 根据OPCODE译码
            case (opcode)
                `OP_SPECIAL: begin
                    if (sa == 5'b00000) begin
                        case (func)
                            // OR
                            `FUNC_OR: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_OR;
                                alusel_o <= `ALU_SEL_LOGIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end  
                            // AND
                            `FUNC_AND: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_AND;
                                alusel_o <= `ALU_SEL_LOGIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end  
                            // XOR
                            `FUNC_XOR: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_XOR;
                                alusel_o <= `ALU_SEL_LOGIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end    
                            // NOR
                            `FUNC_NOR: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_NOR;
                                alusel_o <= `ALU_SEL_LOGIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end 
                            // SLLV
                            `FUNC_SLLV: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SLL;
                                alusel_o <= `ALU_SEL_SHIFT;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end 
                            // SRLV
                            `FUNC_SRLV: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SRL;
                                alusel_o <= `ALU_SEL_SHIFT;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end    
                            // SRAV                 
                            `FUNC_SRAV: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SRA;
                                alusel_o <= `ALU_SEL_SHIFT;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end    
                            // MFHI               
                            `FUNC_MFHI: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_MFHI;
                                alusel_o <= `ALU_SEL_MOVE;
                                re1_o <= `ReadDisable;
                                re2_o <= `ReadDisable;
                                inst_valid <= `InstValid;
                            end
                            // MTHI
                            `FUNC_MTHI: begin
                                we_o <= `WriteDisable;
                                aluop_o <= `ALU_OP_MTHI;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadDisable;
                                inst_valid <= `InstValid;
                            end
                            // MFLO
                            `FUNC_MFLO: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_MFLO;
                                alusel_o <= `ALU_SEL_MOVE;
                                re1_o <= `ReadDisable;
                                re2_o <= `ReadDisable;
                                inst_valid <= `InstValid;
                            end
                            // MTLO
                            `FUNC_MTLO: begin
                                we_o <= `WriteDisable;
                                aluop_o <= `ALU_OP_MTLO;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadDisable;
                                inst_valid <= `InstValid;
                            end
                            // ADD
                            `FUNC_ADD: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_ADD;
                                alusel_o <= `ALU_SEL_ARITHMETIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // ADDU
                            `FUNC_ADDU: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_ADDU;
                                alusel_o <= `ALU_SEL_ARITHMETIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // SUB
                            `FUNC_SUB: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SUB;
                                alusel_o <= `ALU_SEL_ARITHMETIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // SUBU
                            `FUNC_SUBU: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SUBU;
                                alusel_o <= `ALU_SEL_ARITHMETIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // SLT
                            `FUNC_SLT: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SLT;
                                alusel_o <= `ALU_SEL_ARITHMETIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // SLTU
                            `FUNC_SLTU: begin
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SLTU;
                                alusel_o <= `ALU_SEL_ARITHMETIC;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // MULT
                            // 乘除法不写入RegFile，因此后面EX不应当输出wdata
                            // 故这里保持ALU_SEL 为 NOP以禁用输出
                            `FUNC_MULT: begin
                                we_o <= `WriteDisable;
                                aluop_o <= `ALU_OP_MULT;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // MULTU
                            `FUNC_MULTU: begin
                                we_o <= `WriteDisable;
                                aluop_o <= `ALU_OP_MULTU;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // DIV
                            `FUNC_DIV: begin
                                we_o <= `WriteDisable;
                                aluop_o <= `ALU_OP_DIV;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // DIVU
                            `FUNC_DIVU: begin
                                we_o <= `WriteDisable;
                                aluop_o <= `ALU_OP_DIVU;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadEnable;
                                inst_valid <= `InstValid;
                            end
                            // JR
                            `FUNC_JR: begin
                                we_o <= `WriteDisable;
                                alusel_o <= `ALU_SEL_JUMP_BRANCH;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadDisable;
                                link_addr_o <= `ZeroWord;
                                branch_target_address_o <= reg1_data_o;
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                inst_valid <= `InstValid;
                            end
                            // JALR
                            `FUNC_JALR: begin
                                we_o <= `WriteEnable;
                                alusel_o <= `ALU_SEL_JUMP_BRANCH;
                                re1_o <= `ReadEnable;
                                re2_o <= `ReadDisable;
                                link_addr_o <= pc_next_2;
                                branch_target_address_o <= reg1_data_o;
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                                inst_valid <= `InstValid;
                            end
                            default: begin
                            end
                        // END FOR CASE func code
                        endcase
                    // END FOR SA 000000
                    end else if (rs == 5'h00000) begin 
                        case (func)
                            // SLL
                            `FUNC_SLL: begin
                                waddr_o <= rd;
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SLL;
                                alusel_o <= `ALU_SEL_SHIFT;
                                re1_o <= `ReadDisable;
                                re2_o <= `ReadEnable;
                                imm[4:0] <= sa;
                                inst_valid <= `InstValid;
                            end  
                            // SRL
                            `FUNC_SRL: begin
                                waddr_o <= rd;
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SRL;
                                alusel_o <= `ALU_SEL_SHIFT;
                                re1_o <= `ReadDisable;
                                re2_o <= `ReadEnable;
                                imm[4:0] <= sa;
                                inst_valid <= `InstValid;
                            end   
                            // SRA
                            `FUNC_SRA: begin
                                waddr_o <= rd;
                                we_o <= `WriteEnable;
                                aluop_o <= `ALU_OP_SRA;
                                alusel_o <= `ALU_SEL_SHIFT;
                                re1_o <= `ReadDisable;
                                re2_o <= `ReadEnable;
                                imm[4:0] <= sa;
                                inst_valid <= `InstValid;
                            end                                                                       
                            default: begin
                            end
                        // END FOR CASE func code
                        endcase
                    // END FOR rs 000000
                    end else begin
                    end
                end // END FOR OPCODE SPECIAL
                `OP_REGIMM: begin
                    case(rt)
                        // BLTZ
                        `RT_BLTZ: begin
                            we_o <= `WriteDisable;
                            alusel_o <= `ALU_SEL_JUMP_BRANCH;
                            re1_o <= `ReadEnable;
                            re2_o <= `ReadDisable;
                            inst_valid <= `InstValid;
                            if(reg1_data_o[31]) begin
                                branch_target_address_o <= pc_next + addr_offset_imm;
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;  
                           end
                        end
                        // BGEZ
                        `RT_BGEZ: begin
                            we_o <= `WriteDisable;
                            alusel_o <= `ALU_SEL_JUMP_BRANCH;
                            re1_o <= `ReadEnable;
                            re2_o <= `ReadDisable;
                            inst_valid <= `InstValid;
                            if(!reg1_data_o[31]) begin
                                branch_target_address_o <= pc_next + addr_offset_imm;
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;  
                            end
                        end
                        // BLTZAL
                        `RT_BLTZAL: begin    
                            waddr_o <= 5'b11111;
                            we_o <= `WriteEnable;
                            alusel_o <= `ALU_SEL_JUMP_BRANCH;
                            re1_o <= `ReadEnable;
                            re2_o <= `ReadDisable;
                            link_addr_o <= pc_next_2;
                            inst_valid <= `InstValid;
                            if(reg1_data_o[31]) begin
                                branch_target_address_o <= pc_next + addr_offset_imm;
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        end
                        // BGEZAL
                        `RT_BGEZAL: begin 
                            waddr_o <= 5'b11111;
                            we_o <= `WriteEnable;
                            alusel_o <= `ALU_SEL_JUMP_BRANCH;
                            re1_o <= `ReadEnable;
                            re2_o <= `ReadDisable;
                            link_addr_o <= pc_next_2;
                            inst_valid <= `InstValid;
                            if(!reg1_data_o[31]) begin
                                branch_target_address_o <= pc_next + addr_offset_imm;
                                branch_flag_o <= `Branch;
                                next_inst_in_delayslot_o <= `InDelaySlot;
                            end
                        end
                        default: begin
                        end
                    // END FOR CASE rt
                    endcase
                end // END FOR OPCODE REGIMM
                // ORI
                `OP_ORI: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_OR;
                    alusel_o <= `ALU_SEL_LOGIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= unsigned_imm;
                    inst_valid <= `InstValid;
                end
                // ANDI
                `OP_ANDI: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_AND;
                    alusel_o <= `ALU_SEL_LOGIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= unsigned_imm;
                    inst_valid <= `InstValid;
                end
                // XORI
                `OP_XORI: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_XOR;
                    alusel_o <= `ALU_SEL_LOGIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= unsigned_imm;
                    inst_valid <= `InstValid;
                end
                // LUI
                `OP_LUI: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_OR;
                    alusel_o <= `ALU_SEL_LOGIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= {inst_i[15:0], 16'h0};
                    inst_valid <= `InstValid;
                end
                // ADDI
                `OP_ADDI: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_ADD;
                    alusel_o <= `ALU_SEL_ARITHMETIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= signed_imm;
                    inst_valid <= `InstValid;
                end
                // ADDIU
                `OP_ADDIU: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_ADDU;
                    alusel_o <= `ALU_SEL_ARITHMETIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= signed_imm;
                    inst_valid <= `InstValid;
                end
                // SLTI
                `OP_SLTI: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_SLT;
                    alusel_o <= `ALU_SEL_ARITHMETIC;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= signed_imm;
                    inst_valid <= `InstValid;
                end
                // SLTIU
                `OP_SLTIU: begin
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `ALU_OP_SLTU;
                    alusel_o <= `ALU_SEL_ARITHMETIC;re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    imm <= signed_imm;
                    inst_valid <= `InstValid;
                end
                // J
                `OP_J: begin
                    we_o <= `WriteDisable;
                    alusel_o <= `ALU_SEL_JUMP_BRANCH;
                    re1_o <= `ReadDisable;
                    re2_o <= `ReadDisable;
                    link_addr_o <= `ZeroWord;
                    branch_target_address_o <= b_addr_imm;
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;  
                    inst_valid <= `InstValid;
                end
                // JAL
                `OP_JAL: begin
                    // 固定写入$31作为返回地址  
                    waddr_o <= 5'b11111;
                    we_o <= `WriteEnable;
                    alusel_o <= `ALU_SEL_JUMP_BRANCH;
                    re1_o <= `ReadDisable;
                    re2_o <= `ReadDisable;
                    link_addr_o <= pc_next_2 ;
                    branch_target_address_o <= b_addr_imm;
                    branch_flag_o <= `Branch;
                    next_inst_in_delayslot_o <= `InDelaySlot;  
                    inst_valid <= `InstValid;
                end
                // BEQ
                `OP_BEQ: begin
                    we_o <= `WriteDisable;
                    alusel_o <= `ALU_SEL_JUMP_BRANCH;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable;
                    inst_valid <= `InstValid;
                    if(reg1_data_o == reg2_data_o) begin
                        branch_target_address_o <= pc_next + addr_offset_imm;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;  
                    end
                end
                // BNE
                `OP_BNE: begin
                    we_o <= `WriteDisable;
                    alusel_o <= `ALU_SEL_JUMP_BRANCH;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable;
                    inst_valid <= `InstValid;
                    if(reg1_data_o != reg2_data_o) begin
                        branch_target_address_o <= pc_next + addr_offset_imm;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;  
                    end
                end
                // BGTZ
                `OP_BGTZ: begin
                    we_o <= `WriteDisable;
                    alusel_o <= `ALU_SEL_JUMP_BRANCH;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    inst_valid <= `InstValid;
                    if(!reg1_data_o[31] && reg1_data_o != `ZeroWord) begin
                        branch_target_address_o <= pc_next + addr_offset_imm;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;  
                    end
                end
                // BLEZ
                `OP_BLEZ: begin
                    we_o <= `WriteDisable;
                    alusel_o <= `ALU_SEL_JUMP_BRANCH;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    inst_valid <= `InstValid;
                    if(reg1_data_o[31] || reg1_data_o == `ZeroWord) begin
                        branch_target_address_o <= pc_next + addr_offset_imm;
                        branch_flag_o <= `Branch;
                        next_inst_in_delayslot_o <= `InDelaySlot;  
                    end
                end
                // LB
                `OP_LB: begin         
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LB;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable; // base
                    re2_o <= `ReadDisable; 
                    inst_valid <= `InstValid;    
                end
                // LH
                `OP_LH: begin         
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LH;
                    alusel_o <= `ALU_SEL_LOAD_STORE;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;  
                    inst_valid <= `InstValid;    
                end
                // LWL
                `OP_LWL: begin         
                    waddr_o <= rt;
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LWL;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable; 
                    inst_valid <= `InstValid;    
                end
                // LW
                `OP_LW: begin          
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LW;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    inst_valid <= `InstValid;    
                end
                // LBU
                `OP_LBU: begin        
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LBU;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;  
                    inst_valid <= `InstValid;    
                end
                // LHU
                `OP_LHU: begin        
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LHU;
                    alusel_o <= `ALU_SEL_LOAD_STORE;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;  
                    inst_valid <= `InstValid;    
                end
                // LWR
                `OP_LWR: begin
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LWR;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable;          
                    inst_valid <= `InstValid;    
                end
                // SB
                `OP_SB: begin
                    we_o <= `WriteDisable;
                    aluop_o <= `MEM_OP_SB;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable;
                    inst_valid <= `InstValid;    
                end
                // SH
                `OP_SH: begin
                    we_o <= `WriteDisable;
                    aluop_o <= `MEM_OP_SH;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable; 
                    inst_valid <= `InstValid;    
                end
                // SWL
                `OP_SWL: begin
                    we_o <= `WriteDisable;
                    aluop_o <= `MEM_OP_SWL;
                    alusel_o <= `ALU_SEL_LOAD_STORE;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable; 
                    inst_valid <= `InstValid;     
                end
                // SWR
                `OP_SWR: begin
                    we_o <= `WriteDisable;
                    aluop_o <= `MEM_OP_SWR;
                    alusel_o <= `ALU_SEL_LOAD_STORE;
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable; 
                    inst_valid <= `InstValid;     
                end
                // SW
                `OP_SW: begin
                    we_o <= `WriteDisable;
                    aluop_o <= `MEM_OP_SW;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable;
                    inst_valid <= `InstValid;    
                end
                // LL
                `OP_LL: begin          
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_LL;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadDisable;
                    inst_valid <= `InstValid;    
                end
                // SC
                `OP_SC: begin         
                    waddr_o <= rt; 
                    we_o <= `WriteEnable;
                    aluop_o <= `MEM_OP_SC;
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    alusel_o <= `ALU_SEL_LOAD_STORE; 
                    re1_o <= `ReadEnable;
                    re2_o <= `ReadEnable; 
                    inst_valid <= `InstValid;    
                end
                default: begin
                end
            // END FOR CASE OPCODE
            endcase
        end
    end

    // 处理延迟槽信号
    always @ (*) begin
        if(rst == `RstEnable) begin
            is_in_delayslot_o <= `NotInDelaySlot;
        end else begin
            is_in_delayslot_o <= is_in_delayslot_i;
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
            reg2_data_o <= rdata2_i;
        end else if(re2_o == `ReadDisable) begin
            // 如果端口2不需要读，就用给立即数
            reg2_data_o <= imm;
        end else begin
            // 一般不会出现这种情况，但是完备的if..else if..else语句综合后更高效
            reg2_data_o <= `ZeroWord;
        end
    end

endmodule
