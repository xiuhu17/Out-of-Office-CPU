.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

   LUI x28, 2315
nop
nop
nop
nop
nop
LUI x20, 2475
nop
nop
nop
nop
nop
LUI x31, 2068
nop
nop
nop
nop
nop
LUI x30, 2021
nop
nop
nop
nop
nop
LUI x14, 4023
nop
nop
nop
nop
nop
AUIPC x21, 525
nop
nop
nop
nop
nop
AUIPC x27, 698
nop
nop
nop
nop
nop
AUIPC x3, 3810
nop
nop
nop
nop
nop
AUIPC x29, 684
nop
nop
nop
nop
nop
AUIPC x4, 3821
nop
nop
nop
nop
nop
ADDI x18, -1625
nop
nop
nop
nop
nop
ADDI x20, 779
nop
nop
nop
nop
nop
ADDI x22, -927
nop
nop
nop
nop
nop
ADDI x10, -448
nop
nop
nop
nop
nop
ADDI x4, -693
nop
nop
nop
nop
nop
SLTI x22, 2024
nop
nop
nop
nop
nop
SLTI x13, -1072
nop
nop
nop
nop
nop
SLTI x15, 1693
nop
nop
nop
nop
nop
SLTI x26, 862
nop
nop
nop
nop
nop
SLTI x21, -1552
nop
nop
nop
nop
nop
SLTIU x17, 522
nop
nop
nop
nop
nop
SLTIU x19, -1562
nop
nop
nop
nop
nop
SLTIU x21, 1576
nop
nop
nop
nop
nop
SLTIU x23, -690
nop
nop
nop
nop
nop
SLTIU x7, 2000
nop
nop
nop
nop
nop
XORI x27, -1824
nop
nop
nop
nop
nop
XORI x6, 903
nop
nop
nop
nop
nop
XORI x14, -1233
nop
nop
nop
nop
nop
XORI x3, 336
nop
nop
nop
nop
nop
XORI x28, 1822
nop
nop
nop
nop
nop
ORI x18, -426
nop
nop
nop
nop
nop
ORI x1, 863
nop
nop
nop
nop
nop
ORI x26, -806
nop
nop
nop
nop
nop
ORI x23, 1771
nop
nop
nop
nop
nop
ORI x20, 1128
nop
nop
nop
nop
nop
ANDI x23, -228
nop
nop
nop
nop
nop
ANDI x26, -1772
nop
nop
nop
nop
nop
ANDI x6, 1367
nop
nop
nop
nop
nop
ANDI x27, 1084
nop
nop
nop
nop
nop
ANDI x11, -1585
nop
nop
nop
nop
nop
SLLI x29, 1241
nop
nop
nop
nop
nop
SLLI x28, 1094
nop
nop
nop
nop
nop
SLLI x24, -1377
nop
nop
nop
nop
nop
SLLI x16, 1873
nop
nop
nop
nop
nop
SLLI x9, -1953
nop
nop
nop
nop
nop
SRLI x7, 960
nop
nop
nop
nop
nop
SRLI x11, -1919
nop
nop
nop
nop
nop
SRLI x12, 1492
nop
nop
nop
nop
nop
SRLI x8, 1007
nop
nop
nop
nop
nop
SRLI x19, 205
nop
nop
nop
nop
nop
SRAI x27, 1335
nop
nop
nop
nop
nop
SRAI x5, -1861
nop
nop
nop
nop
nop
SRAI x8, 1090
nop
nop
nop
nop
nop
SRAI x20, 1445
nop
nop
nop
nop
nop
SRAI x17, 1251
nop
nop
nop
nop
nop
ADD x7, x26, x28
nop
nop
nop
nop
nop
ADD x28, x12, x6
nop
nop
nop
nop
nop
ADD x3, x1, x24
nop
nop
nop
nop
nop
ADD x6, x16, x14
nop
nop
nop
nop
nop
ADD x21, x27, x28
nop
nop
nop
nop
nop
SUB x16, x15, x3
nop
nop
nop
nop
nop
SUB x19, x28, x13
nop
nop
nop
nop
nop
SUB x30, x30, x21
nop
nop
nop
nop
nop
SUB x21, x11, x9
nop
nop
nop
nop
nop
SUB x24, x3, x17
nop
nop
nop
nop
nop
SLL x13, x22, x15
nop
nop
nop
nop
nop
SLL x18, x31, x28
nop
nop
nop
nop
nop
SLL x8, x31, x13
nop
nop
nop
nop
nop
SLL x26, x31, x31
nop
nop
nop
nop
nop
SLL x20, x25, x11
nop
nop
nop
nop
nop
SLT x15, x19, x15
nop
nop
nop
nop
nop
SLT x4, x17, x8
nop
nop
nop
nop
nop
SLT x14, x7, x19
nop
nop
nop
nop
nop
SLT x3, x12, x12
nop
nop
nop
nop
nop
SLT x9, x23, x26
nop
nop
nop
nop
nop
SLTU x2, x5, x17
nop
nop
nop
nop
nop
SLTU x16, x5, x6
nop
nop
nop
nop
nop
SLTU x15, x24, x31
nop
nop
nop
nop
nop
SLTU x23, x19, x14
nop
nop
nop
nop
nop
SLTU x8, x17, x9
nop
nop
nop
nop
nop
XOR x31, x28, x31
nop
nop
nop
nop
nop
XOR x5, x17, x12
nop
nop
nop
nop
nop
XOR x28, x17, x21
nop
nop
nop
nop
nop
XOR x5, x20, x1
nop
nop
nop
nop
nop
XOR x7, x29, x13
nop
nop
nop
nop
nop
SRL x2, x18, x28
nop
nop
nop
nop
nop
SRL x26, x31, x16
nop
nop
nop
nop
nop
SRL x21, x25, x23
nop
nop
nop
nop
nop
SRL x8, x12, x13
nop
nop
nop
nop
nop
SRL x16, x22, x30
nop
nop
nop
nop
nop
SRA x9, x26, x31
nop
nop
nop
nop
nop
SRA x28, x1, x20
nop
nop
nop
nop
nop
SRA x22, x20, x2
nop
nop
nop
nop
nop
SRA x18, x29, x13
nop
nop
nop
nop
nop
SRA x31, x13, x8
nop
nop
nop
nop
nop
OR x12, x29, x27
nop
nop
nop
nop
nop
OR x10, x15, x17
nop
nop
nop
nop
nop
OR x10, x27, x8
nop
nop
nop
nop
nop
OR x14, x12, x26
nop
nop
nop
nop
nop
OR x22, x1, x19
nop
nop
nop
nop
nop
AND x21, x29, x17
nop
nop
nop
nop
nop
AND x28, x4, x16
nop
nop
nop
nop
nop
AND x15, x24, x14
nop
nop
nop
nop
nop
AND x6, x17, x8
nop
nop
nop
nop
nop
AND x22, x22, x7
nop
nop
nop
nop
nop

    

    slti x0, x0, -256 # this is the magic instruction to end the simulation
