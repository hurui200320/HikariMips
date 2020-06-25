	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
	ori $1, $0, 4
	ori $2, $0, 5
	mul $3, $1, $2