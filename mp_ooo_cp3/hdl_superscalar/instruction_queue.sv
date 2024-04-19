module instruction_queue #(
    parameter INSTR_DEPTH = 4,  // number of bits to use for depth
    parameter SUPERSCALAR = 1
) (
    input logic clk,
    input logic rst,

    // outputing whether the instruction queue is full and the valid/opcode information
    // we assume the instr_push and instr_pop are always correct
    output logic instr_full, 
    output logic instr_valid_out[SUPERSCALAR],

    input logic instr_push,
    input logic instr_pop[SUPERSCALAR],
    input logic [SUPERSCALAR*32-1:0] instr_in,
    input logic [63:0] order_in,

    output logic [63:0] order[SUPERSCALAR],
    output logic [31:0] instr[SUPERSCALAR],
    output logic [2:0] funct3[SUPERSCALAR],
    output logic [6:0] funct7[SUPERSCALAR],
    output logic [6:0] opcode[SUPERSCALAR],
    output logic [31:0] i_imm[SUPERSCALAR],
    output logic [31:0] s_imm[SUPERSCALAR],
    output logic [31:0] b_imm[SUPERSCALAR],
    output logic [31:0] u_imm[SUPERSCALAR],
    output logic [31:0] j_imm[SUPERSCALAR],
    output logic [4:0] rs1_s[SUPERSCALAR],
    output logic [4:0] rs2_s[SUPERSCALAR],
    output logic [4:0] rd_s[SUPERSCALAR]
);

  // Note about this queue:
  // 1. All push and pop operations use an array of SUPERSCALAR space as a unit.
  // So when there is no empty line, the queue is seen as full, even if there may be gaps in the last line.
  // 2. When issuing instructions, we need to make sure that every instruction in the current line is issued before moving to the next line.

  // case 1:
  //  suppose reservation station and ROB are empty
  //  instrution queue only has one instruction left
  //  miss ---> dram read
  //  can issue the only instruction left in queue

  // case 2:
  //  res station only one slot
  //  instr queue is full
  //  we can only issue one instruction from the queue

  // solution: consumer and producer together determine the number of instructions popped
  //  producer ---> instr queue (availability of different instructions): # produce
  //  consumer ---> res&rob (availability of different resources): # consume
  // therefore, we need to decode the instruction in this module

  // [xxxxxxxxxx]

  // [7] [8]
  // [5] [6]
  // [3] [4]
  // [1] [2]


  localparam MAX_NUM_ELEMS = 2 ** INSTR_DEPTH;  // Max number of elements queue can hold
  logic [INSTR_DEPTH-1:0] head;
  logic [INSTR_DEPTH-1:0] tail;
  logic [31:0] instr_arr[MAX_NUM_ELEMS][SUPERSCALAR];
  logic [63:0] order_arr[MAX_NUM_ELEMS][SUPERSCALAR];
  logic valid_arr[MAX_NUM_ELEMS][SUPERSCALAR];

  always_comb begin
    // check if current line is empty (no instruction in the line)
    instr_full = '0;
    for (int i = 0; i < SUPERSCALAR; ++i) begin
      if (valid_arr[head][i]) begin
        instr_full = '1;
      end
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
        for (int j = 0; j < SUPERSCALAR; j++) begin
          valid_arr[i][j] <= '0;
        end
      end
    end else begin
      // push instruction if there's push signal and queue is not full
      if (instr_push) begin
        for (int i = 0; i < SUPERSCALAR; i++) begin
          valid_arr[head][i] <= 1'b1;
          instr_arr[head][i] <= instr_in[i*32+:32];
          order_arr[head][i] <= order_in + i;
        end
        head <= head + 1'b1;
      end
      // pop instruction if it's valid
      for (int i = 0; i < SUPERSCALAR; i++) begin
        if (instr_pop[i]) begin
          valid_arr[tail][i] <= 1'b0;
          // if last instruction in the line is popped, move to the next line
          if (i == SUPERSCALAR - 1) begin
            tail <= tail + 1'b1;
          end
        end
      end
    end
  end

  generate
    for (genvar i = 0; i < SUPERSCALAR; i++) begin : gen_arrays
      ir ir_inst (
          .inst  (instr[i]),
          .funct3(funct3[i]),
          .funct7(funct7[i]),
          .opcode(opcode[i]),
          .i_imm (i_imm[i]),
          .s_imm (s_imm[i]),
          .b_imm (b_imm[i]),
          .u_imm (u_imm[i]),
          .j_imm (j_imm[i]),
          .rs1_s (rs1_s[i]),
          .rs2_s (rs2_s[i]),
          .rd_s  (rd_s[i])
      );
    end
  endgenerate

endmodule : instruction_queue
