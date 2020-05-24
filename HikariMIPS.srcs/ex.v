//////////////////////////////////////////////////////////////////////////////////
// ִ�н׶�
// �ں�ALU����
//////////////////////////////////////////////////////////////////////////////////
`include "defines.v"

module ex(
    input wire clk,
    input wire rst,
    
    //�͵�ִ�н׶ε���Ϣ
    input wire[`AluOpBus] aluop_i,
    input wire[`AluSelBus] alusel_i,
    input wire[`RegBus] reg1_i,
    input wire[`RegBus] reg2_i,
    input wire[`RegAddrBus] waddr_i,
    input wire we_i,

    // hi/LO�Ĵ���
    input wire[`RegBus] hi_i,
    input wire[`RegBus] lo_i,

    // ���Էô����д�ķ�����ͬIDģ����������ص�˼·
    input wire[`RegBus] wb_hi_i,
    input wire[`RegBus] wb_lo_i,
    input wire wb_we_hilo_i,
    
    input wire[`RegBus] mem_hi_i,
    input wire[`RegBus] mem_lo_i,
    input wire mem_we_hilo_i,

    // �͵��ô�׶ε���Ϣ
    output reg[`RegAddrBus] waddr_o,
    output reg we_o,
    output reg[`RegBus] wdata_o,

    output reg we_hilo_o,
    output reg[`RegBus] hi_o,
    output reg[`RegBus] lo_o,

    // ����ģ��
    input wire[`DoubleRegBus] div_result_i,
    input wire div_ready_i,

    output reg[`RegBus] div_opdata1_o,
    output reg[`RegBus] div_opdata2_o,
    output reg div_start_o,
    output reg signed_div_o,

    output reg stallreq // TODO ʵ�ֳ������ۼӳ˷�ʱ
    );

    reg[`RegBus] logic_result;
    reg[`RegBus] shift_result;
    reg[`RegBus] move_result;
    reg[`RegBus] arithmetic_result;
    reg[`DoubleRegBus] mult_result;

    reg stallreq_for_div; // �������ͣ��ˮ��   

    // ����洢�ų�������غ��HI/LO�Ĵ���ֵ
    reg[`RegBus] HI;
    reg[`RegBus] LO;

    // ����߼���·���������ź�����
    // �߼�����
    always @ (*) begin
        if(rst == `RstEnable) begin
            logic_result <= `ZeroWord;
        end else begin
        case (aluop_i)
            `ALU_OP_OR: begin
                logic_result <= reg1_i | reg2_i;
            end
            `ALU_OP_AND: begin
                logic_result <= reg1_i & reg2_i;
            end
            `ALU_OP_NOR: begin
                logic_result <= ~(reg1_i | reg2_i);
            end
            `ALU_OP_XOR: begin
                logic_result <= reg1_i ^ reg2_i;
            end
            default: begin
                logic_result <= `ZeroWord;
            end
        endcase
        end
    end

    // λ������
    always @ (*) begin
        if(rst == `RstEnable) begin
            shift_result <= `ZeroWord;
        end else begin
        case (aluop_i)
            `ALU_OP_SLL: begin
                shift_result <= reg2_i << reg1_i[4:0];
            end
            `ALU_OP_SRL: begin
                shift_result <= reg2_i >> reg1_i[4:0];
            end
            `ALU_OP_SRA: begin
                // �ȸ��ݷ���λ��������Ĳ��֣�������Ϊ�˷����������ƴ��
                shift_result <= ({32{reg2_i[31]}} << (6'd32-{1'b0, reg1_i[4:0]})) | reg2_i >> reg1_i[4:0];
            end
            default: begin
                shift_result <= `ZeroWord;
            end
        endcase
        end
    end

    // �ų�HI/LO�������
    always @ (*) begin
        if(rst == `RstEnable) begin
            {HI,LO} <= {`ZeroWord,`ZeroWord};
        end else if(mem_we_hilo_i == `WriteEnable) begin
            {HI,LO} <= {mem_hi_i,mem_lo_i};
        end else if(wb_we_hilo_i == `WriteEnable) begin
            {HI,LO} <= {wb_hi_i,wb_lo_i};
        end else begin
            {HI,LO} <= {hi_i,lo_i};            
        end
    end

    // �����ƶ���дRegfile���֣�ֻ�漰MFxxָ��
    always @ (*) begin
        if(rst == `RstEnable) begin
            move_result <= `ZeroWord;
        end else begin
            move_result <= `ZeroWord;
            case (aluop_i)
                `ALU_OP_MFHI: begin
                    move_result <= HI;
                end
                `ALU_OP_MFLO: begin
                    move_result <= LO;
                end
                default : begin
                end
            endcase
        end
    end

    // �������㲿��
    // ���ȼ�����ڶ�������������������SLT��С����1��ʱ�൱��+[-y]��
    wire[`RegBus] reg2_i_mux;
    assign reg2_i_mux = ( aluop_i == `ALU_OP_SUB || aluop_i == `ALU_OP_SUBU || aluop_i == `ALU_OP_SLT ) ? ~reg2_i + 1 : reg2_i;
    // ����Ӽ��ͣ�����Ǽӷ�������������ͣ�����Ǽ�����Ƚϣ���������ǲ�
    wire[`RegBus] result_sum;
    assign result_sum = reg1_i + reg2_i_mux;
    // ������������Ϊ����Ϊ����������Ϊ����Ϊ��
    wire sum_overflow;
    assign sum_overflow = (!reg1_i[31] && !reg2_i_mux && result_sum[31]) || ( reg1_i[31] && reg2_i_mux[31] && !result_sum[31]);
    // reg1�Ƿ�С��reg2�����������
    // �з�������reg1 2�ķ��ź�result_sum�ķ��ţ�����һ��һ�����ȻС��
    // �޷�����ֱ�ӱȽ����߷���
    wire reg1_lt_reg2;
    assign reg1_lt_reg2 = (aluop_i == `ALU_OP_SLTU) ? (reg1_i < reg2_i) : ( (reg1_i[31] && !reg2_i[31]) || (!reg1_i[31] && !reg2_i[31] && result_sum[31]) || (reg1_i[31] && reg2_i[31] && result_sum[31]) );
    // ������������
    always @ (*) begin
        if(rst == `RstEnable) begin
            arithmetic_result <= `ZeroWord;
        end else begin
            case (aluop_i)
                `ALU_OP_SLT, `ALU_OP_SLTU: begin
                    arithmetic_result <= reg1_lt_reg2 ;
                end
                `ALU_OP_ADD, `ALU_OP_ADDU: begin
                    arithmetic_result <= result_sum; 
                end
                `ALU_OP_SUB, `ALU_OP_SUBU: begin
                    arithmetic_result <= result_sum; 
                end        
                default: begin
                    arithmetic_result <= `ZeroWord;
                end
            endcase
        end
    end

    // ���������ĳ˷���������������з��ų˷��Ҳ���Ϊ��������
    wire[`RegBus] opdata1_mult;
    assign opdata1_mult = ( aluop_i == `ALU_OP_MULT && reg1_i[31]) ? ~reg1_i + 1 : reg1_i;
    wire[`RegBus] opdata2_mult;
    assign opdata2_mult = ( aluop_i == `ALU_OP_MULT && reg2_i[31]) ? ~reg2_i + 1 : reg2_i;
    // ����˷�
    wire[`DoubleRegBus] hilo_temp;
    assign hilo_temp = opdata1_mult * opdata2_mult;
    // �Խ�������������˷����
    always @ (*) begin
        if(rst == `RstEnable) begin
            mult_result <= {`ZeroWord,`ZeroWord};
        end else if (aluop_i == `ALU_OP_MULT)begin
            // ������з��ų˷�������������һ��һ��
            if(reg1_i[31] ^ reg2_i[31]) begin
                // ���ҲӦ���Ǹ����Խ������
                mult_result <= ~hilo_temp + 1;
            end else begin
                mult_result <= hilo_temp;
            end
        end else begin
                mult_result <= hilo_temp;
        end
    end

    // �������
    always @ (*) begin
        if(rst == `RstEnable) begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;
        end else begin
            stallreq_for_div <= `NoStop;
            div_opdata1_o <= `ZeroWord;
            div_opdata2_o <= `ZeroWord;
            div_start_o <= `DivStop;
            signed_div_o <= 1'b0;     
            case (aluop_i) 
                `ALU_OP_DIV: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b1;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                         
                end
                `ALU_OP_DIVU: begin
                    if(div_ready_i == `DivResultNotReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStart;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `Stop;
                    end else if(div_ready_i == `DivResultReady) begin
                        div_opdata1_o <= reg1_i;
                        div_opdata2_o <= reg2_i;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end else begin
                        div_opdata1_o <= `ZeroWord;
                        div_opdata2_o <= `ZeroWord;
                        div_start_o <= `DivStop;
                        signed_div_o <= 1'b0;
                        stallreq_for_div <= `NoStop;
                    end                         
                end
                default: begin
                end
            endcase
        end
    end

    // ������ͣ����
    always @ (*) begin
        // �����ܵ���ͣ����֮��
        stallreq = stallreq_for_div;
    end

    // �����ƶ���дHI/LO���֣�ֻ�漰MTxxָ��
    // ͬʱ����д��˳������
    always @ (*) begin
        if(rst == `RstEnable) begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end else if(aluop_i == `ALU_OP_MULT || aluop_i == `ALU_OP_MULTU) begin
            // �ǳ˷������д��
            we_hilo_o = `WriteEnable;
            hi_o <= mult_result[63:32];
            lo_o <= mult_result[31:0];
        end else if (aluop_i == `ALU_OP_DIV || aluop_i == `ALU_OP_DIVU) begin
            // ����
            we_hilo_o <= `WriteEnable;
            hi_o <= div_result_i[63:32];
            lo_o <= div_result_i[31:0];
        end else if(aluop_i == `ALU_OP_MTHI) begin
            we_hilo_o <= `WriteEnable;
            hi_o <= reg1_i;
            lo_o <= LO;
        end else if(aluop_i == `ALU_OP_MTLO) begin
            we_hilo_o <= `WriteEnable;
            hi_o <= HI;
            lo_o <= reg1_i;
        end else begin
            we_hilo_o <= `WriteDisable;
            hi_o <= `ZeroWord;
            lo_o <= `ZeroWord;
        end                
    end

    // ������������ѡ��һ��������
    always @ (*) begin
        // ����д����ź�
        waddr_o <= waddr_i;
        // ���з�����������������ο�MIPSָ��ֲᣩ
        if((aluop_i == `ALU_OP_ADD || aluop_i == `ALU_OP_SUB) && sum_overflow) begin
            // ��������ֹд + ��������/�쳣
            we_o <= `WriteDisable;
        end else begin
            we_o <= we_i;
        end
        case (alusel_i) 
            `ALU_SEL_LOGIC: begin
                wdata_o <= logic_result;
            end
            `ALU_SEL_SHIFT: begin
                wdata_o <= shift_result;
            end   
            `ALU_SEL_MOVE: begin
                wdata_o <= move_result;
            end   
            `ALU_SEL_ARITHMETIC: begin
                wdata_o <= arithmetic_result;
            end   
            default: begin
                wdata_o <= `ZeroWord;
            end
        endcase
    end
endmodule
