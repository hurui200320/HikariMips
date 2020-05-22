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
`define True_v 1'b1
`define False_v 1'b0

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
// ͨ�üĴ�������
`define RegNum 32
// ALU���㷽ʽ����
`define AluOpBus 7:0
// ALU�������ʹ���
`define AluSelBus 2:0

// ROM��ַ���

// ������
`define OP_SPECIAL 6'b000000
`define OP_ORI 6'b001101

// ������

// ALU OP
`define ALU_OP_NOP 8'h00000000
`define ALU_OP_OR 8'b00100101

// ALU��������
`define ALU_SEL_NOP 3'h000
`define ALU_SEL_LOGIC 3'b001

// NOPʱ�����ļĴ���
`define NOPRegAddr 5'b00000

// �ر���ʽ��������ֹ������ƴд����ʱ�Զ������±���
`default_nettype none
