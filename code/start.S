	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
	ori $1, $0, 4
	movz $2, $1, $0 # $2 = 4
	movz $3, $1, $1 # $3 = 0
	movn $4, $1, $0 # $4 = 0
	movn $5, $1, $1 # $5 = 4