module cmp
  import rv32i_types::*;
(
    input  logic [ 2:0] cmpop,
    input  logic [31:0] a,
    b,
    output logic        br_en
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
    unique case (cmpop)
      beq_cmp_op: br_en = (au == bu);
      bne_cmp_op: br_en = (au != bu);
      blt_cmp_op: br_en = (as < bs);
      bge_cmp_op: br_en = (as >= bs);
      bltu_cmp_op: br_en = (au < bu);
      bgeu_cmp_op: br_en = (au >= bu);
      default: br_en = 1'bx;
    endcase
  end

endmodule : cmp
