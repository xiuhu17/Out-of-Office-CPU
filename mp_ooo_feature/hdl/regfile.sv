module regfile_scoreboard
  import rv32i_types::*;
#(
    parameter ROB_DEPTH = 4
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    // rob_to_regfile_t
    // each time we may not write SUPERSCALAR robs to regfile, e.g only one could commit, but superscalar = 2
    input logic                   commit_regfile_we,
    input logic [            4:0] commit_rd_s,
    input logic [           31:0] commit_rd_v,
    input logic [ROB_DEPTH - 1:0] commit_rob,

    // overwrite the scoreboard when instruction is issued
    // iq_to_regfile_t
    input logic                   issue_valid,
    input logic [            6:0] issue_opcode,
    input logic [            4:0] issue_rd_s,
    input logic [ROB_DEPTH - 1:0] issue_rob,

    // read from registerfile when instruction is issued
    // regfile_to_iq_t
    input  logic [            4:0] issue_rs1_s,
    input  logic [            4:0] issue_rs2_s,
    output logic [           31:0] issue_rs1_regfile_v,
    output logic [           31:0] issue_rs2_regfile_v,
    output logic                   issue_rs1_regfile_ready,
    output logic                   issue_rs2_regfile_ready,
    output logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    output logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,

    // rvfi
    input logic [4:0] rvfi_rs1_s_tail,
    input logic [4:0] rvfi_rs2_s_tail
);

  // 0 is oldest
  // n is youngest
  logic [31:0] register_arr[32];
  logic [ROB_DEPTH - 1:0] scoreboard_arr[32];
  logic scoreboard_valid_arr[32];

  // rvfi
  logic [31:0] rvfi_rs1_v_tail;
  logic [31:0] rvfi_rs2_v_tail;

  always_comb begin
    rvfi_rs1_v_tail = register_arr[rvfi_rs1_s_tail];
    rvfi_rs2_v_tail = register_arr[rvfi_rs2_s_tail];
  end

  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < 32; i++) begin
        register_arr[i] <= '0;
        scoreboard_arr[i] <= '0;
        scoreboard_valid_arr[i] <= '0;
      end
    end else begin
      if (commit_regfile_we && (commit_rd_s != 5'd0)) begin
        // scoreboard update
        //  update only when scoreboard exists and the commit is the rob which matches the scoreboard; stop looking up the rob
        //  otherwise, scoreboard still exists
        if (scoreboard_valid_arr[commit_rd_s] && (scoreboard_arr[commit_rd_s] == commit_rob)) begin
          scoreboard_valid_arr[commit_rd_s] <= '0;
        end
      end

      // after updating the scoreboard, we may need to update scoreboard if there's a newly issued instruction
      if (issue_valid && (issue_rd_s != 5'd0)) begin
        if (issue_opcode != store_opcode && issue_opcode != br_opcode) begin
          scoreboard_arr[issue_rd_s] <= issue_rob;
          scoreboard_valid_arr[issue_rd_s] <= '1;
        end
      end

      if (move_flush) begin
        for (int i = 0; i < 32; i++) begin
          scoreboard_arr[i] <= '0;
          scoreboard_valid_arr[i] <= '0;
        end
      end

      if (commit_regfile_we && (commit_rd_s != 5'd0)) begin
        // value update
        register_arr[commit_rd_s] <= commit_rd_v;
      end
    end
  end

  always_comb begin
    issue_rs1_regfile_v = register_arr[issue_rs1_s];
    issue_rs2_regfile_v = register_arr[issue_rs2_s];
    issue_rs1_regfile_ready = ~scoreboard_valid_arr[issue_rs1_s];
    issue_rs2_regfile_ready = ~scoreboard_valid_arr[issue_rs2_s];
    issue_rs1_regfile_rob = scoreboard_arr[issue_rs1_s];
    issue_rs2_regfile_rob = scoreboard_arr[issue_rs2_s];
  end

endmodule


