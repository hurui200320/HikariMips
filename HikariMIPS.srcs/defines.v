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

// ROM地址宽度

// 操作码
`define OP_SPECIAL 6'b000000
`define OP_ORI 6'b001101

// 功能码

// ALU OP
`define ALU_OP_NOP 8'h00000000
`define ALU_OP_OR 8'b00100101

// ALU运算类型
`define ALU_SEL_NOP 3'h000
`define ALU_SEL_LOGIC 3'b001

// NOP时操作的寄存器
`define NOPRegAddr 5'b00000

// 关闭隐式声明，防止变量名拼写错误时自动生成新变量
`default_nettype none
