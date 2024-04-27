module issue
  import rv32i_types::*;
#(
    parameter ROB_DEPTH = 4
) (
    // instruction queue variables
    input logic instr_valid,
    input logic instr_ready,
    input logic [6:0] opcode,
    input logic [6:0] funct7,
    // reservation station variables
    input logic alu_rs_full,
    input logic muldiv_rs_full,
    input logic branch_rs_full,
    input logic load_rs_full,
    input logic store_rs_full,
    // rob is available
    input logic rob_full,
    // output signals
    // instruction queue
    output logic instr_pop,
    // reservation stations
    output logic alu_rs_issue,
    output logic muldiv_rs_issue,
    output logic branch_rs_issue,
    output logic load_rs_issue,
    output logic store_rs_issue,
    // ROB
    output logic rob_push,
    // scoreboard
    output logic issue_valid
);

  always_comb begin
    instr_pop = '0;
    alu_rs_issue = '0;
    muldiv_rs_issue = '0;
    branch_rs_issue = '0;
    load_rs_issue = '0;
    store_rs_issue = '0;
    rob_push = '0;
    issue_valid = '0;
    if (!rob_full) begin
      if (instr_valid && instr_ready) begin
        if (!alu_rs_full) begin
          if (opcode == lui_opcode || opcode == auipc_opcode || opcode == imm_opcode || (opcode == reg_opcode && funct7 != multiply_funct7)) begin
            // pop from instruction queue
            instr_pop = '1;
            // issue to the alu reservation station
            alu_rs_issue = '1;
            // update ROB
            rob_push = '1;
            // update scoreboard
            issue_valid = '1;
          end
        end
        if (!muldiv_rs_full) begin
          if (opcode == reg_opcode && funct7 == multiply_funct7) begin
            // pop from instruction queue
            instr_pop = '1;
            // issue to the mul reservation station
            muldiv_rs_issue = '1;
            // update ROB
            rob_push = '1;
            // update scoreboard
            issue_valid = '1;
          end
        end
        if (!branch_rs_full) begin
          if (opcode == br_opcode || opcode == jal_opcode || opcode == jalr_opcode) begin
            // pop from instruction queue
            instr_pop = '1;
            // issue to the branch reservation station
            branch_rs_issue = '1;
            // update ROB
            rob_push = '1;
            // update scoreboard
            issue_valid = '1;
          end
        end
        if (!load_rs_full) begin
          if (opcode == load_opcode) begin
            // pop from instruction queue
            instr_pop = '1;
            // issue to the load reservation station
            load_rs_issue = '1;
            // update ROB
            rob_push = '1;
            // update scoreboard
            issue_valid = '1;
          end
        end
        if (!store_rs_full) begin
          if (opcode == store_opcode) begin
            // pop from instruction queue
            instr_pop = '1;
            // issue to the store reservation station
            store_rs_issue = '1;
            // update ROB
            rob_push = '1;
            // update scoreboard
            issue_valid = '1;
          end
        end
      end
    end
  end

endmodule
