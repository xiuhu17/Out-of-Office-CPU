.section .text
.globl _start
    # Refer to the RISC-V ISA Spec for the functionality of
    # the instructions in this test program.
_start:
    # Note that the comments in this file should not be taken as
    # an example of good commenting style!!  They are merely provided
    # in an effort to help you understand the assembly style.

    addi x1, x0, 4  # x1 <= 4
    nop
    nop
    nop             # nops in between to prevent hazard
    nop
    nop
    addi x3, x1, 8  # x3 <= x1 + 8

    # Add your own test cases here!
    addi x10, x0, 4  # x1 <= 4

    AUIPC   x2, 0x20            # Add PC to immediate, store in x2
    NOP
    NOP
    NOP
    AUIPC   x2, 0x20            # Add PC to immediate, store in x2

        LUI     x9, 0x1F            # Load upper immediate to x1
            LUI     x9, 0x1F            # Load upper immediate to x1
                LUI     x9, 0x1F            # Load upper immediate to x1
    NOP
    NOP
    ADDI    x3, x1, 10          # Add immediate to x1, store in x3
    NOP
    NOP
    AUIPC   x2, 0x20            # Add PC to immediate, store in x2

    NOP
    NOP

    AUIPC   x2, 0x20            # Add PC to immediate, store in x2
    LUI     x9, 0x1F            # Load upper immediate to x1
        LUI     x9, 0x1F            # Load upper immediate to x1
            LUI     x9, 0x1F            # Load upper immediate to x1
                LUI     x9, 0x1F            # Load upper immediate to x1
                LUI     x9, 0x1F            # Load upper immediate to x1

                LUI     x9, 0x1F            # Load upper immediate to x1

                LUI     x1, 0x1F            # Load upper immediate to x1
        addi x10, x0, 4  # x1 <= 4
            addi x10, x0, 4  # x1 <= 4
                addi x10, x0, 4  # x1 <= 4
                    addi x10, x0, 4  # x1 <= 4
                        addi x10, x0, 4  # x1 <= 4
                            addi x10, x0, 4  # x1 <= 4
                                addi x10, x0, 4  # x1 <= 4
                                    addi x10, x0, 4  # x1 <= 4
                                        addi x10, x0, 4  # x1 <= 4
                                            addi x10, x0, 4  # x1 <= 4
        SRLI    x13, x12, 3         # Shift right logical immediate
        NOP
        NOP
        NOP
        NOP
        NOP
    SRAI    x12, x13, 2         # Shift right arithmetic immediate
    OR      x15, x14, x12       # OR x14 with x12, store in x15
    XORI    x16, x14, 0xFF      # XOR immediate with x15, store in x16

    # More instructions to balance RR, RI, LUI, AUIPC usage
    NOP
    NOP
    NOP
    NOP
    NOP
    LUI     x5, 0
    NOP
    NOP
    NOP
    NOP
    ADD     x17, x16, x10       # Add x16 and x10
    SLTI    x18, x5, 0        # Set less than immediate
    NOP
    NOP
    NOP
    NOP
    NOP
    SLT     x19, x18, x17       # Set less than

    

    slti x0, x0, -256 # this is the magic instruction to end the simulation
