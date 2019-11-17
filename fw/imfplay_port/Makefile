TOPDIR := ../..

MAIN_PRG := imfplay

# Test file
#DRO_FILE = opl3dro/doom_000.dro
#DRO_FILE = opl3dro/doom_035.dro
#DRO_FILE = opl3dro/doom_036.dro

#DRO_FILE = opl3dro/doom2_000.dro
#DRO_FILE = opl3dro/doom2_001.dro
#DRO_FILE = opl3dro/doom2_002.dro
#DRO_FILE = opl3dro/doom2_003.dro
#DRO_FILE = opl3dro/doom2_013.dro
#DRO_FILE = opl3dro/doom2_014.dro
DRO_FILE = opl3dro/doom2_015.dro
#DRO_FILE = opl3dro/doom2_016.dro
#DRO_FILE = opl3dro/doom2_031.dro
#DRO_FILE = opl3dro/doom2_032.dro
#DRO_FILE = opl3dro/xcom_001.dro

# these don't work (opl3 support needed?)

#OPL3 files
#DRO_FILE = opl3dro/war_000.dro #(doesn't fit in flash, plays if truncated manually
#DRO_FILE = opl3dro/atlantis_000.dro #(doesn't fit in flash)
#DRO_FILE = opl3dro/dott_000.dro

# opl2 file?

CFLAGS = -I../include -MD -O1 -march=rv32i -ffreestanding -nostdlib 
VPATH = ../common

all: $(MAIN_PRG).lst $(MAIN_PRG).bin 

-include $(TOPDIR)/Makefile

CLEAN_FILES += mfs_file.h

OBJS = start.o mfs_filesys.o main.o imfplay.o audio.o i2c.o printf.o 
OBJS += pano_time.o stdlib.o

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

mfs_file.h: $(BIN2C) Makefile
	$(BIN2C) $(DRO_FILE) mfs_file.h gMfsFile

mfs_filesys.o: mfs_file.h

prog: $(MAIN_PRG).bin
	$(XC3SPROG) $(XC3SPROG_OPTS) -I$(XC3SPROG_BIT_FILE) $(MAIN_PRG).bin:W:786432:BIN
	$(XC3SPROG) $(XC3SPROG_OPTS) $(BIT_FILE).bit

-include *.d

