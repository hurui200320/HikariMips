//////////////////////////////////////////////////////////////////////////////////
// ����ģ��
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module id(
    input wire clk,
    input wire rst,

    // Լ��_i��β�ı���������
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,
    
    // ��regfile�Ŀ����ź�
    output reg re1_o,
    output reg[`RegAddrBus] raddr1_o,
    input wire[`RegBus] rdata1_i,

    output reg re2_o,
    output reg[`RegAddrBus] raddr2_o,
    input wire[`RegBus] rdata2_i,

    //����ִ�н׶εķ����������������ָ���д���
    input wire ex_we_i,
    input wire[`RegBus] ex_wdata_i,
    input wire[`RegAddrBus] ex_waddr_i,

    //���Էô�׶εķ�����������һ��ָ���д���
    input wire mem_we_i,
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_waddr_i,

    // ִ�н׶������ź�
    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] reg1_data_o,
    output reg[`RegBus] reg2_data_o,
    // д�Ĵ����׶���Ҫ��ִ����Ϻ�д�ؽ׶���ɣ�����ǰ�׶�Ӧ����дĿ�����Ϣ
    output reg we_o,
    output reg[`RegAddrBus] waddr_o,

    output reg stallreq
    );

    // opcode
    wire[5:0] opcode = inst_i[31:26];
    // R��I
    wire[4:0] rs = inst_i[25:21];
    wire[4:0] rt = inst_i[20:16];
    // R
    wire[4:0] rd = inst_i[15:11];
    wire[4:0] sa = inst_i[10:6];
    wire[5:0] func = inst_i[5:0];
    // �з�����չ������
    wire[`RegBus] signed_imm = {{16{inst_i[15]}}, inst_i[15:0]};
    wire[`RegBus] unsigned_imm = {16'h0, inst_i[15:0]};
    // ������Ҫ������������Ϊ�м�����������������֮������
    reg[`RegBus] imm;
    // ָ���α��־λ
    reg inst_valid;
  
    // �������������У���Ϊ����������߼���·
    // ���벢��ȡ������������regfile�����źţ�
    always @ (*) begin    
        if (rst == `RstEnable) begin
            // ��λ
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
            // Ĭ�ϲ���Ҫ��ͣ��ˮ��
            stallreq <= `NoStop;// TODO
            imm <= `ZeroWord;
            // ����OPCODE����
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
                            // �˳�����д��RegFile����˺���EX��Ӧ�����wdata
                            // �����ﱣ��ALU_SEL Ϊ NOP�Խ������
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

                default: begin
                end
            // END FOR CASE OPCODE
            endcase
        end
    end
    
    // �����һ��������
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg1_data_o <= `ZeroWord;
        end else if(re1_o == `ReadEnable && ex_we_i == `WriteEnable && ex_waddr_i == raddr1_o) begin
            // �˿�1���������������ִ�н׶Σ��ȷô�׶��£������Ľ�д�������
            reg1_data_o <= ex_wdata_i;
        end else if(re1_o == `ReadEnable && mem_we_i == `WriteEnable && mem_waddr_i == raddr1_o) begin
            // �˿�1��������������Ƿô�׶Σ��ȼĴ������£������Ľ�д������
            reg1_data_o <= mem_wdata_i;
        end else if(re1_o == `ReadEnable) begin
            // ���˿�1
            reg1_data_o <= rdata1_i;
        end else if(re1_o == `ReadDisable) begin
            // ����˿�1����Ҫ�������ø�������
            // Ŀǰ��˵�˿�1������ζ���Ҫ���ģ�rs��
            // ����дֻ��Ϊ����˿�2�ȽϹ���
            reg1_data_o <= imm;
        end else begin
            // һ�㲻�������������������걸��if..else if..else����ۺϺ����Ч
            reg1_data_o <= `ZeroWord;
        end
    end

    // ͬ�ϣ�����ڶ������������ڶ���������������Դ��������
    always @ (*) begin
        if(rst == `RstEnable) begin
            reg2_data_o <= `ZeroWord;
        end else if(re2_o == `ReadEnable && ex_we_i == `WriteEnable && ex_waddr_i == raddr2_o) begin
            // �˿�2���������������ִ�н׶Σ��ȷô�׶��£������Ľ�д�������
            reg2_data_o <= ex_wdata_i;
        end else if(re2_o == `ReadEnable && mem_we_i == `WriteEnable && mem_waddr_i == raddr2_o) begin
            // �˿�2��������������Ƿô�׶Σ��ȼĴ������£������Ľ�д������
            reg2_data_o <= mem_wdata_i;
        end else if(re2_o == `ReadEnable) begin
            // ���˿�2
            reg2_data_o <= rdata2_i;
        end else if(re2_o == `ReadDisable) begin
            // ����˿�2����Ҫ�������ø�������
            reg2_data_o <= imm;
        end else begin
            // һ�㲻�������������������걸��if..else if..else����ۺϺ����Ч
            reg2_data_o <= `ZeroWord;
        end
    end

endmodule
