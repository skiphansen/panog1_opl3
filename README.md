# A port of the OPL3 to the Panologic G1 thin client

** THIS PROJECT IS A WIP, IT IS NOT FUNCTIONAL!

The plan was to port [opl3_fpga](https://github.com/gtaylormb/opl3_fpga) to the
Panologic G1 thin client.

Unfortunately it didn't fit.

`Place:665 - The design has 13 block-RAM components of which 4 block-RAM 
components require the adjacent multiplier site to remain empty.  This is 
because certain input pins of adjacent block-RAM and multiplier sites 
share routing ressources.  In addition, the design has 35 multiplier 
components.  Therefore, the design would require a total of 39 multiplier 
sites on the device.  The current device has only 36 multiplier sites.`

I'm committing the work in case someone wants to take up the challenge since
it's "close" to fitting.

At least imfplay compiles and runs somewhat.

This project is based on [pano_hello_g1](https://github.com/skiphansen/pano_hello_g1),
please see that project for more information.

The Panologic G2 will solve this issue since it has 180 multiplers instead
of 36 !

