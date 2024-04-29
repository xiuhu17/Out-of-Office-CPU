module ir (
    input  logic [31:0] inst,
    output logic [ 2:0] funct3,
    output logic [ 6:0] funct7,
    output logic [ 6:0] opcode,
    output logic [31:0] i_imm,
    output logic [31:0] s_imm,
    output logic [31:0] b_imm,
    output logic [31:0] u_imm,
    output logic [31:0] j_imm,
    output logic [ 4:0] rs1_s,
    output logic [ 4:0] rs2_s,
    output logic [ 4:0] rd_s
);

  assign funct3 = inst[14:12];
  assign funct7 = inst[31:25];
  assign opcode = inst[6:0];
  assign i_imm  = {{21{inst[31]}}, inst[30:20]};
  assign s_imm  = {{21{inst[31]}}, inst[30:25], inst[11:7]};
  assign b_imm  = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
  assign u_imm  = {inst[31:12], 12'h000};
  assign j_imm  = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
  assign rs1_s  = inst[19:15];
  assign rs2_s  = inst[24:20];
  assign rd_s   = inst[11:7];

endmodule : ir
