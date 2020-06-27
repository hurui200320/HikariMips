	.org 0x0
	.globl	_start
	.set noat
    .set noreorder
    .set nomacro
_start:
	addi $s0,$0,-1
    addi $s1,$0,0
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    addi $s0,$s0,1
    addi $s1,$s1,4
    sw $s0,512($s1)
    
    add $s0,$zero,$zero   
    addi $s1,$zero,28   #排序区间
sort_loop:
    lw $s3,512($s0)     
    lw $s4,512($s1)
    slt $t0,$s3,$s4
    beq $t0,$0,sort_next   #降序排序
	nop
    sw $s3, 512($s1)
    sw $s4, 512($s0)   
sort_next:
    addi $s1, $s1, -4   
    bne $s0, $s1, sort_loop  
    nop
    addi $s0,$s0,4
    addi $s1,$zero,28
    bne $s0, $s1, sort_loop
	nop
    addi   $v0,$zero,10 
	j _loop
	
_loop:
	j _loop
	nop