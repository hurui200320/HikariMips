	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
    ori $1,$0,0x100     # $1 = 0x100
    jr $1
    nop
    
    .org 0x40 # 异常处理
	mfc0 $4, $14, 0x00
	addi $4, $4, 0x04
	mtc0 $4, $14, 0x00
    mult $2, $3
    eret
    nop
    
    .org 0x100
    ori $2,$0,200
    ori $1,$0,100
    ori $3,$0,400
    syscall # 测试乘法取消
	mult $1, $2
_loop:
	j _loop
	nop