	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
	ori $1, $0, 0x0001
	ori $2, $0, 0xFFFF
	beql $0, $1, _loop # 这里不应该跳，且下面的除法指令不应该被执行
	div $0, $2, $1 # 0xFFFF / 0x0001
	j _start
	nop
	
_loop:
	j _loop
	nop