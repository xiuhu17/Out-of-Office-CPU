module ALU
  import rv32i_types::*;
(
    input  logic [ 3:0] aluop,
    input  logic [31:0] a,
    input  logic [31:0] b,
    output logic [31:0] f,

    input  logic start,
    output logic done
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
      alu_add:  f = unsigned'(as + bs);
      alu_sub:  f = unsigned'(as - bs);
      alu_sll:  f = au << bu[4:0];
      alu_slt:  f = {31'b0, as < bs};
      alu_sltu: f = {31'b0, au < bu};
      alu_xor:  f = au ^ bu;
      alu_srl:  f = au >> bu[4:0];
      alu_sra:  f = unsigned'(as >>> bu[4:0]);
      alu_or:   f = au | bu;
      alu_and:  f = au & bu;
      alu_lui:  f = b;
      alu_jalr: f = (a + b) & 32'hfffffffe;
      default:  f = 'x;
    endcase
  end

  assign done = start;

endmodule : alu
