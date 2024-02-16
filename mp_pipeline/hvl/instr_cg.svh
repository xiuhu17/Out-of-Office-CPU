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
  all_funct3 : coverpoint (instr.r_type.funct3);

  // Check that the rs1 and rs2 fields across instructions take on
  // all possible values (each register is touched).
  all_regs_rs1 : coverpoint (instr.r_type.rs1);
  all_regs_rs2 : coverpoint (instr.r_type.rs2);

  // Now, cross coverage takes in the opcode context to correctly
  // figure out the /real/ coverage.
  funct3_cross : cross instr.i_type.opcode, instr.i_type.funct3 {

    // We want to ignore the cases where funct3 isn't relevant.

    // For example, for JAL, funct3 doesn't exist. Put it in an ignore_bins.
    ignore_bins JAL_FUNCT3 = funct3_cross with (instr.i_type.opcode == jal_opcode);

    // TODO:  What other opcodes does funct3 not exist for? Put those in
    // ignore_bins.
    ignore_bins AUIPC_FUNCT3 = funct3_cross with (instr.i_type.opcode == auipc_opcode);
    ignore_bins LUI_FUNCT3 = funct3_cross with (instr.i_type.opcode == lui_opcode);


    // Branch instructions use funct3, but only 6 of the 8 possible values
    // are valid. Ignore the other two -- don't include them in the coverage
    // report. In fact, if they're generated, that's an illegal instruction.
    illegal_bins BR_FUNCT3 = funct3_cross with
    (instr.i_type.opcode == br_opcode
     && !(instr.i_type.funct3 inside {beq_funct3, bne_funct3, blt_funct3, bge_funct3, bltu_funct3, bgeu_funct3}));

    // TODO: You'll also have to ignore some funct3 cases in JALR, LOAD, and
    // STORE. Write the illegal_bins/ignore_bins for those cases.
    illegal_bins JALR_FUNCT3 = funct3_cross with (instr.i_type.opcode == jalr_opcode && !(instr.i_type.funct3 == 3'b000));
    illegal_bins LOAD_FUNCT3 = funct3_cross with (instr.i_type.opcode == load_opcode && !(instr.i_type.funct3 inside {lb_funct3, lh_funct3, lw_funct3, lbu_funct3, lhu_funct3}));
    illegal_bins STORE_FUNCT3 = funct3_cross with (instr.i_type.opcode == store_opcode && !(instr.i_type.funct3 inside {sw_funct3, sb_funct3, sh_funct3}));
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
    (!(instr.r_type.opcode inside {reg_opcode, imm_opcode}));

    // TODO: Get rid of all the other cases where funct7 isn't necessary, or cannot
    // take on certain values.
    ignore_bins I_TYPE_FUNCT3_CAUSE = funct7_cross with (instr.r_type.opcode == imm_opcode && !(instr.r_type.funct3 inside {sr_funct3, sll_funct3}));

    illegal_bins R_FUNCT7_ILLEGAL_VARIANT = funct7_cross with (instr.r_type.opcode == reg_opcode && !(instr.r_type.funct3 inside {add_funct3, sr_funct3}) && instr.r_type.funct7 == variant_funct7);
    illegal_bins I_FUNCT7_ILLEGAL_VARIANT = funct7_cross with (instr.r_type.opcode == imm_opcode && (instr.r_type.funct3 == sll_alu_op) && instr.r_type.funct7 == variant_funct7);
  }

endgroup : instr_cg