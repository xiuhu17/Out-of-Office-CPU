module PLRU
  import cache_types::*;
(
    input logic clk,
    input logic rst,
    input logic ufp_Resp,
    input logic [3:0] curr_set,
    input logic [1:0] PLRU_Way_Visit,
    // input logic Way_A_Valid,
    // input logic Way_B_Valid,
    // input logic Way_C_Valid,
    // input logic Way_D_Valid,
    output logic [1:0] PLRU_Way_Replace
);
  logic [2:0] PLRU_Arr[16];
  logic [2:0] next_PLRU_Set;

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 16; ++i) begin
        PLRU_Arr[i] <= 3'b0;
      end
    end else if (ufp_Resp) begin
      // for hit, then update
      PLRU_Arr[curr_set] <= next_PLRU_Set;
    end
  end

  // for hit, then update
  always_comb begin
    next_PLRU_Set = PLRU_Arr[curr_set];
    case (PLRU_Way_Visit)
      Way_A: begin
        next_PLRU_Set = {PLRU_Arr[curr_set][2], 1'b0, 1'b0};
      end
      Way_B: begin
        next_PLRU_Set = {PLRU_Arr[curr_set][2], 1'b1, 1'b0};
      end
      Way_C: begin
        next_PLRU_Set = {1'b0, PLRU_Arr[curr_set][1], 1'b1};
      end
      Way_D: begin
        next_PLRU_Set = {1'b1, PLRU_Arr[curr_set][1], 1'b1};
      end
    endcase
  end

  always_comb begin
    PLRU_Way_Replace = 'x;
    // if (~Way_A_Valid) begin 
    //     PLRU_Way_Replace = Way_A;
    // end else if (~Way_B_Valid) begin
    //     PLRU_Way_Replace = Way_B;
    // end else if (~Way_C_Valid) begin 
    //     PLRU_Way_Replace = Way_C;
    // end else if (~Way_D_Valid) begin 
    //     PLRU_Way_Replace = Way_D;
    // end else begin 
    if (PLRU_Arr[curr_set][0]) begin
      if (PLRU_Arr[curr_set][1]) begin
        PLRU_Way_Replace = Way_A;
      end else begin
        PLRU_Way_Replace = Way_B;
      end
    end else begin
      if (PLRU_Arr[curr_set][2]) begin
        PLRU_Way_Replace = Way_C;
      end else begin
        PLRU_Way_Replace = Way_D;
      end
    end
  end
  // end

endmodule
