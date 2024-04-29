module fetch (
    input logic clk,
    input logic rst,

    input logic move_fetch,

    input logic move_flush,
    input logic [31:0] pc_branch_target,
    input logic [63:0] order_branch_target,

    output logic [31:0] imem_addr,
    output logic [3:0] imem_rmask,
    output logic imem_rqst,

    output logic [31:0] pc,
    output logic [63:0] order,
    input logic [31:0] pc_next
);
  // registers
  logic [31:0] pc_curr;
  logic [63:0] order_curr;
  // wires
  logic [63:0] order_next;

  always_comb begin
    pc = pc_curr;
    order = order_curr;
    order_next = order + 64'h1;
    imem_addr = pc;
  end

  always_comb begin
    // output rmask
    if (move_fetch) begin
      imem_rmask = '1;
      imem_rqst  = '1;
    end else begin
      imem_rmask = '0;
      imem_rqst  = '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      pc_curr <= 32'h60000000;
      order_curr <= '0;
    end else begin
      if (move_flush) begin
        pc_curr <= pc_branch_target;
        order_curr <= order_branch_target;
      end else if (move_fetch) begin
        pc_curr <= pc_next;
        order_curr <= order_next;
      end
    end
  end

endmodule
