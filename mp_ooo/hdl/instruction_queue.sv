module instruction_queue #(
    parameter DEPTH = 4,  // number of bits to use for depth
    parameter WIDTH = 32
) (
    input logic clk,
    input logic rst,
    input logic instr_push,  // Add in to head
    input logic instr_pop,  // remove tail
    input logic [WIDTH-1:0] instr_in,  // data to be inserted at head
    output logic instr_full,  // high when queue is full
    output logic instr_valid_out,  // out is outputting valid data
    output logic [WIDTH-1:0] instr_out     // Whatever the tail is pointing to + valid bit, oldest element in queue
);

  localparam NUM_ELEMS = 2 ** DEPTH;  // Max number of elements queue can hold
  logic [DEPTH-1:0] head;
  logic [DEPTH-1:0] tail;
  logic [WIDTH:0] data[NUM_ELEMS];  // bit 0 is valid bit
  logic valid_tail;

  always_comb begin
    instr_full = (data[head][0] == 1'b1);
    valid_tail = (data[tail][0] == 1'b1);
    instr_valid_out = data[tail][0];
    instr_out = data[tail][WIDTH:1];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      head <= '0;
      tail <= '0;
      for (int i = 0; i < NUM_ELEMS; i++) begin
        data[i] <= '0;
      end
    end else begin
      if (instr_push && (instr_full == 1'b0)) begin
        data[head] <= {instr_in, 1'b1};
        head <= head + 1'd1;
      end
      if (instr_pop && valid_tail) begin
        data[tail][0] <= 1'b0;
        tail <= tail + 1'd1;
      end
    end

  end
endmodule : instruction_queue
