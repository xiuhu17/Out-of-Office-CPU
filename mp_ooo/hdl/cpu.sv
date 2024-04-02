module cpu
  import rv32i_types::*;
#(
    parameter INSTR_DEPTH = 4,
    parameter ALU_RS_DEPTH = 3,
    parameter MUL_RS_DEPTH = 3,
    parameter ROB_DEPTH = 4,
    parameter CDB_SIZE = 2
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
  logic move_fetch;
  logic [63:0] order_curr;
  logic take_branch;
  logic [31:0] pc;
  logic [31:0] pc_next;

  // instruction queue variables
  logic instr_full;
  logic instr_valid;
  logic instr_ready;
  logic instr_push;
  logic instr_pop;
  logic [31:0] fetch_instr;
  logic [63:0] fetch_order;
  logic [63:0] issue_order;
  logic [31:0] issue_instr;
  logic [31:0] issue_pc;
  logic [31:0] issue_pc_next;
  logic [2:0] issue_funct3;
  logic [6:0] issue_funct7;
  logic [6:0] issue_opcode;
  logic [31:0] issue_imm;
  logic [4:0] issue_rs1_s;
  logic [4:0] issue_rs2_s;
  logic [4:0] issue_rd_s;

  // alu_rs variables
  logic alu_rs_full;
  logic alu_rs_issue;
  logic alu_rs_valid;
  logic [31:0] alu_rs_f;
  logic [ROB_DEPTH-1:0] alu_rs_rob;

  // mul_rs variables
  logic mul_rs_full;
  logic mul_rs_issue;
  logic mul_rs_valid;
  logic [31:0] mul_rs_p;
  logic [ROB_DEPTH-1:0] mul_rs_rob;

  // CDB variables
  logic exe_valid[CDB_SIZE];
  logic [31:0] exe_alu_f[CDB_SIZE];
  logic [ROB_DEPTH-1:0] exe_rob[CDB_SIZE];
  logic cdb_valid[CDB_SIZE];
  logic [31:0] cdb_rd_v[CDB_SIZE];
  logic [ROB_DEPTH-1:0] cdb_rob[CDB_SIZE];
  always_comb begin
    exe_valid[0] = alu_rs_valid;
    exe_valid[1] = mul_rs_valid;
    exe_alu_f[0] = alu_rs_f;
    exe_alu_f[1] = mul_rs_p;
    exe_rob[0]   = alu_rs_rob;
    exe_rob[1]   = mul_rs_rob;
  end

  // ROB variables
  logic rob_full;
  logic rob_valid;
  logic rob_ready;
  logic rob_push;
  logic [ROB_DEPTH-1:0] issue_rob;
  logic [ROB_DEPTH - 1:0] issue_rs1_rob;
  logic [ROB_DEPTH - 1:0] issue_rs2_rob;
  logic [31:0] issue_rs1_rob_v;
  logic [31:0] issue_rs2_rob_v;
  logic issue_rs1_rob_ready;
  logic issue_rs2_rob_ready;
  logic rob_pop;
  logic [4:0] commit_rd_s;
  logic [31:0] commit_rd_v;
  logic [ROB_DEPTH-1:0] commit_rob;
  logic [4:0] rvfi_rs1_s_tail;
  logic [4:0] rvfi_rs2_s_tail;

  // regfile_scoreboard variables
  logic commit_regfile_we;
  logic issue_valid;
  logic [4:0] issue_rs_1;
  logic [4:0] issue_rs_2;
  logic [31:0] issue_rs1_regfile_v;
  logic [31:0] issue_rs2_regfile_v;
  logic issue_rs1_regfile_ready;
  logic issue_rs2_regfile_ready;
  logic [ROB_DEPTH-1:0] issue_rs1_regfile_rob;
  logic [ROB_DEPTH-1:0] issue_rs2_regfile_rob;


    fetch_fsm fetch_fsm(
        .instr_full(instr_full),
        .move_fetch(move_fetch)
    );

  fetch fetch (
      .clk(clk),
      .rst(rst),
      .move_fetch(move_fetch),
      .take_branch('0),
      .pc_branch('0),
      .imem_addr(imem_addr),
      .imem_rmask(imem_rmask),
      .order_curr(order_curr),
      .pc(pc),
      .pc_next(pc_next)
  );

  instruction_queue #(
      .INSTR_DEPTH(INSTR_DEPTH)
  ) instruction_queue (
      .clk(clk),
      .rst(rst),
      .instr_full(instr_full),
      .instr_valid(instr_valid),
      .instr_ready(instr_ready),
      .move_fetch(move_fetch),
      .imem_resp(imem_resp),
      .instr_pop(instr_pop),
      .imem_rdata(imem_rdata),
      .fetch_order(order_curr),
      .fetch_pc(pc),
      .issue_order(issue_order),
      .issue_instr(issue_instr),
      .issue_pc(issue_pc),
      .issue_pc_next(issue_pc_next),
      .issue_funct3(issue_funct3),
      .issue_funct7(issue_funct7),
      .issue_opcode(issue_opcode),
      .issue_imm(issue_imm),
      .issue_rs1_s(issue_rs1_s),
      .issue_rs2_s(issue_rs2_s),
      .issue_rd_s(issue_rd_s)
  );

  issue #(
      .ROB_DEPTH(ROB_DEPTH)
  ) issue (
      .instr_valid(instr_valid),
      .instr_ready(instr_ready),
      .opcode(issue_opcode),
      .funct7(issue_funct7),
      .alu_rs_full(alu_rs_full),
      .mul_rs_full(mul_rs_full),
      .rob_full(rob_full),
      .instr_pop(instr_pop),
      .alu_rs_issue(alu_rs_issue),
      .mul_rs_issue(mul_rs_issue),
      .rob_push(rob_push),
      .issue_valid(issue_valid)
  );

  alu_rs #(
      .ALU_RS_DEPTH(ALU_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) alu_rs (
      .clk(clk),
      .rst(rst),
      .alu_rs_full(alu_rs_full),
      .alu_rs_issue(alu_rs_issue),
      .opcode(issue_opcode),
      .funct3(issue_funct3),
      .funct7(issue_funct7),
      .issue_rs1_regfile_ready(issue_rs1_regfile_ready),
      .issue_rs2_regfile_ready(issue_rs2_regfile_ready),
      .issue_rs1_regfile_v(issue_rs1_regfile_v),
      .issue_rs2_regfile_v(issue_rs2_regfile_v),
      .issue_rs1_regfile_rob(issue_rs1_regfile_rob),
      .issue_rs2_regfile_rob(issue_rs2_regfile_rob),
      .issue_rs1_rob_ready(issue_rs1_rob_ready),
      .issue_rs2_rob_ready(issue_rs2_rob_ready),
      .issue_rs1_rob_v(issue_rs1_rob_v),
      .issue_rs2_rob_v(issue_rs2_rob_v),
      .cdb_valid(cdb_valid),
      .cdb_rob(cdb_rob),
      .cdb_rd_v(cdb_rd_v),
      .imm(issue_imm),
      .pc(issue_pc),
      .issue_target_rob(issue_rob),
      .alu_rs_valid(alu_rs_valid),
      .alu_rs_f(alu_rs_f),
      .alu_rs_rob(alu_rs_rob)
  );

  mul_rs #(
      .MUL_RS_DEPTH(MUL_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) mul_rs (
      .clk(clk),
      .rst(rst),
      .mul_rs_full(mul_rs_full),
      .mul_rs_issue(mul_rs_issue),
      .opcode(issue_opcode),
      .funct3(issue_funct3),
      .funct7(issue_funct7),
      .issue_rs1_regfile_ready(issue_rs1_regfile_ready),
      .issue_rs2_regfile_ready(issue_rs2_regfile_ready),
      .issue_rs1_regfile_v(issue_rs1_regfile_v),
      .issue_rs2_regfile_v(issue_rs2_regfile_v),
      .issue_rs1_regfile_rob(issue_rs1_regfile_rob),
      .issue_rs2_regfile_rob(issue_rs2_regfile_rob),
      .issue_rs1_rob_ready(issue_rs1_rob_ready),
      .issue_rs2_rob_ready(issue_rs2_rob_ready),
      .issue_rs1_rob_v(issue_rs1_rob_v),
      .issue_rs2_rob_v(issue_rs2_rob_v),
      .cdb_valid(cdb_valid),
      .cdb_rob(cdb_rob),
      .cdb_rd_v(cdb_rd_v),
      .issue_target_rob(issue_rob),
      .mul_rs_valid(mul_rs_valid),
      .mul_rs_p(mul_rs_p),
      .mul_rs_rob(mul_rs_rob)
  );

  CDB #(
      .CDB_SIZE (CDB_SIZE),
      .ROB_DEPTH(ROB_DEPTH)
  ) CDB (
      .exe_valid(exe_valid),
      .exe_alu_f(exe_alu_f),
      .exe_rob  (exe_rob),
      .cdb_valid(cdb_valid),
      .cdb_rob  (cdb_rob),
      .cdb_rd_v (cdb_rd_v)
  );

  ROB #(
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE (CDB_SIZE)
  ) ROB (
      .clk(clk),
      .rst(rst),
      .rob_full(rob_full),
      .rob_valid(rob_valid),
      .rob_ready(rob_ready),
      .cdb_valid(cdb_valid),
      .cdb_rob(cdb_rob),
      .cdb_rd_v(cdb_rd_v),
      .rob_push(rob_push),
      .issue_rd_s(issue_rd_s),
      .issue_rob(issue_rob),
      .issue_rs1_rob(issue_rs1_regfile_rob),  // read from regfile_scoreboard
      .issue_rs2_rob(issue_rs2_regfile_rob),
      .issue_rs1_rob_v(issue_rs1_rob_v),
      .issue_rs2_rob_v(issue_rs2_rob_v),
      .issue_rs1_rob_ready(issue_rs1_rob_ready),
      .issue_rs2_rob_ready(issue_rs2_rob_ready),
      .rob_pop(rob_pop),
      .commit_rd_s(commit_rd_s),
      .commit_rd_v(commit_rd_v),
      .commit_rob(commit_rob),
      .rvfi_order(issue_order),
      .rvfi_inst(issue_instr),
      .rvfi_rs1_s(issue_rs1_s),
      .rvfi_rs2_s(issue_rs2_s),
      .rvfi_rd_s(issue_rd_s),
      .rvfi_pc(issue_pc),
      .rvfi_pc_next(issue_pc_next),
      .rvfi_rs1_s_tail(rvfi_rs1_s_tail),
      .rvfi_rs2_s_tail(rvfi_rs2_s_tail)
  );

  regfile_scoreboard #(
      .ROB_DEPTH(ROB_DEPTH)
  ) regfile_scoreboard (
      .clk(clk),
      .rst(rst),
      .commit_regfile_we(commit_regfile_we),
      .commit_rd_s(commit_rd_s),
      .commit_rd_v(commit_rd_v),
      .commit_rob(commit_rob),
      .issue_valid(issue_valid),
      .issue_rd_s(issue_rd_s),
      .issue_rob(issue_rob),
      .issue_rs1_s(issue_rs1_s),
      .issue_rs2_s(issue_rs2_s),
      .issue_rs1_regfile_v(issue_rs1_regfile_v),
      .issue_rs2_regfile_v(issue_rs2_regfile_v),
      .issue_rs1_regfile_ready(issue_rs1_regfile_ready),
      .issue_rs2_regfile_ready(issue_rs2_regfile_ready),
      .issue_rs1_regfile_rob(issue_rs1_regfile_rob),
      .issue_rs2_regfile_rob(issue_rs2_regfile_rob),
      .rvfi_rs1_s_tail(rvfi_rs1_s_tail),
      .rvfi_rs2_s_tail(rvfi_rs2_s_tail)
  );

  commit commit (
      .rob_valid(rob_valid),
      .rob_ready(rob_ready),
      .rob_pop(rob_pop),
      .commit_regfile_we(commit_regfile_we)
  );

endmodule : cpu
