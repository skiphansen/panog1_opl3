#define regnum_q0   0
#define regnum_a0  10

.section .text

start:
#copy the jump to the isr into place
li a0, 0x0e000ff4
la a1, jump_irq
lw a2, 0(a1)
sw a2, 0(a0)
lw a2, 4(a1)
sw a2, 4(a0)
lw a2, 8(a1)
sw a2, 8(a0)

# copy data section
la a0, _sidata
la a1, _sdata
la a2, _edata
bge a1, a2, end_init_data
loop_init_data:
lw a3, 0(a0)
sw a3, 0(a1)
addi a0, a0, 4
addi a1, a1, 4
blt a1, a2, loop_init_data
end_init_data:

# zero-init bss section
la a0, _sbss
la a1, _ebss
bge a0, a1, end_init_bss
loop_init_bss:
sw zero, 0(a0)
addi a0, a0, 4
blt a0, a1, loop_init_bss
end_init_bss:

# call main
call main

# jump to the interrupt handler.  This will be copied into the
# vector @ startup 
jump_irq:
lui a0, %hi(irq)
addi a0, a0, %lo(irq)
jr a0, 0

irq:
#.word 0x0000450B
addi a0, gp, 0
call irq_handler

         .weak irq_handler
irq_handler:
         j irq_handler
