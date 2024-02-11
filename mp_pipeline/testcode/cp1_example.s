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
    lui x8, 0x70008
    nop
    nop
    nop
    nop
    nop
    lui x7, 0x70004
    sw x1, 8(x8)
    nop
    nop
    nop
    nop
    nop
    sw x1, 4(x8)
    nop
    nop
    nop
    nop
    nop
    lw x1, 8(x8)
    nop
    nop
    nop
    nop
    nop
    lw x1, 4(x8)



    slti x0, x0, -256 # this is the magic instruction to end the simulation

    good: .word 0x600d600d
    goodgood: .word 0x600d6000

