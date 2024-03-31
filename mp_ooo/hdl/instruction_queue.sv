module instruction_queue #(
    parameter INSTR_DEPTH = 4  // number of bits to use for depth
) (
    input logic clk,
    input logic rst,

    // outputing whether the instruction queue is full and the valid/opcode information
    // we assume the instr_push and instr_pop are always correct
    output logic instr_full,
    output logic instr_valid_out,

    input logic instr_push,
    input logic instr_pop,
    input logic [31:0] instr_in,
    input logic [63:0] order_in,

    output logic [63:0] order,
    output logic [31:0] instr,
    output logic [ 2:0] funct3,
    output logic [ 6:0] funct7,
    output logic [ 6:0] opcode,
    output logic [31:0] imm,
    output logic [ 4:0] rs1_s,
    output logic [ 4:0] rs2_s,
    output logic [ 4:0] rd_s
);

  localparam MAX_NUM_ELEMS = 2 ** INSTR_DEPTH;  // Max number of elements queue can hold
  logic [INSTR_DEPTH-1:0] head;
  logic [INSTR_DEPTH-1:0] tail;
  logic [31:0] instr_arr[MAX_NUM_ELEMS];
  logic [63:0] order_arr[MAX_NUM_ELEMS];
  logic valid_arr[MAX_NUM_ELEMS];
  // immediate values
  logic [31:0] i_imm, s_imm, b_imm, u_imm, j_imm;

  always_comb begin
    // check if current line is empty (no instruction in the line)
    instr_full = '0;
    if (valid_arr[head]) begin
      instr_full = '1;
    end
    instr = instr_arr[tail];
    order = order_arr[tail];
    instr_valid_out = valid_arr[tail];
  end

  // if full (head == tail), we do not support pop tail and push head at same cycle
  // if empty (head == tail), we also do not support push and pop for same instructions at same cycle (we want instructions stay for at least one cycle)
  always_ff @(posedge clk) begin
    if (rst) begin
      head <= '0;
      tail <= '0;
      for (int i = 0; i < MAX_NUM_ELEMS; i++) begin
        valid_arr[i] <= '0;
      end
    end else begin
      // pop instruction if it's valid
      if (instr_pop) begin
        valid_arr[tail] <= 1'b0;
        tail <= tail + 1'b1;
      end

      // push instruction if there's push signal and queue is not full
      if (instr_push) begin
        valid_arr[head] <= 1'b1;
        instr_arr[head] <= instr_in;
        order_arr[head] <= order_in;
        head <= head + 1'b1;
      end
    end
  end

  ir ir_inst (
      .inst  (instr),
      .funct3(funct3),
      .funct7(funct7),
      .opcode(opcode),
      .i_imm (i_imm),
      .s_imm (s_imm),
      .b_imm (b_imm),
      .u_imm (u_imm),
      .j_imm (j_imm),
      .rs1_s (rs1_s),
      .rs2_s (rs2_s),
      .rd_s  (rd_s)
  );

  imm_gen imm_gen_inst (
      .opcode(opcode),
      .i_imm(i_imm),
      .s_imm(s_imm),
      .b_imm(b_imm),
      .u_imm(u_imm),
      .j_imm(j_imm),
      .imm(imm)
  );

endmodule : instruction_queue
