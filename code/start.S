	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
	ori $1, $0, 0x0001
	clz $2, $1 # $2 = 31
	ori $1, $0, 0xFFFD
	sll $1, $1, 16
	clo $2, $1 # $2 = 30