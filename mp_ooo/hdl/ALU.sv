module alu
  import rv32i_types::*;
(
    input  logic [ 2:0] aluop,
    input  logic [31:0] a,
    b,
    output logic [31:0] f
);

  logic signed   [31:0] as;
  logic signed   [31:0] bs;
  logic unsigned [31:0] au;
  logic unsigned [31:0] bu;

  assign as = signed'(a);
  assign bs = signed'(b);
  assign au = unsigned'(a);
  assign bu = unsigned'(b);

  always_comb begin
    unique case (aluop)
      add_alu_op: f = au + bu;
      sll_alu_op: f = au << bu[4:0];
      sra_alu_op: f = unsigned'(as >>> bu[4:0]);
      sub_alu_op: f = au - bu;
      xor_alu_op: f = au ^ bu;
      srl_alu_op: f = au >> bu[4:0];
      or_alu_op: f = au | bu;
      and_alu_op: f = au & bu;
      default: f = 'x;
    endcase
  end

endmodule : alu
