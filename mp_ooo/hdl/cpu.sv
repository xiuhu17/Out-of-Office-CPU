module cpu
  import rv32i_types::*;
#(
    parameter INSTR_DEPTH = 4,
    parameter ALU_RS_DEPTH = 3,
    parameter MUL_RS_DEPTH = 3,
    parameter BRANCH_RS_DEPTH = 3,
    parameter ROB_DEPTH = 4,
    parameter CDB_SIZE = 3
) (
    // Explicit dual port connections when caches are not integrated into design yet (Before CP3)
    input logic clk,
    input logic rst,

    // output logic [31:0] imem_addr,
    // output logic [ 3:0] imem_rmask,
    // input  logic [31:0] imem_rdata,
    // input  logic        imem_resp,

    // output logic [31:0] dmem_addr,
    // output logic [ 3:0] dmem_rmask,
    // output logic [ 3:0] dmem_wmask,
    // input  logic [31:0] dmem_rdata,
    // output logic [31:0] dmem_wdata,
    // input  logic        dmem_resp

    // Single memory port connection when caches are integrated into design (CP3 and after)
    output logic [31:0] bmem_addr,
    output logic        bmem_read,
    output logic        bmem_write,
    output logic [63:0] bmem_wdata,
    input  logic        bmem_ready,

    input logic [31:0] bmem_raddr,
    input logic [63:0] bmem_rdata,
    input logic        bmem_rvalid
);
  // instruction cache variables
  logic [         31:0] instr_cache_addr;
  logic [          3:0] instr_cache_rmask;
  logic [          3:0] instr_cache_wmask;
  logic [         31:0] instr_cache_wdata;
  logic [         31:0] instr_cache_rdata;
  logic                 instr_cache_resp;

  // fetch fsm
  logic                 imem_rqst;

  // fetch variables
  logic                 move_fetch;
  logic                 move_flush;
  logic [         63:0] order;
  logic [         31:0] pc;
  logic [         31:0] pc_next;

  // instruction queue variables
  logic                 instr_full;
  logic                 instr_valid;
  logic                 instr_ready;
  logic                 instr_push;
  logic                 instr_pop;
  logic [         31:0] fetch_instr;
  logic [         63:0] fetch_order;
  logic [         63:0] issue_order;
  logic [         31:0] issue_instr;
  logic [         31:0] issue_pc;
  logic [         31:0] issue_pc_next;
  logic [          2:0] issue_funct3;
  logic [          6:0] issue_funct7;
  logic [          6:0] issue_opcode;
  logic [         31:0] issue_imm;
  logic [          4:0] issue_rs1_s;
  logic [          4:0] issue_rs2_s;
  logic [          4:0] issue_rd_s;

  // alu_rs variables
  logic                 alu_rs_full;
  logic                 alu_rs_issue;
  logic                 cdb_alu_rs_valid;
  logic [         31:0] cdb_alu_rs_f;
  logic [ROB_DEPTH-1:0] cdb_alu_rs_rob;

  // mul_rs variables
  logic                 mul_rs_full;
  logic                 mul_rs_issue;
  logic                 cdb_mul_rs_valid;
  logic [         31:0] cdb_mul_rs_p;
  logic [ROB_DEPTH-1:0] cdb_mul_rs_rob;

  // branch_rs variables
  logic                 branch_rs_full;
  logic                 branch_rs_issue;
  logic                 cdb_branch_rs_valid;
  logic [         31:0] cdb_branch_rs_v;
  logic [ROB_DEPTH-1:0] cdb_branch_rs_rob;
  logic                 cdb_branch_take;
  logic [         31:0] cdb_branch_pc;

  // CDB variables
  logic                 exe_valid           [CDB_SIZE];
  logic [         31:0] exe_alu_f           [CDB_SIZE];
  logic [ROB_DEPTH-1:0] exe_rob             [CDB_SIZE];
  logic                 cdb_valid           [CDB_SIZE];
  logic [         31:0] cdb_rd_v            [CDB_SIZE];
  logic [ROB_DEPTH-1:0] cdb_rob             [CDB_SIZE];
  always_comb begin
    exe_valid[0] = cdb_alu_rs_valid;
    exe_valid[1] = cdb_mul_rs_valid;
    exe_valid[2] = cdb_branch_rs_valid;
    exe_alu_f[0] = cdb_alu_rs_f;
    exe_alu_f[1] = cdb_mul_rs_p;
    exe_alu_f[2] = cdb_branch_rs_v;
    exe_rob[0]   = cdb_alu_rs_rob;
    exe_rob[1]   = cdb_mul_rs_rob;
    exe_rob[2]   = cdb_branch_rs_rob;
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
  logic [6:0] commit_opcode;
  logic [4:0] rvfi_rs1_s_tail;
  logic [4:0] rvfi_rs2_s_tail;
  logic flush_branch;
  logic [31:0] pc_branch;
  logic [63:0] order_branch;




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


  fetch_fsm fetch_fsm (
      .clk(clk),
      .rst(rst),
      .imem_resp(imem_resp),
      .imem_rqst(imem_rqst),
      .instr_full(instr_full),
      .move_flush(move_flush),
      .move_fetch(move_fetch)
  );

  flush_fsm flush_fsm (
      .clk(clk),
      .rst(rst),
      .imem_resp(imem_resp),
      .imem_rqst(imem_rqst),
      .rob_valid(rob_valid),
      .rob_ready(rob_ready),
      .flush_branch(flush_branch),
      .move_flush(move_flush)
  );

  fetch fetch (
      .clk(clk),
      .rst(rst),
      .move_fetch(move_fetch),
      .move_flush(move_flush),
      .pc_branch(pc_branch),
      .order_branch(order_branch),
      .imem_addr(imem_addr),
      .imem_rmask(imem_rmask),
      .imem_rqst(imem_rqst),
      .pc(pc),
      .order(order),
      .pc_next(pc_next)
  );

  cache instruction_cache (
      .clk(clk),
      .rst(rst),
      .ufp_addr(instr_cache_addr),
      .ufp_rmask(instr_cache_rmask),
      .ufp_wmask(instr_cache_wmask),
      .ufp_rdata(instr_cache_rdata),
      .ufp_wdata(instr_cache_wdata),
      .ufp_resp(instr_cache_resp),
      .dfp_addr(bmem_addr),
      .dfp_read(bmem_read),
      .dfp_write(bmem_write),
      .dfp_wdata(bmem_wdata),
      .dfp_ready(bmem_ready),
      .dfp_rdata(bmem_rdata),
      .dfp_resp(bmem_rvalid)
  );

  instruction_queue #(
      .INSTR_DEPTH(INSTR_DEPTH)
  ) instruction_queue (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .instr_full(instr_full),
      .instr_valid(instr_valid),
      .instr_ready(instr_ready),
      .move_fetch(move_fetch),
      .imem_resp(imem_resp),
      .instr_pop(instr_pop),
      .imem_rdata(imem_rdata),
      .fetch_order(order),
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
      .branch_rs_full(branch_rs_full),
      .rob_full(rob_full),
      .instr_pop(instr_pop),
      .alu_rs_issue(alu_rs_issue),
      .mul_rs_issue(mul_rs_issue),
      .branch_rs_issue(branch_rs_issue),
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
      .move_flush(move_flush),
      .alu_rs_full(alu_rs_full),
      .alu_rs_issue(alu_rs_issue),
      .issue_opcode(issue_opcode),
      .issue_funct3(issue_funct3),
      .issue_funct7(issue_funct7),
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
      .issue_imm(issue_imm),
      .issue_pc(issue_pc),
      .issue_target_rob(issue_rob),
      .cdb_alu_rs_valid(cdb_alu_rs_valid),
      .cdb_alu_rs_f(cdb_alu_rs_f),
      .cdb_alu_rs_rob(cdb_alu_rs_rob)
  );

  mul_rs #(
      .MUL_RS_DEPTH(MUL_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) mul_rs (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .mul_rs_full(mul_rs_full),
      .mul_rs_issue(mul_rs_issue),
      .issue_opcode(issue_opcode),
      .issue_funct3(issue_funct3),
      .issue_funct7(issue_funct7),
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
      .cdb_mul_rs_valid(cdb_mul_rs_valid),
      .cdb_mul_rs_p(cdb_mul_rs_p),
      .cdb_mul_rs_rob(cdb_mul_rs_rob)
  );

  branch_rs #(
      .BRANCH_RS_DEPTH(BRANCH_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) branch_rs (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .branch_rs_full(branch_rs_full),
      .branch_rs_issue(branch_rs_issue),
      .issue_opcode(issue_opcode),
      .issue_funct3(issue_funct3),
      .issue_imm(issue_imm),
      .issue_pc(issue_pc),
      .issue_target_rob(issue_rob),
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
      .cdb_branch_rs_valid(cdb_branch_rs_valid),
      .cdb_branch_rs_v(cdb_branch_rs_v),
      .cdb_branch_rs_rob(cdb_branch_rs_rob),
      .cdb_branch_take(cdb_branch_take),
      .cdb_branch_pc(cdb_branch_pc)
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
      .move_flush(move_flush),
      .rob_full(rob_full),
      .rob_valid(rob_valid),
      .rob_ready(rob_ready),
      .cdb_valid(cdb_valid),
      .cdb_rob(cdb_rob),
      .cdb_rd_v(cdb_rd_v),
      .cdb_branch_take(cdb_branch_take),
      .cdb_branch_pc(cdb_branch_pc),
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
      .commit_opcode(commit_opcode),
      .flush_branch(flush_branch),
      .pc_branch(pc_branch),
      .order_branch(order_branch),
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
      .move_flush(move_flush),
      .commit_regfile_we(commit_regfile_we),
      .commit_rd_s(commit_rd_s),
      .commit_rd_v(commit_rd_v),
      .commit_rob(commit_rob),
      .issue_valid(issue_valid),
      .issue_opcode(issue_opcode),
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
      .commit_opcode(commit_opcode),
      .flush_branch(flush_branch),
      .move_flush(move_flush),
      .rob_pop(rob_pop),
      .commit_regfile_we(commit_regfile_we)
  );

endmodule : cpu
