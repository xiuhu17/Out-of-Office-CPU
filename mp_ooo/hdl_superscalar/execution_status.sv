module execution_status #(
    parameter int ALU_SIZE = 2
) (
    input logic clk,
    input logic rst,

    input logic w_en [ALU_SIZE],
    input logic start[ALU_SIZE],
    input logic done [ALU_SIZE],

    output logic busy[ALU_SIZE]
);

  // two design choices:
  //  1. each reservation station check whether it the executation unit is busy or not // too many ports
  //  2. executation unit itself output its status
  logic internal_busy[ALU_SIZE];

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < ALU_SIZE; i++) begin
        internal_busy[i] <= 0;
      end
    end else begin
      for (int i = 0; i < ALU_SIZE; i++) begin
        if (w_en[i]) begin
          if (start[i]) begin
            internal_busy[i] <= 1;
          end else if (done[i]) begin
            internal_busy[i] <= 0;
          end
        end
      end
    end
  end

  always_comb begin
    for (int i = 0; i < ALU_SIZE; i++) begin
      busy[i] = internal_busy[i];
    end
  end

endmodule
