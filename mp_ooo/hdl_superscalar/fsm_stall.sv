module fsm_stall (
    input logic clk,
    input logic rst,

    input  logic instr_full,
    output logic fetch_stall
);

  always_comb begin
    if (instr_full) begin
      fetch_stall = 1'b1;
    end else begin
      fetch_stall = 1'b0;
    end
  end

endmodule
