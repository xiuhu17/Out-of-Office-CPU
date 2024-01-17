// This file will be replaced by the autograder.
module tb;
import rv32i_types::*;

  `include "../../hvl/randinst.svh"

  RandInst rg = new();

  int covered;
  int total;

  initial begin
    repeat (500) begin
      rg.randomize();
    end

    rg.instr_cg.all_opcodes.get_coverage(covered, total);
    $display("all_opcodes: %0d/%0d", covered, total);

    rg.instr_cg.all_funct7.get_coverage(covered, total);
    $display("all_funct7: %0d/%0d", covered, total);

    rg.instr_cg.all_funct3.get_coverage(covered, total);
    $display("all_funct3: %0d/%0d", covered, total);

    rg.instr_cg.all_regs_rs1.get_coverage(covered, total);
    $display("all_regs_rs1: %0d/%0d", covered, total);

    rg.instr_cg.all_regs_rs2.get_coverage(covered, total);
    $display("all_regs_rs2: %0d/%0d", covered, total);

    rg.instr_cg.funct3_cross.get_coverage(covered, total);
    $display("funct3_cross: %0d/%0d", covered, total);

    rg.instr_cg.funct7_cross.get_coverage(covered, total);
    $display("funct7_cross: %0d/%0d", covered, total);
  end

endmodule : tb
