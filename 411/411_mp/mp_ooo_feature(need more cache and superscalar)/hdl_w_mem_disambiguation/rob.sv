module ROB
  import rv32i_types::*;
#(
    parameter ROB_DEPTH = 4,  // number of bits to use for depth
    parameter CDB_SIZE  = 3
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    // status signal
    output logic rob_full,
    output logic rob_valid,
    output logic rob_ready,

    // for cdb write into rob
    input logic                 cdb_valid           [CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob             [CDB_SIZE],
    input logic [         31:0] cdb_rd_v            [CDB_SIZE],
    // for branch
    input logic                 cdb_branch_rs_valid,
    input logic [ROB_DEPTH-1:0] cdb_branch_rs_rob,
    input logic                 cdb_branch_take,
    input logic [         31:0] cdb_branch_target_pc,
    // for load
    input logic                 cdb_load_rs_valid,
    input logic [ROB_DEPTH-1:0] cdb_load_rs_rob,
    input logic [3:0] cdb_load_rs_rmask,
    input logic [31:0] cdb_load_rs_addr,
    input logic [31:0] cdb_load_rs_rdata,
    // for store
    output logic [ROB_DEPTH-1:0] rob_tail,
    input logic cdb_store_rs_valid,
    input logic [ROB_DEPTH-1:0] cdb_store_rs_rob,
    input logic [3:0] cdb_arbiter_store_rs_wmask,
    input logic [31:0] cdb_arbiter_store_rs_addr,
    input logic [31:0] cdb_arbiter_store_rs_wdata,

    // for instruction_issue write into rob
    input  logic                   rob_push,
    input  logic [            4:0] issue_rd_s,
    output logic [  ROB_DEPTH-1:0] issue_rob,
    // for instruction_issue reading from rob when the instr is issued
    input  logic [ROB_DEPTH - 1:0] issue_rs1_rob,
    input  logic [ROB_DEPTH - 1:0] issue_rs2_rob,
    output logic [           31:0] issue_rs1_rob_v,
    output logic [           31:0] issue_rs2_rob_v,
    output logic                   issue_rs1_rob_ready,
    output logic                   issue_rs2_rob_ready,

    // for rob to commit out
    input logic rob_pop,
    output logic [4:0] commit_rd_s,
    output logic [31:0] commit_rd_v,
    output logic [ROB_DEPTH-1:0] commit_rob,
    output logic [6:0] commit_opcode,  // for commit.sv to determine regfile_we
    output logic [31:0] commit_pc,

    // forward to fetch.sv
    output logic flush_branch,
    output logic take_branch,
    output logic [31:0] pc_branch_target,
    output logic [63:0] order_branch_target,

    // for rvfi
    input  logic [63:0] rvfi_order,
    input  logic [31:0] rvfi_inst,
    input  logic [ 4:0] rvfi_rs1_s,
    input  logic [ 4:0] rvfi_rs2_s,
    input  logic [ 4:0] rvfi_rd_s,
    input  logic [31:0] rvfi_pc,
    input  logic [31:0] rvfi_pc_next,

    // for rvfi to read rs1_v and rs2_v
    output logic [ 4:0] rvfi_rs1_s_tail,
    output logic [ 4:0] rvfi_rs2_s_tail
);

  localparam MAX_NUM_ELEMS = 2 ** ROB_DEPTH;
  logic [ROB_DEPTH-1:0] head;
  logic [ROB_DEPTH-1:0] tail;
  // valid means occupy
  logic valid_arr[MAX_NUM_ELEMS];
  // ready means calculated/ready to commit
  logic ready_arr[MAX_NUM_ELEMS];

  // for committing to regfile
  logic [4:0] rd_s_arr[MAX_NUM_ELEMS];
  logic [31:0] rd_v_arr[MAX_NUM_ELEMS];

  // for branch take/not take
  logic branch_flush_arr[MAX_NUM_ELEMS];
  logic branch_take_arr[MAX_NUM_ELEMS];

  // for rvfi
  logic [63:0] rvfi_order_arr[MAX_NUM_ELEMS];
  logic [31:0] rvfi_inst_arr[MAX_NUM_ELEMS];
  logic [4:0] rvfi_rs1_s_arr[MAX_NUM_ELEMS];
  logic [4:0] rvfi_rs2_s_arr[MAX_NUM_ELEMS];
  logic [4:0] rvfi_rd_s_arr[MAX_NUM_ELEMS];
  logic [31:0] rvfi_pc_arr[MAX_NUM_ELEMS];
  logic [31:0] rvfi_pc_next_arr[MAX_NUM_ELEMS];
  logic [31:0] rvfi_mem_addr_arr[MAX_NUM_ELEMS];
  logic [3:0] rvfi_mem_rmask_arr[MAX_NUM_ELEMS];
  logic [3:0] rvfi_mem_wmask_arr[MAX_NUM_ELEMS];
  logic [31:0] rvfi_mem_rdata_arr[MAX_NUM_ELEMS];
  logic [31:0] rvfi_mem_wdata_arr[MAX_NUM_ELEMS];
  logic [63:0] rvfi_order_tail;
  logic [31:0] rvfi_inst_tail;
  logic [4:0] rvfi_rd_s_tail;
  logic [31:0] rvfi_rd_v_tail;
  logic [31:0] rvfi_pc_tail;
  logic [31:0] rvfi_pc_next_tail;
  logic [31:0] rvfi_mem_addr_tail;
  logic [3:0] rvfi_mem_rmask_tail;
  logic [3:0] rvfi_mem_wmask_tail;
  logic [31:0] rvfi_mem_rdata_tail;
  logic [31:0] rvfi_mem_wdata_tail;


  always_comb begin
    // check if current line is empty (no instruction in the line)
    rob_full = '0;
    if (valid_arr[head]) begin
      rob_full = '1;
    end
    rob_valid = valid_arr[tail];
    rob_ready = ready_arr[tail];

    // for assinging rob number to issued instruction
    issue_rob = head;

    //
    rob_tail = tail;

    // for committing
    commit_opcode = rvfi_inst_arr[tail][6:0];
    commit_pc = rvfi_pc_arr[tail];
    commit_rob = tail;
    commit_rd_s = rd_s_arr[tail];
    commit_rd_v = rd_v_arr[tail];

    // for flushing
    flush_branch = '0;
    take_branch = '0;
    if (commit_opcode == jal_opcode || commit_opcode == jalr_opcode || commit_opcode == br_opcode) begin
      if (branch_flush_arr[tail]) begin
        flush_branch = '1;
      end
      if (branch_take_arr[tail]) begin
        take_branch = '1;
      end
    end
    pc_branch_target = rvfi_pc_next_arr[tail];
    order_branch_target = rvfi_order_arr[tail] + 64'h1;
  end

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      head <= '0;
      tail <= '0;
      for (int i = 0; i < MAX_NUM_ELEMS; i++) begin
        valid_arr[i] <= '0;
        ready_arr[i] <= '0;
        rvfi_order_arr[i] <= '0;
        rvfi_inst_arr[i] <= '0;
        rvfi_rs1_s_arr[i] <= '0;
        rvfi_rs2_s_arr[i] <= '0;
        rvfi_rd_s_arr[i] <= '0;
        rvfi_pc_arr[i] <= '0;
        rvfi_pc_next_arr[i] <= '0;
        rvfi_mem_addr_arr[i] <= '0;
        rvfi_mem_rmask_arr[i] <= '0;
        rvfi_mem_wmask_arr[i] <= '0;
        rvfi_mem_rdata_arr[i] <= '0;
        rvfi_mem_wdata_arr[i] <= '0;
        branch_flush_arr[i] <= '0;
        branch_take_arr[i] <= '0;
      end
    end else begin
      if (rob_pop) begin
        valid_arr[tail] <= 1'b0;
        ready_arr[tail] <= 1'b0;
        branch_flush_arr[tail] <= '0;
        branch_take_arr[tail] <= '0;
        rvfi_mem_wmask_arr[tail] <= '0;
        rvfi_mem_rmask_arr[tail] <= '0;
        tail <= tail + 1'b1;
      end

      for (int i = 0; i < CDB_SIZE; ++i) begin
        if (cdb_valid[i]) begin
          ready_arr[cdb_rob[i]] <= '1;
          rd_v_arr[cdb_rob[i]]  <= cdb_rd_v[i];
        end
      end
      if (cdb_branch_rs_valid) begin
        if ((rvfi_pc_next_arr[cdb_branch_rs_rob] != cdb_branch_target_pc)) begin
          branch_flush_arr[cdb_branch_rs_rob] <= '1;
          rvfi_pc_next_arr[cdb_branch_rs_rob] <= cdb_branch_target_pc;
        end
        if (cdb_branch_take) begin
          branch_take_arr[cdb_branch_rs_rob] <= '1;
        end
      end
      if (cdb_load_rs_valid) begin
        rvfi_mem_wmask_arr[cdb_load_rs_rob] <= '0;
        rvfi_mem_wdata_arr[cdb_load_rs_rob] <= '0;
        rvfi_mem_rmask_arr[cdb_load_rs_rob] <= cdb_load_rs_rmask;
        rvfi_mem_addr_arr[cdb_load_rs_rob] <= cdb_load_rs_addr;
        rvfi_mem_rdata_arr[cdb_load_rs_rob] <= cdb_load_rs_rdata;
      end
      if (cdb_store_rs_valid) begin
        ready_arr[cdb_store_rs_rob] <= '1;
        rvfi_mem_rmask_arr[cdb_store_rs_rob] <= '0;
        rvfi_mem_rdata_arr[cdb_store_rs_rob] <= '0;
        rvfi_mem_wmask_arr[cdb_store_rs_rob] <= cdb_arbiter_store_rs_wmask;
        rvfi_mem_addr_arr[cdb_store_rs_rob] <= cdb_arbiter_store_rs_addr;
        rvfi_mem_wdata_arr[cdb_store_rs_rob] <= cdb_arbiter_store_rs_wdata;
      end

      if (rob_push) begin
        valid_arr[head] <= 1'b1;
        ready_arr[head] <= 1'b0;
        rd_s_arr[head] <= issue_rd_s;
        rvfi_order_arr[head] <= rvfi_order;
        rvfi_inst_arr[head] <= rvfi_inst;
        rvfi_rs1_s_arr[head] <= rvfi_rs1_s;
        rvfi_rs2_s_arr[head] <= rvfi_rs2_s;
        rvfi_rd_s_arr[head] <= rvfi_rd_s;
        if (rvfi_inst[6:0] == br_opcode || rvfi_inst[6:0] == store_opcode) begin
          rvfi_rd_s_arr[head] <= '0;
        end
        rvfi_pc_arr[head] <= rvfi_pc;
        rvfi_pc_next_arr[head] <= rvfi_pc_next;
        rvfi_mem_addr_arr[head] <= '0;
        rvfi_mem_rmask_arr[head] <= '0;
        rvfi_mem_wmask_arr[head] <= '0;
        rvfi_mem_rdata_arr[head] <= '0;
        rvfi_mem_wdata_arr[head] <= '0;
        branch_flush_arr[head] <= '0;
        branch_take_arr[head] <= '0;
        head <= head + 1'b1;
      end
    end
  end

  // transparent register isue: from cdb writing to rob
  always_comb begin
    issue_rs1_rob_ready = '0;
    issue_rs1_rob_v = '0;
    issue_rs2_rob_ready = '0;
    issue_rs2_rob_v = '0;
    if (valid_arr[issue_rs1_rob]) begin
      if (ready_arr[issue_rs1_rob]) begin
        issue_rs1_rob_ready = '1;
        issue_rs1_rob_v = rd_v_arr[issue_rs1_rob];
      end
      for (int i = 0; i < CDB_SIZE; ++i) begin
        if (cdb_valid[i] && (cdb_rob[i] == issue_rs1_rob)) begin
          issue_rs1_rob_ready = '1;
          issue_rs1_rob_v = cdb_rd_v[i];
        end
      end
    end
    if (valid_arr[issue_rs2_rob]) begin
      if (ready_arr[issue_rs2_rob]) begin
        issue_rs2_rob_ready = '1;
        issue_rs2_rob_v = rd_v_arr[issue_rs2_rob];
      end
      for (int i = 0; i < CDB_SIZE; ++i) begin
        if (cdb_valid[i] && (cdb_rob[i] == issue_rs2_rob)) begin
          issue_rs2_rob_ready = '1;
          issue_rs2_rob_v = cdb_rd_v[i];
        end
      end
    end
  end

  always_comb begin
    rvfi_order_tail = rvfi_order_arr[tail];
    rvfi_inst_tail = rvfi_inst_arr[tail];
    rvfi_rs1_s_tail = rvfi_rs1_s_arr[tail];
    rvfi_rs2_s_tail = rvfi_rs2_s_arr[tail];
    rvfi_rd_s_tail = rvfi_rd_s_arr[tail];
    rvfi_rd_v_tail = rd_v_arr[tail];
    rvfi_pc_tail = rvfi_pc_arr[tail];
    rvfi_pc_next_tail = rvfi_pc_next_arr[tail];
    rvfi_mem_addr_tail = rvfi_mem_addr_arr[tail];
    rvfi_mem_rmask_tail = rvfi_mem_rmask_arr[tail];
    rvfi_mem_wmask_tail = rvfi_mem_wmask_arr[tail];
    rvfi_mem_rdata_tail = rvfi_mem_rdata_arr[tail];
    rvfi_mem_wdata_tail = rvfi_mem_wdata_arr[tail];
  end

endmodule
