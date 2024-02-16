// This class generates random valid RISC-V instructions to test your
// RISC-V cores.

class RandInst;
  // You will increment this number as you generate more random instruction
  // types. Once finished, NUM_TYPES should be 9, for each opcode type in
  // rv32i_opcode.
  // TODO:
  localparam NUM_TYPES = 9;

  // You'll need this type to randomly generate variants of certain
  // instructions that have the funct7 field.
  typedef enum bit [6:0] {
    base    = 7'b0000000,
    variant = 7'b0100000
  } funct7_t;

  // Various ways RISC-V instruction words can be interpreted.
  // See page 104, Chapter 19 RV32/64G Instruction Set Listings
  // of the RISC-V v2.2 spec.
  typedef union packed {
    bit [31:0] word;

    struct packed {
      bit [11:0] i_imm;
      bit [4:0] rs1;
      bit [2:0] funct3;
      bit [4:0] rd;
      rv32i_opcode opcode;
    } i_type;

    struct packed {
      bit [6:0] funct7;
      bit [4:0] rs2;
      bit [4:0] rs1;
      bit [2:0] funct3;
      bit [4:0] rd;
      rv32i_opcode opcode;
    } r_type;

    struct packed {
      bit [11:5] imm_s_top;
      bit [4:0]  rs2;
      bit [4:0]  rs1;
      bit [2:0]  funct3;
      bit [4:0]  imm_s_bot;
      rv32i_opcode opcode;
    } s_type;

    /* TODO: Write the struct for b-type instructions.*/
    struct packed {
      bit [12:12] imm_b_top;
      bit [10:5] imm_b_middle_top;
      bit [4:0] rs2;
      bit [4:0] rs1;
      bit [2:0] funct3;
      bit [4:1] imm_b_middle_bot;
      bit [11:11] imm_b_bot;
      rv32i_opcode opcode;
    } b_type;

    struct packed {
      bit [31:12] imm;
      bit [4:0]  rd;
      rv32i_opcode opcode;
    } j_type;

    struct packed {
      bit [31:12] u_imm;
      bit [4:0] rd;
      rv32i_opcode opcode;
    } u_type;

  } instr_t;

  rand bit [2:0] f3;
  rand bit [6:0] f7;
  rand instr_t instr;
  rand bit [NUM_TYPES-1:0] instr_type;

  constraint funct3_c { instr.r_type.funct3 == f3; }
  constraint funct7_c { instr.r_type.funct7 == f7; }
  // Make sure we have an even distribution of instruction types.
  constraint solve_order_c { solve instr_type before instr; }

  // Hint/TODO: you will need another solve_order constraint for funct3
  // to get 100% coverage with 500 calls to .randomize().
  constraint solve_order_funct3_c { 
    solve f3 before f7; 
  }


  // Pick one of the instruction types.
  constraint instr_type_c {
    $countones(instr_type) == 1; // Ensures one-hot.
  }

  // Constraints for actually generating instructions, given the type.
  // Again, see the instruction set listings to see the valid set of
  // instructions, and constrain to meet it. Refer to ../pkg/types.sv
  // to see the typedef enums.

  constraint instr_c {
      // Reg-imm instructions
      instr_type[0] -> {
        instr.i_type.opcode == imm_opcode;

        // Implies syntax: if funct3 is sr, then funct7 must be
        // one of two possibilities.
        instr.r_type.funct3 == srl_alu_op -> {
          instr.r_type.funct7 inside {base, variant};
        }

        // This if syntax is equivalent to the implies syntax above
        // but also supports an else { ... } clause.
        if (instr.r_type.funct3 == sll_alu_op) {
          instr.r_type.funct7 == base;
        } 
      }

      // Reg-reg instructions
      instr_type[1] -> {
        instr.r_type.opcode == reg_opcode;

        if (instr.r_type.funct3 == add_funct3) {
          instr.r_type.funct7 inside {base, variant};
        } else if (instr.r_type.funct3 == sr_funct3) {
          instr.r_type.funct7 inside {base, variant};
        } else {
          instr.r_type.funct7 == base;
        }
      }

      // Store instructions -- these are easy to constrain!
      instr_type[2] -> {
        instr.s_type.opcode == store_opcode;
        instr.s_type.funct3 inside {sw_funct3, sb_funct3, sh_funct3};
      }

      // // Load instructions
      instr_type[3] -> {
        instr.i_type.opcode == load_opcode;
        instr.i_type.funct3 inside {lb_funct3, lh_funct3, lw_funct3, lbu_funct3, lhu_funct3};
      }

      // TODO: Do all 9 types!
      // Branch instruction
      instr_type[4] -> {
        instr.b_type.opcode == br_opcode;
        instr.b_type.funct3 inside {beq_funct3, bne_funct3, blt_funct3, bge_funct3, bltu_funct3, bgeu_funct3}; 
      }

      // Jump and Link Register instruction
      instr_type[5] -> {
        instr.i_type.opcode == jalr_opcode;
        instr.i_type.funct3 == 3'b000;
      }

      // Jump and Link instruction
      instr_type[6] -> {
        instr.j_type.opcode == jal_opcode;
      }

      // auipc
      instr_type[7] -> {
        instr.u_type.opcode == auipc_opcode;
      }

      // lui
      instr_type [8] -> {
        instr.u_type.opcode == lui_opcode;
      }
  }

  `include "../../hvl/instr_cg.svh"

  // Constructor, make sure we construct the covergroup.
  function new();
    instr_cg = new();
  endfunction : new

  // Whenever randomize() is called, sample the covergroup. This assumes
  // that every time you generate a random instruction, you send it into
  // the CPU.
  function void post_randomize();
    instr_cg.sample(this.instr);
  endfunction : post_randomize

  // A nice part of writing constraints is that we get constraint checking
  // for free -- this function will check if a bit vector is a valid RISC-V
  // instruction (assuming you have written all the relevant constraints).
  function bit verify_valid_instr(instr_t inp);
    bit valid = 1'b0;
    this.instr = inp;
    for (int i = 0; i < NUM_TYPES; ++i) begin
      this.instr_type = 1 << i;
      if (this.randomize(null)) begin
        valid = 1'b1;
        break;
      end
    end
    return valid;
  endfunction : verify_valid_instr
endclass : RandInst