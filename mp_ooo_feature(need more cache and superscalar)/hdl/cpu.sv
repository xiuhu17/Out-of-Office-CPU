module cpu
  import rv32i_types::*;
#(
    parameter INSTR_DEPTH = 4,
    parameter ALU_RS_DEPTH = 2,
    parameter MULDIV_RS_DEPTH = 2,
    parameter BRANCH_RS_DEPTH = 2,
    parameter LOAD_RS_DEPTH = 2,
    parameter STORE_RS_DEPTH = 2,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 4,
    parameter BTB_DEPTH = 2,
    parameter GHR_DEPTH = 30,
    parameter PHT_DEPTH = 6,
    parameter BIMODAL_DEPTH = 2,
    parameter STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH,
    parameter LOAD_RS_NUM_ELEM = 2 ** LOAD_RS_DEPTH,
    parameter STORE_RS_NUM_ELEM_1 = STORE_RS_NUM_ELEM + 1
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
  logic [              31:0] instr_cache_addr;
  logic [               3:0] instr_cache_rmask;
  logic [               3:0] instr_cache_wmask;
  logic [              31:0] instr_cache_wdata;
  logic [              31:0] instr_cache_rdata;
  logic                      instr_cache_resp;
  logic                      instr_cache_read_stage;
  logic [              31:0] instr_cache_bmem_addr;
  logic                      instr_cache_bmem_read;
  logic                      instr_cache_bmem_ready;

  // data cache variables
  logic [              31:0] data_cache_addr;
  logic [               3:0] data_cache_rmask;
  logic [               3:0] data_cache_wmask;
  logic [              31:0] data_cache_wdata;
  logic [              31:0] data_cache_rdata;
  logic                      data_cache_resp;
  logic                      data_cache_read_stage;
  logic                      data_cache_write_stage;
  logic [              31:0] data_cache_bmem_addr;
  logic                      data_cache_bmem_read;
  logic                      data_cache_bmem_write;
  logic [              63:0] data_cache_bmem_wdata;
  logic                      data_cache_bmem_ready;

  // fetch fsm
  logic                      imem_rqst;
  logic                      dmem_rqst;

  // fetch variables
  logic                      move_fetch;
  logic                      move_flush;
  logic [              63:0] order;
  logic [              31:0] pc;
  logic [              31:0] pc_next;

  // btb variables
  logic                      gshare_take;

  // instruction queue variables
  logic                      instr_full;
  logic                      instr_valid;
  logic                      instr_ready;
  logic                      instr_push;
  logic                      instr_pop;
  logic [              31:0] fetch_instr;
  logic [              63:0] fetch_order;
  logic [              63:0] issue_order;
  logic [              31:0] issue_instr;
  logic [              31:0] issue_pc;
  logic [              31:0] issue_pc_next;
  logic [               2:0] issue_funct3;
  logic [               6:0] issue_funct7;
  logic [               6:0] issue_opcode;
  logic [              31:0] issue_imm;
  logic [               4:0] issue_rs1_s;
  logic [               4:0] issue_rs2_s;
  logic [               4:0] issue_rd_s;

  // alu_rs variables
  logic                      alu_rs_full;
  logic                      alu_rs_issue;
  logic                      cdb_alu_rs_valid;
  logic [              31:0] cdb_alu_rs_f;
  logic [     ROB_DEPTH-1:0] cdb_alu_rs_rob;

  // muldiv_rs variables
  logic                      muldiv_rs_full;
  logic                      muldiv_rs_issue;
  logic                      cdb_muldiv_rs_valid;
  logic [              31:0] cdb_muldiv_rs_p;
  logic [     ROB_DEPTH-1:0] cdb_muldiv_rs_rob;

  // branch_rs variables
  logic                      branch_rs_full;
  logic                      branch_rs_issue;
  logic                      cdb_branch_rs_valid;
  logic [              31:0] cdb_branch_rs_v;
  logic [     ROB_DEPTH-1:0] cdb_branch_rs_rob;
  logic                      cdb_branch_take;
  logic [              31:0] cdb_branch_target_pc;

  // load_store_fsm
  logic                      arbiter_load_rs;
  logic                      arbiter_store_rs;
  logic                      dmem_r_rqst;
  logic                      dmem_w_rqst;

  // load_rs variales
  logic                      load_rs_full;
  logic                      load_rs_issue;
  logic                      load_rs_pop;
  logic                      cdb_load_rs_valid;
  logic [              31:0] cdb_load_rs_v;
  logic [     ROB_DEPTH-1:0] cdb_load_rs_rob;
  logic [               3:0] arbiter_load_rs_rmask;
  logic [              31:0] arbiter_load_rs_addr;
  logic [ LOAD_RS_DEPTH-1:0] load_rs_idx_rqst;
  logic [ LOAD_RS_DEPTH-1:0] load_rs_idx_executing;
  logic [               3:0] cdb_load_rs_rmask;
  logic [              31:0] cdb_load_rs_addr;
  logic [              31:0] cdb_load_rs_rdata;

  // store_rs variables
  logic                      store_rs_full;
  logic                      store_rs_issue;
  logic                      store_rs_pop;
  logic                      cdb_store_rs_valid;
  logic [     ROB_DEPTH-1:0] cdb_store_rs_rob;
  logic [               3:0] cdb_arbiter_store_rs_wmask;
  logic [              31:0] cdb_arbiter_store_rs_addr;
  logic [              31:0] cdb_arbiter_store_rs_wdata;
  logic [  STORE_RS_DEPTH:0] issue_store_rs_count;
