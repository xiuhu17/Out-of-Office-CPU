module instruction_queue #(
    parameter INSTR_DEPTH = 4  // number of bits to use for depth
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    // outputing whether the instruction queue is full and the valid/opcode information
    // we assume the instr_push and instr_pop are always correct
    output logic instr_full,
    output logic instr_valid,
    output logic instr_ready,

    input logic move_fetch,
    input logic imem_resp,
    input logic instr_pop,

    input logic [31:0] imem_rdata,
    input logic [63:0] fetch_order,
    input logic [31:0] fetch_pc,
    input logic [31:0] fetch_pc_next,

    output logic [63:0] issue_order,
    output logic [31:0] issue_instr,
    output logic [31:0] issue_pc,
    output logic [31:0] issue_pc_next,
    output logic [ 2:0] issue_funct3,
    output logic [ 6:0] issue_funct7,
    output logic [ 6:0] issue_opcode,
    output logic [31:0] issue_imm,
    output logic [ 4:0] issue_rs1_s,
    output logic [ 4:0] issue_rs2_s,
    output logic [ 4:0] issue_rd_s
);

  localparam MAX_NUM_ELEMS = 2 ** INSTR_DEPTH;  // Max number of elements queue can hold
  logic [31:0] instr_arr[MAX_NUM_ELEMS];
  logic [63:0] order_arr[MAX_NUM_ELEMS];
  logic [31:0] pc_arr[MAX_NUM_ELEMS];
  logic [31:0] pc_next_arr[MAX_NUM_ELEMS];

  logic [INSTR_DEPTH-1:0] valid_head;
  logic [INSTR_DEPTH-1:0] valid_tail;
  logic [INSTR_DEPTH-1:0] ready_head;
  logic [INSTR_DEPTH-1:0] ready_tail;
  logic valid_arr[MAX_NUM_ELEMS];
  logic ready_arr[MAX_NUM_ELEMS];

  // sending signal
  always_comb begin
    instr_full  = valid_arr[valid_head];
    instr_valid = valid_arr[valid_tail];
    instr_ready = ready_arr[ready_tail];
  end

  // sending value
  always_comb begin
    issue_instr = instr_arr[ready_tail];
    issue_order = order_arr[ready_tail];
    issue_pc = pc_arr[ready_tail];
    issue_pc_next = pc_next_arr[ready_tail];
  end

  // if full (head == tail), we do not support pop tail and push head at same cycle
  // if empty (head == tail), we also do not support push and pop for same instructions at same cycle (we want instructions stay for at least one cycle)
  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      valid_head <= '0;
      valid_tail <= '0;
      ready_head <= '0;
      ready_tail <= '0;
      for (int i = 0; i < MAX_NUM_ELEMS; i++) begin
        valid_arr[i] <= '0;
        ready_arr[i] <= '0;
      end
    end else begin
      // pop instruction if it's valid
      if (instr_pop) begin
        valid_arr[valid_tail] <= 1'b0;
        ready_arr[ready_tail] <= 1'b0;
        valid_tail <= valid_tail + 1'b1;
        ready_tail <= ready_tail + 1'b1;
      end

      // push instruction if there's push signal and queue is not full
      if (move_fetch) begin
        valid_arr[valid_head] <= 1'b1;
        pc_arr[valid_head] <= fetch_pc;
        pc_next_arr[valid_head] <= fetch_pc_next;
        order_arr[valid_head] <= fetch_order;
        valid_head <= valid_head + 1'b1;
      end

      // 
      if (imem_resp) begin
        ready_arr[ready_head] <= 1'b1;
        instr_arr[ready_head] <= imem_rdata;
        ready_head <= ready_head + 1'b1;
      end
    end
  end

  decode decode (
      .inst(issue_instr),
      .funct3(issue_funct3),
      .funct7(issue_funct7),
      .opcode(issue_opcode),
      .imm(issue_imm),
      .rs1_s(issue_rs1_s),
      .rs2_s(issue_rs2_s),
      .rd_s(issue_rd_s)
  );

endmodule : instruction_queue
