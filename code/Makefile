TOPDIR=$(shell pwd)

#export LD_PRELOAD =
CFLAGS := -D_KERNEL -fno-builtin -march=mips32 -DMEMSTART=0x80000000 -DMEMSIZE=0x04000 -DCPU_COUNT_PER_US=1000
CFLAGS += -fno-reorder-blocks -fno-reorder-functions

OBJDIR = ./obj

export TOPDIR AR CFLAGS
export CROSS_COMPILE ?= mipsel-linux-

all:
	make compile

compile:main.bin main.data convert
	./convert
	mkdir -p $(OBJDIR)
	mv main.elf  $(OBJDIR)/.
	mv test.s    $(OBJDIR)/.
	mv main.bin  $(OBJDIR)/.
	mv main.data $(OBJDIR)/.
	mv *.coe     $(OBJDIR)/.
	mv *.mif     $(OBJDIR)/.
	cp $(OBJDIR)/inst_ram.mif  $(OBJDIR)/axi_ram.mif

main.bin:main.elf
	${CROSS_COMPILE}objcopy -O binary -j .text $< $@ 

main.data:main.elf
	${CROSS_COMPILE}objcopy -O binary -j .data $< $@ 

main.elf: start.o
	${CROSS_COMPILE}gcc -E -P -Umips -D_LOADER -U_MAIN $(CFLAGS) bin.lds.S -o bin.lds
	${CROSS_COMPILE}ld -g -T  bin.lds  -o $@ start.o -L .
	${CROSS_COMPILE}objdump -alD $@ > test.s

convert:convert.c
	gcc  $(ALIGNED) -std=c99 -o convert  convert.c

clean:
	rm -f *.o *.a bin.lds convert
	rm -rf obj

.S.o:
	${CROSS_COMPILE}gcc -O2 $(CFLAGS) -fno-pic -mno-abicalls -g -DGUEST -I include -I .  -c $< -nostdinc -nostdlib
.c.o:
	${CROSS_COMPILE}gcc -O2 $(CFLAGS) -fno-pic -mno-abicalls -g -DGUEST -I include -I .  -c $< -nostdinc -nostdlib
.S.s:
	${CROSS_COMPILE}gcc -O2 $(CFLAGS) -fno-pic -mno-abicalls -g -DGUEST -I include -I .  -S -fverbose-asm -o $@ $< -nostdinc -nostdlib
.c.s:
	${CROSS_COMPILE}gcc -O2 $(CFLAGS) -fno-pic -mno-abicalls -g -DGUEST -I include -I .  -S -fverbose-asm -o $@  $< -nostdinc -nostdlib

