TOPDIR := ../..

MAIN_PRG := hello

CFLAGS = -I../include -MD -O1 -march=rv32i -ffreestanding -nostdlib 
TOOLCHAIN_PREFIX = riscv32-unknown-elf-
BIN2MIF := ../../tools/bin2mif/bin2mif
BIN2C := ../../tools/bin2c/bin2c

all: $(MAIN_PRG).lst $(MAIN_PRG).bin 

OBJS = start.o hello.o

#override CFLAGS for native compiles
$(BIN2C) $(BIN2MIF) : CFLAGS =

$(BIN2MIF): $(BIN2MIF).cpp

$(BIN2C) : $(BIN2C).c 

$(MAIN_PRG).bin: $(MAIN_PRG).elf
	$(TOOLCHAIN_PREFIX)objcopy -O binary $< $@

$(MAIN_PRG).lst : $(MAIN_PRG).elf
	$(TOOLCHAIN_PREFIX)objdump -d $< > $@

$(MAIN_PRG).mif: $(MAIN_PRG).bin $(BIN2MIF)
	dd if=/dev/zero of=flash.bin bs=1k count=768
	cat $(MAIN_PRG).bin >> flash.bin
	$(BIN2MIF) flash.bin $(MAIN_PRG).mif 1048576 8
	cp $(MAIN_PRG).mif ../../fpga

$(MAIN_PRG).elf: $(OBJS) sections.lds
	$(TOOLCHAIN_PREFIX)gcc $(CFLAGS) -Wl,-Bstatic,-T,sections.lds,-Map,$(MAIN_PRG).map,--strip-debug,--no-relax -o $@ $(OBJS) -lgcc
	size $@

%.o: %.c
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

%.o: %.s
	$(TOOLCHAIN_PREFIX)gcc -c $(CFLAGS) $<

prog: $(MAIN_PRG).bin
	$(XC3SPROG) $(XC3SPROG_OPTS) -I$(XC3SPROG_BIT_FILE) $(MAIN_PRG).bin:W:786432:BIN
	$(XC3SPROG) $(XC3SPROG_OPTS) $(BIT_FILE).bit

clean:
	rm -rf *.o *.d *.elf *.bin *.map *.lst

.PHONY: clean

-include *.d
-include $(TOPDIR)/Makefile

