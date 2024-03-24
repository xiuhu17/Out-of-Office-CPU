module cpu
  import rv32i_types::*;
#(
    parameter SUPERSCALAR = 1
) (
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input logic clk,
    input logic rst,

    output logic [31:0] imem_addr,
    output logic [ 3:0] imem_rmask,
    input  logic [31:0] imem_rdata,
    input  logic        imem_resp,

    output logic [31:0] dmem_addr,
    output logic [ 3:0] dmem_rmask,
    output logic [ 3:0] dmem_wmask,
    input  logic [31:0] dmem_rdata,
    output logic [31:0] dmem_wdata,
    input  logic        dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)
    /*
    output  logic   [31:0]  bmem_addr,
    output  logic           bmem_read,
    output  logic           bmem_write,
    input   logic   [255:0] bmem_rdata,
    output  logic   [255:0] bmem_wdata,
    input   logic           bmem_resp
    */
);
  // this block is for tricking the compiler
  always_comb begin
    dmem_addr  = '0;
    dmem_rmask = '0;
    dmem_wmask = dmem_resp ? 4'h1 : 4'h0;
    dmem_wdata = dmem_rdata;
  end

  // fetch variables
  logic [63:0] order_curr;
  logic take_branch;

  // instruction queue variables
  logic instr_pop[SUPERSCALAR];
  logic [SUPERSCALAR*32-1:0] instr_in;
  logic instr_full;
  logic instr_valid_out[SUPERSCALAR];
  logic [31:0] instr[SUPERSCALAR];
  logic [2:0] funct3[SUPERSCALAR];
  logic [6:0] funct7[SUPERSCALAR];
  logic [6:0] opcode[SUPERSCALAR];
  logic [31:0] i_imm[SUPERSCALAR];
  logic [31:0] s_imm[SUPERSCALAR];
  logic [31:0] b_imm[SUPERSCALAR];
  logic [31:0] u_imm[SUPERSCALAR];
  logic [31:0] j_imm[SUPERSCALAR];
  logic [4:0] rs1_s[SUPERSCALAR];
  logic [4:0] rs2_s[SUPERSCALAR];
  logic [4:0] rd_s[SUPERSCALAR];


  fetch #(
      .SUPERSCALAR(SUPERSCALAR)
  ) fetch (
      .clk(clk),
      .rst(rst),
      .fetch_stall(instr_full),  // TODO: use FSM to control stall
      .take_branch('0),
      .pc_branch('0),
      .imem_addr(imem_addr),
      .imem_rmask(imem_rmask),
      .order_curr(order_curr)
  );

  instruction_queue #(
      .DEPTH(4),
      .SUPERSCALAR(SUPERSCALAR)
  ) instruction_queue (
      .clk(clk),
      .rst(rst),
      .instr_push(imem_resp),
      .instr_pop({'0}),
      .instr_in(imem_rdata),
      .instr_full(instr_full),
      .instr_valid_out(instr_valid_out),
      .instr(instr),
      .funct3(funct3),
      .funct7(funct7),
      .opcode(opcode),
      .i_imm(i_imm),
      .s_imm(s_imm),
      .b_imm(b_imm),
      .u_imm(u_imm),
      .j_imm(j_imm),
      .rs1_s(rs1_s),
      .rs2_s(rs2_s),
      .rd_s(rd_s)
  );

endmodule : cpu
