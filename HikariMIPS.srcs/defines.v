// 为提高代码可读性
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

// 指令存储器地址带宽
`define InstAddrBus 31:0
// 指令储存器数据带宽
`define InstBus 31:0
// 通用寄存器地址带宽，5位可寻址32个
`define RegAddrBus 4:0
// 通用寄存器地址宽度
`define RegAddrBusWidth 5
// 通用寄存器数据带宽
`define RegBus 31:0
// 通用寄存器个数
`define RegNum 32
// ALU运算方式带宽
`define AluOpBus 7:0
// ALU运算类型带宽
`define AluSelBus 2:0

// 操作码
// 逻辑运算、位移运算
`define OP_SPECIAL 6'b000000
`define OP_ANDI    6'b001100
`define OP_ORI     6'b001101
`define OP_XORI    6'b001110
`define OP_LUI     6'b001111

// 功能码
// 逻辑运算
`define FUNC_AND 6'b100100
`define FUNC_OR  6'b100101
`define FUNC_XOR 6'b100110
`define FUNC_NOR 6'b100111
// 位移运算
`define FUNC_SLL  6'b000000
`define FUNC_SRL  6'b000010
`define FUNC_SRA  6'b000011
`define FUNC_SLLV 6'b000100
`define FUNC_SRLV 6'b000110
`define FUNC_SRAV 6'b000111
// 数据移动
`define FUNC_MFHI 6'b010000
`define FUNC_MTHI 6'b010001
`define FUNC_MFLO 6'b010010
`define FUNC_MTLO 6'b010011

// ALU OP
`define ALU_OP_NOP 8'h00000000
// 逻辑运算
`define ALU_OP_OR  8'b00000001
`define ALU_OP_AND 8'b00000010
`define ALU_OP_XOR 8'b00000011
`define ALU_OP_NOR 8'b00000100
// 位移运算
`define ALU_OP_SLL 8'b00000101
`define ALU_OP_SRL 8'b00000110
`define ALU_OP_SRA 8'b00000111
// 数据移动
`define ALU_OP_MFHI 8'b00010000
`define ALU_OP_MTHI 8'b00010001
`define ALU_OP_MFLO 8'b00010010
`define ALU_OP_MTLO 8'b00010011

// ALU运算类型
`define ALU_SEL_NOP 3'h000
`define ALU_SEL_LOGIC 3'b001
`define ALU_SEL_SHIFT 3'b010
`define ALU_SEL_MOVE 3'b011

// NOP时操作的寄存器
`define NOPRegAddr 5'b00000

// 关闭隐式声明，防止变量名拼写错误时自动生成新变量
`default_nettype none
