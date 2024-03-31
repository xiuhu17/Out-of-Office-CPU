module ROB
  import rv32i_types::*;
#(
    parameter ROB_DEPTH = 4,  // number of bits to use for depth
    parameter CDB_SIZE  = 2
) (
    input logic clk,
    input logic rst,

    // status signal
    output logic rob_full,
    output logic rob_valid_out,
    output logic rob_ready_out,

    // for cdb write into rob
    // cdb_t
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

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
    output logic [ROB_DEPTH-1:0] commit_rob
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

  // for rvfi
  rvfi_t rvfi[MAX_NUM_ELEMS];

  always_comb begin
    // check if current line is empty (no instruction in the line)
    rob_full = '0;
    if (valid_arr[head]) begin
      rob_full = '1;
    end
    rob_valid_out = valid_arr[tail];
    rob_ready_out = ready_arr[tail];

    // for assinging rob number to issued instruction
    issue_rob = head;

    // for committing
    commit_rob = tail;
    commit_rd_s = rd_s_arr[tail];
    commit_rd_v = rd_v_arr[tail];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      head <= '0;
      tail <= '0;
      for (int i = 0; i < MAX_NUM_ELEMS; i++) begin
        valid_arr[i] <= '0;
        ready_arr[i] <= '0;
      end
    end else begin
      if (rob_pop) begin
        valid_arr[tail] <= 1'b0;
        ready_arr[tail] <= 1'b0;
        tail <= tail + 1'b1;
      end

      for (int i = 0; i < CDB_SIZE; ++i) begin
        if (cdb_valid[i]) begin
          ready_arr[cdb_rob[i]] <= '1;
          rd_v_arr[cdb_rob[i]]  <= cdb_rd_v[i];
        end
      end

      if (rob_push) begin
        valid_arr[head] <= 1'b1;
        ready_arr[head] <= 1'b0;
        rd_s_arr[head] <= issue_rd_s;
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
endmodule
