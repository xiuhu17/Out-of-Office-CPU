module gshare
  import rv32i_types::*;
#(
    parameter GHR_DEPTH = 30,
    parameter PHT_DEPTH = 10,
    parameter BIMODAL_DEPTH = 2
) (
    input logic clk,
    input logic rst,

    // flush_branch mean the prediction is wrong
    input logic rob_pop,
    input logic flush_branch,
    input logic take_branch,
    input logic [6:0] commit_opcode,
    input logic [31:0] commit_pc,

    // fetch
    input logic [31:0] fetch_pc,
    output logic gshare_take
);

  localparam GSHARE_NUM_ELEM = 2 ** PHT_DEPTH;

  // 
  logic [GHR_DEPTH-1:0] GHR;
  logic [BIMODAL_DEPTH-1:0] PHT[GSHARE_NUM_ELEM];

  always_ff @(posedge clk) begin
    if (rst) begin
      GHR <= '0;
      for (int i = 0; i < GSHARE_NUM_ELEM; i++) begin
        PHT[i] <= 2'b01;
      end
    end else begin
      if (rob_pop) begin
        if (commit_opcode == br_opcode) begin
          GHR <= {GHR[GHR_DEPTH-2:0], take_branch};
          if (flush_branch) begin
            if (PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]][1]) begin
              PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] <= PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] - 1'b1;
            end else begin
              PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] <= PHT[GHR[PHT_DEPTH-1:0] ^ commit_pc[PHT_DEPTH+1:2]] + 1'b1;
            end
          end else begin
            if (PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] == 2'b10) begin
              PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] <= 2'b11;
            end else if (PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] == 2'b01) begin
              PHT[GHR[PHT_DEPTH-1:0]^commit_pc[PHT_DEPTH+1:2]] <= 2'b00;
            end
          end
        end
      end
    end
  end

  always_comb begin
    gshare_take = '0;
    if (PHT[GHR[PHT_DEPTH-1:0]^fetch_pc[PHT_DEPTH+1:2]][1]) begin
      gshare_take = '1;
    end
  end
endmodule
