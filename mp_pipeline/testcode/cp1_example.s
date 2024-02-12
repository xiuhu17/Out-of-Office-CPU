.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    addi x1, x0, 3  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    lui x1, 0x70008
    lui x2, 0x70004
    addi x1, x1, 2
    addi x1, x1, 2
    addi x1, x1, 2 
    addi x1, x1, 2 
    addi x1, x1, 2 
    addi x1, x1, 2 
    addi x1, x1, 2 
    addi x1, x1, 2 
    addi x1, x1, 2 
    add  x3, x1, x2
    lui x4, 0x7000c
    add x5, x4, x3
    sw  x5, 0(x2)
    lw  x6, 0(x2)
    addi x7, x6, 3
    add x1, x1, 2


    slti x0, x0, -256 # this is the magic instruction to end the simulation

    good: .word 0x600d600d
    goodgood: .word 0x600d6000