//   logic [STORE_RS_DEPTH-1:0] issue_store_rs_head;
//   logic                      forward_wready             [STORE_RS_NUM_ELEM];
//   logic [              31:0] forward_waddr              [STORE_RS_NUM_ELEM];

  // CDB variables
  logic                      exe_valid                  [         CDB_SIZE];
  logic [              31:0] exe_alu_f                  [         CDB_SIZE];
  logic [     ROB_DEPTH-1:0] exe_rob                    [         CDB_SIZE];
  logic                      cdb_valid                  [         CDB_SIZE];
  logic [              31:0] cdb_rd_v                   [         CDB_SIZE];
  logic [     ROB_DEPTH-1:0] cdb_rob                    [         CDB_SIZE];

  always_comb begin
    exe_valid[0] = cdb_alu_rs_valid;
    exe_valid[1] = cdb_muldiv_rs_valid;
    exe_valid[2] = cdb_branch_rs_valid;
    exe_valid[3] = cdb_load_rs_valid;
    exe_alu_f[0] = cdb_alu_rs_f;
    exe_alu_f[1] = cdb_muldiv_rs_p;
    exe_alu_f[2] = cdb_branch_rs_v;
    exe_alu_f[3] = cdb_load_rs_v;
    exe_rob[0]   = cdb_alu_rs_rob;
    exe_rob[1]   = cdb_muldiv_rs_rob;
    exe_rob[2]   = cdb_branch_rs_rob;
    exe_rob[3]   = cdb_load_rs_rob;
  end

  // ROB variables
  logic rob_full;
  logic rob_valid;
  logic rob_ready;
  logic rob_push;
  logic [ROB_DEPTH-1:0] issue_rob;
  logic [ROB_DEPTH-1:0] rob_tail;
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
  logic [31:0] commit_pc;
  logic [4:0] rvfi_rs1_s_tail;
  logic [4:0] rvfi_rs2_s_tail;
  logic flush_branch;
  logic take_branch;
  logic [31:0] pc_branch_target;
  logic [63:0] order_branch_target;
  logic rob_store_in_flight;
  logic store_executing;

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
      .imem_resp(instr_cache_resp),
      .imem_rqst(imem_rqst),
      .instr_full(instr_full),
      .move_flush(move_flush),
      .rob_ready(rob_ready),
      .rob_valid(rob_valid),
      .flush_branch(flush_branch),
      .move_fetch(move_fetch)
  );

  flush_fsm flush_fsm (
      .clk(clk),
      .rst(rst),
      .imem_resp(instr_cache_resp),
      .imem_rqst(imem_rqst),
      .dmem_resp(data_cache_resp),
      .dmem_rqst(dmem_rqst),
      .rob_valid(rob_valid),
      .rob_ready(rob_ready),
      .flush_branch(flush_branch),
      .move_flush(move_flush)
  );


  btb #(
      .BTB_DEPTH(BTB_DEPTH)
  ) btb (
      .clk(clk),
      .rst(rst),
      .rob_pop(rob_pop),
      .take_branch(take_branch),
      .commit_opcode(commit_opcode),
      .commit_pc(commit_pc),
      .commit_pc_next(pc_branch_target),
      .gshare_take(gshare_take),
      .fetch_pc(pc),
      .fetch_pc_next(pc_next)
  );

  gshare #(
      .GHR_DEPTH(GHR_DEPTH),
      .PHT_DEPTH(PHT_DEPTH),
      .BIMODAL_DEPTH(BIMODAL_DEPTH)
  ) gshare (
      .clk(clk),
      .rst(rst),
      .rob_pop(rob_pop),
      .flush_branch(flush_branch),
      .take_branch(take_branch),
      .commit_opcode(commit_opcode),
      .commit_pc(commit_pc),
      .fetch_pc(pc),
      .gshare_take(gshare_take)
  );

  fetch fetch (
      .clk(clk),
      .rst(rst),
      .move_fetch(move_fetch),
      .move_flush(move_flush),
      .pc_branch_target(pc_branch_target),
      .order_branch_target(order_branch_target),
      .imem_addr(instr_cache_addr),
      .imem_rmask(instr_cache_rmask),
      .imem_rqst(imem_rqst),
      .pc(pc),
      .order(order),
      .pc_next(pc_next)
  );

  instr_cache instr_cache (
      .clk(clk),
      .rst(rst),
      .cpu_ufp_addr(instr_cache_addr),
      .cpu_ufp_rmask(instr_cache_rmask),
      .ufp_rdata(instr_cache_rdata),
      .ufp_resp(instr_cache_resp),
      .bfp_ready(instr_cache_bmem_ready),
      .bfp_rdata(bmem_rdata),
      .bfp_raddr(bmem_raddr),
      .bfp_rvalid(bmem_rvalid),
      .bfp_addr(instr_cache_bmem_addr),
      .bfp_read(instr_cache_bmem_read),
      .bfp_read_stage(instr_cache_read_stage)
  );

  data_cache data_cache (
      .clk(clk),
      .rst(rst),
      .cpu_ufp_addr(data_cache_addr),
      .cpu_ufp_rmask(data_cache_rmask),
      .cpu_ufp_wmask(data_cache_wmask),
      .ufp_rdata(data_cache_rdata),
      .cpu_ufp_wdata(data_cache_wdata),
      .ufp_resp(data_cache_resp),

      .bfp_ready(data_cache_bmem_ready),
      .bfp_rdata(bmem_rdata),
      .bfp_raddr(bmem_raddr),
      .bfp_rvalid(bmem_rvalid),
      .bfp_addr(data_cache_bmem_addr),
      .bfp_read(data_cache_bmem_read),
      .bfp_write(data_cache_bmem_write),
      .bfp_wdata(data_cache_bmem_wdata),
      .bfp_read_stage(data_cache_read_stage),
      .bfp_write_stage(data_cache_write_stage)
  );

  bmem_arbiter bmem_arbiter (
      .instr_cache_read_stage(instr_cache_read_stage),
      .instr_cache_bmem_addr(instr_cache_bmem_addr),
      .instr_cache_bmem_read(instr_cache_bmem_read),
      .data_cache_read_stage(data_cache_read_stage),
      .data_cache_write_stage(data_cache_write_stage),
      .data_cache_bmem_addr(data_cache_bmem_addr),
      .data_cache_bmem_read(data_cache_bmem_read),
      .data_cache_bmem_write(data_cache_bmem_write),
      .data_cache_bmem_wdata(data_cache_bmem_wdata),
      .bmem_ready(bmem_ready),
      .instr_cache_bmem_ready(instr_cache_bmem_ready),
      .data_cache_bmem_ready(data_cache_bmem_ready),
      .bmem_addr(bmem_addr),
      .bmem_read(bmem_read),
      .bmem_write(bmem_write),
      .bmem_wdata(bmem_wdata)
  );

  data_cache_arbiter data_cache_arbiter (
      .arbiter_load_rs(arbiter_load_rs),
      .arbiter_store_rs(arbiter_store_rs),
      .arbiter_load_rs_rmask(arbiter_load_rs_rmask),
      .arbiter_load_rs_addr(arbiter_load_rs_addr),
      .cdb_arbiter_store_rs_wmask(cdb_arbiter_store_rs_wmask),
      .cdb_arbiter_store_rs_addr(cdb_arbiter_store_rs_addr),
      .cdb_arbiter_store_rs_wdata(cdb_arbiter_store_rs_wdata),
      .dmem_rmask(data_cache_rmask),
      .dmem_wmask(data_cache_wmask),
      .dmem_addr(data_cache_addr),
      .dmem_wdata(data_cache_wdata)
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
      .imem_resp(instr_cache_resp),
      .instr_pop(instr_pop),
      .imem_rdata(instr_cache_rdata),
      .fetch_order(order),
      .fetch_pc(pc),
      .fetch_pc_next(pc_next),
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
      .muldiv_rs_full(muldiv_rs_full),
      .branch_rs_full(branch_rs_full),
      .load_rs_full(load_rs_full),
      .store_rs_full(store_rs_full),
      .rob_full(rob_full),
      .instr_pop(instr_pop),
      .alu_rs_issue(alu_rs_issue),
      .muldiv_rs_issue(muldiv_rs_issue),
      .branch_rs_issue(branch_rs_issue),
      .load_rs_issue(load_rs_issue),
      .store_rs_issue(store_rs_issue),
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

  muldiv_rs #(
      .MULDIV_RS_DEPTH(MULDIV_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) muldiv_rs (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .muldiv_rs_full(muldiv_rs_full),
      .muldiv_rs_issue(muldiv_rs_issue),
      .issue_funct3(issue_funct3),
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
      .cdb_muldiv_rs_valid(cdb_muldiv_rs_valid),
      .cdb_muldiv_rs_p(cdb_muldiv_rs_p),
      .cdb_muldiv_rs_rob(cdb_muldiv_rs_rob)
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
      .cdb_branch_target_pc(cdb_branch_target_pc)
  );

  load_store_fsm #(
      .LOAD_RS_DEPTH (LOAD_RS_DEPTH),
      .STORE_RS_DEPTH(STORE_RS_DEPTH)
  ) load_store_fsm (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .rob_ready(rob_ready),
      .rob_valid(rob_valid),
      .flush_branch(flush_branch),
      .dmem_resp(data_cache_resp),
      .dmem_r_rqst(dmem_r_rqst),
      .dmem_w_rqst(dmem_w_rqst),
      .load_rs_idx_rqst(load_rs_idx_rqst),
      .arbiter_load_rs(arbiter_load_rs),
      .arbiter_store_rs(arbiter_store_rs),
      .load_rs_idx_executing(load_rs_idx_executing),
      .load_rs_pop(load_rs_pop),
      .store_rs_pop(store_rs_pop),
      .dmem_rqst(dmem_rqst)
  );

  load_rs #(
      .LOAD_RS_DEPTH(LOAD_RS_DEPTH),
      .STORE_RS_DEPTH(STORE_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) load_rs (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .load_rs_full(load_rs_full),
      .load_rs_issue(load_rs_issue),
      .store_rs_pop(store_rs_pop),
      .dmem_r_rqst(dmem_r_rqst),
      .load_rs_idx_rqst(load_rs_idx_rqst),
      .load_rs_pop(load_rs_pop),
      .load_rs_idx_executing(load_rs_idx_executing),
      .dmem_rdata(data_cache_rdata),
      .issue_funct3(issue_funct3),
      .issue_imm(issue_imm),
      .issue_target_rob(issue_rob),
      .issue_rs1_regfile_ready(issue_rs1_regfile_ready),
      .issue_rs1_regfile_v(issue_rs1_regfile_v),
      .issue_rs1_regfile_rob(issue_rs1_regfile_rob),
      .issue_rs1_rob_v(issue_rs1_rob_v),
      .issue_rs1_rob_ready(issue_rs1_rob_ready),
    //   .issue_store_rs_head(issue_store_rs_head),
      .issue_store_rs_count(issue_store_rs_count),
      .cdb_valid(cdb_valid),
      .cdb_rob(cdb_rob),
      .cdb_rd_v(cdb_rd_v),
    //   .forward_wready(forward_wready),
    //   .forward_waddr(forward_waddr),
      .cdb_load_rs_valid(cdb_load_rs_valid),
      .cdb_load_rs_v(cdb_load_rs_v),
      .cdb_load_rs_rob(cdb_load_rs_rob),
      .cdb_load_rs_rmask(cdb_load_rs_rmask),
      .cdb_load_rs_addr(cdb_load_rs_addr),
      .cdb_load_rs_rdata(cdb_load_rs_rdata),
      .arbiter_load_rs_rmask(arbiter_load_rs_rmask),
      .arbiter_load_rs_addr(arbiter_load_rs_addr)
  );

  store_rs #(
      .STORE_RS_DEPTH(STORE_RS_DEPTH),
      .ROB_DEPTH(ROB_DEPTH),
      .CDB_SIZE(CDB_SIZE)
  ) store_rs (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .store_rs_issue(store_rs_issue),
      .store_rs_full(store_rs_full),
      .rob_tail(rob_tail),
      .dmem_w_rqst(dmem_w_rqst),
      .store_rs_pop(store_rs_pop),
      .issue_funct3(issue_funct3),
      .issue_imm(issue_imm),
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
      .issue_store_rs_count(issue_store_rs_count),
    //   .issue_store_rs_head(issue_store_rs_head),
      .cdb_valid(cdb_valid),
      .cdb_rob(cdb_rob),
      .cdb_rd_v(cdb_rd_v),
    //   .forward_wready(forward_wready),
    //   .forward_waddr(forward_waddr),
      .cdb_store_rs_valid(cdb_store_rs_valid),
      .cdb_store_rs_rob(cdb_store_rs_rob),
      .cdb_arbiter_store_rs_wmask(cdb_arbiter_store_rs_wmask),
      .cdb_arbiter_store_rs_addr(cdb_arbiter_store_rs_addr),
      .cdb_arbiter_store_rs_wdata(cdb_arbiter_store_rs_wdata)
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
      .cdb_branch_rs_valid(cdb_branch_rs_valid),
      .cdb_branch_rs_rob(cdb_branch_rs_rob),
      .cdb_branch_take(cdb_branch_take),
      .cdb_branch_target_pc(cdb_branch_target_pc),
      .cdb_load_rs_valid(cdb_load_rs_valid),
      .cdb_load_rs_rob(cdb_load_rs_rob),
      .cdb_load_rs_rmask(cdb_load_rs_rmask),
      .cdb_load_rs_addr(cdb_load_rs_addr),
      .cdb_load_rs_rdata(cdb_load_rs_rdata),
      .rob_tail(rob_tail),
      .cdb_store_rs_valid(cdb_store_rs_valid),
      .cdb_store_rs_rob(cdb_store_rs_rob),
      .cdb_arbiter_store_rs_wmask(cdb_arbiter_store_rs_wmask),
      .cdb_arbiter_store_rs_addr(cdb_arbiter_store_rs_addr),
      .cdb_arbiter_store_rs_wdata(cdb_arbiter_store_rs_wdata),
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
      .commit_pc(commit_pc),
      .flush_branch(flush_branch),
      .take_branch(take_branch),
      .pc_branch_target(pc_branch_target),
      .order_branch_target(order_branch_target),
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
