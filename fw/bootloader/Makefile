TOPDIR := ../..

MEM_WORDS := 2048
CFLAGS = -I../include -march=rv32i -O1 -ffreestanding -nostdlib 

all: picorv_bl.mif picorv_bl.lst  

-include $(TOPDIR)/Makefile

picorv_bl.elf: sections_bl.lds start_bl.s bootloader.c
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections_bl.lds,-Map=picorv_bl.map,--strip-debug -Wl,--no-relax -o picorv_bl.elf start_bl.s bootloader.c
	size picorv_bl.elf

picorv_bl.bin: picorv_bl.elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary picorv_bl.elf picorv_bl.bin

picorv_bl.mif: $(BIN2MIF) picorv_bl.bin
	$(BIN2MIF) picorv_bl.bin picorv_bl.mif 4096 32
	$(BIN2MIF) picorv_bl.bin picorv_bl_0.mif 1024 8 0 3
	$(BIN2MIF) picorv_bl.bin picorv_bl_1.mif 1024 8 1 3
	$(BIN2MIF) picorv_bl.bin picorv_bl_2.mif 1024 8 2 3
	$(BIN2MIF) picorv_bl.bin picorv_bl_3.mif 1024 8 3 3
	cp *.mif ../../fpga

update_ram: picorv_bl.mem
	$(XILINX_BIN)/data2mem -bm picorv_bl.bmm -bt $(BIT_FILE).bit -bd picorv_bl.mem -o b $(BIT_FILE).new.bit
	$(XILINX_BIN)/data2mem -bm picorv_bl.bmm -bt $(BIT_FILE).new.bit -d > $(BIT_FILE).new.bit.dump
	mv $(BIT_FILE).bit $(BIT_FILE).bit.orig
	mv $(BIT_FILE).new.bit $(BIT_FILE).bit
	$(XC3SPROG) $(XC3SPROG_OPTS) $(BIT_FILE).bit

picorv_bl.lst : picorv_bl.elf
	$(TOOLCHAIN_PREFIX)objdump -d $< > $@

picorv_bl.mem: picorv_bl.bin
	$(CREATE_MIF) -f mem -d $(MEM_WORDS) -w 32 $< > picorv_bl.mem

prog: picorv_bl.mem
	$(XILINX_BIN)/data2mem -bm bootloader.bmm -bt $(BIT_FILE).bit -bd picorv_bl.mem -o b $(BIT_FILE).new.bit
#	$(XILINX_BIN)/data2mem -bm bootloader.bmm -bt $(BIT_FILE).new.bit -d > $(BIT_FILE).dump
	mv $(BIT_FILE).bit $(BIT_FILE).orig
	mv $(BIT_FILE).new.bit $(BIT_FILE).bit
	$(XC3SPROG) $(XC3SPROG_OPTS) $(BIT_FILE).bit

-include *.d


