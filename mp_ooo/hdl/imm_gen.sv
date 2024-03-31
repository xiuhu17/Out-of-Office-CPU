module imm_gen
  import rv32i_types::*;
(
    input  logic [ 6:0] opcode,
    input  logic [31:0] i_imm,
    input  logic [31:0] s_imm,
    input  logic [31:0] b_imm,
    input  logic [31:0] u_imm,
    input  logic [31:0] j_imm,
    output logic [31:0] imm
);

  always_comb begin
    unique case (opcode)
      op_b_jalr, op_b_imm, op_b_load: imm = i_imm;
      op_b_store: imm = s_imm;
      op_b_br: imm = b_imm;
      op_b_lui, op_b_auipc: imm = u_imm;
      op_b_jal: imm = j_imm;
      default: imm = 'h0;
    endcase
  end

endmodule
