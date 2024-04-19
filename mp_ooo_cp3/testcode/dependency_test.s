dependency_test.s: 
.align 4
.section .text
.globl _start
    # This program consists of small snippets
    # containing RAW, WAW, and WAR hazards

    # This test is NOT exhaustive
_start:

# initialize
li x1,  1
li x2,  2
li x3,  3
li x4,  4
li x5,  5
li x6,  6
li x7,  7
li x8,  8
li x9,  9
li x10, 5
li x11, 8
li x12, 4
li x13, 2

nop
nop
nop
nop
nop

# RAW
mul x3, x1, x2
add x5, x3, x4

# WAW
mul x6, x7, x8
add x6, x9, x10

# WAR
mul x11, x12, x13
add x12, x1, x2



halt:                 
    slti x0, x0, -256
                       