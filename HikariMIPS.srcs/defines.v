// Ϊ��ߴ���ɶ���
`define RstEnable 1'b1
`define RstDisable 1'b0
`define ZeroWord 32'h00000000
`define WriteEnable 1'b1
`define WriteDisable 1'b0
`define ReadEnable 1'b1
`define ReadDisable 1'b0
`define ChipEnable 1'b1
`define ChipDisable 1'b0
`define InstValid 1'b0
`define InstInvalid 1'b1
`define Stop 1'b1
`define NoStop 1'b0
`define True_v 1'b1
`define False_v 1'b0
// ���������
`define DivFree 2'b00
`define DivByZero 2'b01
`define DivOn 2'b10
`define DivEnd 2'b11
`define DivResultReady 1'b1
`define DivResultNotReady 1'b0
`define DivStart 1'b1
`define DivStop 1'b0

// ָ��洢����ַ����
`define InstAddrBus 31:0
// ָ��������ݴ���
`define InstBus 31:0
// ͨ�üĴ�����ַ����5λ��Ѱַ32��
`define RegAddrBus 4:0
// ͨ�üĴ�����ַ���
`define RegAddrBusWidth 5
// ͨ�üĴ������ݴ���
`define RegBus 31:0
// ˫���������ڱ���˷����
`define DoubleRegBus 63:0
// ͨ�üĴ�������
`define RegNum 32
// ALU���㷽ʽ����
`define AluOpBus 7:0
// ALU�������ʹ���
`define AluSelBus 2:0

// ������
// �߼����㡢λ������
`define OP_SPECIAL 6'b000000
`define OP_ANDI    6'b001100
`define OP_ORI     6'b001101
`define OP_XORI    6'b001110
`define OP_LUI     6'b001111
// ��������������
`define OP_ADDI  6'b001000
`define OP_ADDIU 6'b001001
`define OP_SLTI  6'b001010
`define OP_SLTIU 6'b001011

// ������
// �߼�����
`define FUNC_AND 6'b100100
`define FUNC_OR  6'b100101
`define FUNC_XOR 6'b100110
`define FUNC_NOR 6'b100111
// λ������
`define FUNC_SLL  6'b000000
`define FUNC_SRL  6'b000010
`define FUNC_SRA  6'b000011
`define FUNC_SLLV 6'b000100
`define FUNC_SRLV 6'b000110
`define FUNC_SRAV 6'b000111
// �����ƶ�
`define FUNC_MFHI 6'b010000
`define FUNC_MTHI 6'b010001
`define FUNC_MFLO 6'b010010
`define FUNC_MTLO 6'b010011
// ��������������
// TODO �����Ƶ�ϲ�ȥ�����Կ��ǲ�˷�
`define FUNC_ADD   6'b100000
`define FUNC_ADDU  6'b100001
`define FUNC_SUB   6'b100010
`define FUNC_SUBU  6'b100011
`define FUNC_SLT   6'b101010
`define FUNC_SLTU  6'b101011
`define FUNC_MULT  6'b011000
`define FUNC_MULTU 6'b011001
// �����ڳ�������
`define FUNC_DIV   6'b011010
`define FUNC_DIVU  6'b011011

// ALU OP
`define ALU_OP_NOP 8'h00000000
// �߼�����
`define ALU_OP_OR  8'b00000001
`define ALU_OP_AND 8'b00000010
`define ALU_OP_XOR 8'b00000011
`define ALU_OP_NOR 8'b00000100
// λ������
`define ALU_OP_SLL 8'b00000101
`define ALU_OP_SRL 8'b00000110
`define ALU_OP_SRA 8'b00000111
// �����ƶ�
`define ALU_OP_MFHI 8'b00001000
`define ALU_OP_MTHI 8'b00001001
`define ALU_OP_MFLO 8'b00001010
`define ALU_OP_MTLO 8'b00001011
// ��������������
`define ALU_OP_ADD   8'b00001100
`define ALU_OP_ADDU  8'b00001101
`define ALU_OP_SUB   8'b00001110
`define ALU_OP_SUBU  8'b00001111
`define ALU_OP_SLT   8'b00010000
`define ALU_OP_SLTU  8'b00010001
`define ALU_OP_MULT  8'b00010010
`define ALU_OP_MULTU 8'b00010011
// �����ڳ�������
`define ALU_OP_DIV   8'b00011010
`define ALU_OP_DIVU  8'b00011011

// ALU��������
`define ALU_SEL_NOP 3'h000
`define ALU_SEL_LOGIC 3'b001
`define ALU_SEL_SHIFT 3'b010
`define ALU_SEL_MOVE 3'b011
`define ALU_SEL_ARITHMETIC 3'b100

// NOPʱ�����ļĴ���
`define NOPRegAddr 5'b00000

// �ر���ʽ��������ֹ������ƴд����ʱ�Զ������±���
`default_nettype none
