	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
    ori  $1,$0,0xeef0
    ori  $2,$1,0xeef1
    ori  $3,$2,0xeef2
    ori  $4,$3,0xeef3
    
_loop:
    j _loop
    nop