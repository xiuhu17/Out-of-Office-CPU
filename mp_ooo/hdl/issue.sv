module issue
  import rv32i_types::*;
(
    // instruction queue variables
    input logic instr_valid_out,
    input logic [6:0] opcode,
    input logic [6:0] funct7,
    // reservation station variables
    input logic alu_rs_full,
    input logic mul_rs_full,
    // rob is available
    input logic rob_full,
    // output signals
    output logic instr_pop,
    output logic alu_rs_issue,
    output logic mul_rs_issue
);

  always_comb begin
    instr_pop = '0;
    alu_rs_issue = '0;
    if (!rob_full) begin
      if (instr_valid_out) begin
        if (!alu_rs_full) begin 
          if (opcode == lui_opcode || opcode == auipc_opcode || opcode == imm_opcode || (opcode == reg_opcode && funct7 != multiply_funct7)) begin
            alu_rs_issue = '1;
            instr_pop = '1;
          end
        end
        if (!mul_rs_full) begin 
          if (opcode == reg_opcode && funct7 == multiply_funct7) begin 
            mul_rs_issue = '1;
            instr_pop = '1;
          end 
        end 
      end
    end
  end

endmodule
