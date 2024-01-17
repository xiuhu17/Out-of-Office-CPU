covergroup instr_cg with function sample(instr_t instr);
  // Easy covergroup to see that we're at least exercising
  // every opcode. Since opcode is an enum, this makes bins
  // for all its members.
  all_opcodes : coverpoint instr.i_type.opcode;


  // Some simple coverpoints on various instruction fields.
  // Recognize that these coverpoints are inherently less useful
  // because they really make sense in the context of the opcode itself.
  all_funct7 : coverpoint funct7_t'(instr.r_type.funct7);

  // TODO: Write the following coverpoints:

  // Check that funct3 takes on all possible values.
  // all_funct3 : coverpoint ... ;

  // Check that the rs1 and rs2 fields across instructions take on
  // all possible values (each register is touched).
  // all_regs_rs1 : coverpoint ... ;
  // all_regs_rs2 : coverpoint ... ;

  // Now, cross coverage takes in the opcode context to correctly
  // figure out the /real/ coverage.
  funct3_cross : cross instr.i_type.opcode, instr.i_type.funct3 {

    // We want to ignore the cases where funct3 isn't relevant.

    // For example, for JAL, funct3 doesn't exist. Put it in an ignore_bins.
    ignore_bins JAL_FUNCT3 = funct3_cross with (instr.i_type.opcode == op_jal);

    // TODO:  What other opcodes does funct3 not exist for? Put those in
    // ignore_bins.


    // Branch instructions use funct3, but only 6 of the 8 possible values
    // are valid. Ignore the other two -- don't include them in the coverage
    // report. In fact, if they're generated, that's an illegal instruction.
    illegal_bins BR_FUNCT3 = funct3_cross with
    (instr.i_type.opcode == op_br
     && !(instr.i_type.funct3 inside {beq, bne, blt, bge, bltu, bgeu}));

    // TODO: You'll also have to ignore some funct3 cases in JALR, LOAD, and
    // STORE. Write the illegal_bins/ignore_bins for those cases.
  }

  // Coverpoint to make separate bins for funct7.
  coverpoint instr.r_type.funct7 {
    bins range[] = {[0:$]};
    ignore_bins not_in_spec = {[1:31], [33:127]};
  }

  // Cross coverage for funct7.
  funct7_cross : cross instr.r_type.opcode, instr.r_type.funct3, instr.r_type.funct7 {

    // No opcodes except op_reg and op_imm use funct7, so ignore the rest.
    ignore_bins OTHER_INSTS = funct7_cross with
    (!(instr.r_type.opcode inside {op_reg, op_imm}));

    // TODO: Get rid of all the other cases where funct7 isn't necessary, or cannot
    // take on certain values.
  }

endgroup : instr_cg
