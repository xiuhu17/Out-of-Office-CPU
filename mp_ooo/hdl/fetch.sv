module fetch #(
    parameter SUPERSCALAR = 1
) (
    input logic clk,
    input logic rst,

    input logic fetch_stall,
    input logic take_branch,

    input logic [31:0] pc_branch,
    output logic [31:0] imem_addr,
    output logic [4*SUPERSCALAR-1:0] imem_rmask,
    output logic [63:0] order_curr
);
  // registers
  logic [31:0] pc_curr;
  // wires
  logic [31:0] pc_next;
  logic [63:0] order_next;
  logic [31:0] pc_pred;  // static not-taken bp (use PC+4)

  always_comb begin
    imem_addr = pc_curr;
    pc_pred   = pc_curr + 32'h4 * SUPERSCALAR;  // static not-taken bp
    // update pc_next
    if (take_branch) begin
      pc_next = pc_branch;
      order_next = order_curr + SUPERSCALAR;  // TODO: update order on branch
    end else begin
      pc_next = pc_pred;
      order_next = order_curr + SUPERSCALAR;
    end
    // output rmask
    if (!fetch_stall) begin
      imem_rmask = '1;
    end else begin
      imem_rmask = '0;
    end
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      pc_curr <= 32'h60000000;
      order_curr <= '0;
    end else begin
      if (!fetch_stall) begin
        pc_curr <= pc_next;
        order_curr <= order_next;
      end
    end
  end

endmodule
