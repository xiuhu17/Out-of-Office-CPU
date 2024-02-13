.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    addi x1, x0, 3  # x1 <= 4
    addi x3, x1, 2
    add x0, x1, x3
    add x3, x0, x3
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    lui x1, 0x70008
    lui x2, 0x70004

    add x3, x3, x3
    add x3, x3, x3
    add x3, x3, x3
    add x3, x3, x3
    add x3, x3, x3

    sw  x1, 4(x1)
    sw  x2, 8(x1)

    add x3, x1, 6
    lh  x4, 0(x3)
    add x5, x4, x3
    sub x6, x4, x5
    add x6, x5, x5
    xor x7, x6, x3
    
    add x1, x1, 2

    jal x1, test 
    add x1, x1, 2
    add x1, x1, x1

test:

    add x1, x1, 2
    add x1, x1, x1



    slti x0, x0, -256 # this is the magic instruction to end the simulation

    good: .word 0x600d600d
    goodgood: .word 0x600d6000



