module decode
  import rv32i_types::*;
(
    input  logic [31:0] inst,
    output logic [ 2:0] funct3,
    output logic [ 6:0] funct7,
    output logic [ 6:0] opcode,
    output logic [31:0] imm,
    output logic [ 4:0] rs1_s,
    output logic [ 4:0] rs2_s,
    output logic [ 4:0] rd_s
);

  always_comb begin
    funct3 = inst[14:12];
    funct7 = inst[31:25];
    opcode = inst[6:0];
    rs1_s  = inst[19:15];
    rs2_s  = inst[24:20];
    rd_s   = inst[11:7];
    unique case (opcode)
      jalr_opcode, imm_opcode, load_opcode: imm = {{21{inst[31]}}, inst[30:20]};
      store_opcode: imm = {{21{inst[31]}}, inst[30:25], inst[11:7]};
      br_opcode: imm = {{20{inst[31]}}, inst[7], inst[30:25], inst[11:8], 1'b0};
      lui_opcode, auipc_opcode: imm = {inst[31:12], 12'h000};
      jal_opcode: imm = {{12{inst[31]}}, inst[19:12], inst[20], inst[30:21], 1'b0};
      default: imm = 'h0;
    endcase
  end

endmodule : decode
