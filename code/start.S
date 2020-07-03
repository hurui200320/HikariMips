	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
	# 测试HILO在WB的数据相关
	ori $1, $0, 0xFF
	mthi $1
	nop
	mfhi $2
	# 测试CP0
	ori $1, $0, 0xf
	mtc0 $1, $11, 0x0 # 写入Compare寄存器
	
	lui $1, 0x1000
	ori $1, $1, 0x401 # $1 = 0x10000401
	mtc0 $1, $12, 0x0 # 写入Status寄存器
	mfc0 $2, $12, 0x0 # $2 = 0x10000401
	
_loop:
	j _loop
	nop