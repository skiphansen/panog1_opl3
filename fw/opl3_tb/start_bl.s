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

# zero-initialize register file
addi x1, zero, 0
# x2 (sp) is initialized by reset
addi x3, zero, 0
addi x4, zero, 0
addi x5, zero, 0
addi x6, zero, 0
addi x7, zero, 0
addi x8, zero, 0
addi x9, zero, 0
addi x10, zero, 0
addi x11, zero, 0
addi x12, zero, 0
addi x13, zero, 0
addi x14, zero, 0
addi x15, zero, 0
addi x16, zero, 0
addi x17, zero, 0
addi x18, zero, 0
addi x19, zero, 0
addi x20, zero, 0
addi x21, zero, 0
addi x22, zero, 0
addi x23, zero, 0
addi x24, zero, 0
addi x25, zero, 0
addi x26, zero, 0
addi x27, zero, 0
addi x28, zero, 0
addi x29, zero, 0
addi x30, zero, 0
addi x31, zero, 0

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

# jump to the application
li a1, 0x0c000000
jr a1, 0

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

