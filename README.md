# Yamaha OPL2 for the Panologic thin client

This is a port of Saanlima Electronics's port of Greg Taylor's clone of the
OPL3 Yamaha YMF262 FM synthesis sound chip in System Verilog.  

If you don't know what a Panologic thin client is please see [here](https://hackaday.com/2013/01/11/ask-hackaday-we-might-have-some-fpgas-to-hack/) 
and [here](https://github.com/skiphansen/pano_hello_g1) for background.

Magnus of Saanlima Electronics translated Greg Taylor's System Verilog HDL to 
legacy Verilog because Xilinx's ISE doesn't support System Verilog. This is
important for designs based on the Spartan 3 or Spartan 6 FPGAs such as the 
Panologic devices.

Magnus's was interested in running Doom on an Spartan 6 LX9 and he found that
the full OPL3 didn't fit so he also also created a OPL2 subset which all that
is used by Doom anyway.

I made further modifications to the core OPL code to correct errors encountered 
when using the Spartan 3 version of ISE.  I also and created an interface to 
the Pano's Wolfson codec.

I had initially given up on the Pano G1 after the first cut didn't fit 
because it ran out of multiplers. When I mentioned this to Tom Verbeure he 
spent a few minutes studying the HDL then made a few tweaks and eliminated a 
bunch of multipliers.  It now fits by a good margin (28% utilization including
a RISC-V core, VGA and other glue logic).

The eventual plan is to use this core on other projects to do more interesting
things.

Note: See this [project](https://github.com/skiphansen/panog2_opl3) for the 
second generation Pano.

## Status
The project builds and the Doom test files play.  It is suspected that the 
files that don't play are targeting an opl3 rather than an opl2.

A prebuilt demo bit and firmware file is committed (./xilinx/panog1_opl3.msc) 
which plays an .DRO file that has been compiled into the firmware.

## Building and Installation
Please see [pano_hello_g1](https://github.com/skiphansen/pano_hello_g1) for 
more information and detailed information on how to flash the panog1_opl3.msc 
image into a device.

## Acknowledgement and Thanks
This project uses code from several other projects including:
 - [https://github.com/gtaylormb/opl3_fpga]
 - [https://github.com/Saanlima/Pipistrello]
 - [https://github.com/zephray/VerilogBoy]
 - [https://github.com/cliffordwolf/picorv32](https://github.com/cliffordwolf/picorv32)
 - [https://github.com/MParygin/v.vga.font8x16](https://github.com/MParygin/v.vga.font8x16)
 - [https://github.com/skiphansen/pano_hello_g1]

## LEGAL 

My original work (the Pano Codec glue code) is released under the GNU General 
Public License, version 2.

