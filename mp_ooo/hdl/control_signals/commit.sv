module commit
  import rv32i_types::*;
(
    input logic rob_valid,
    input logic rob_ready,
    input logic [6:0] commit_opcode,

    input logic flush_branch,
    input logic move_flush,

    output logic rob_pop,
    output logic commit_regfile_we
);

  always_comb begin
    commit_regfile_we = '0;
    rob_pop = '0;
    if (rob_valid && rob_ready) begin
      case (commit_opcode)
        jal_opcode, jalr_opcode: begin
          if (flush_branch) begin
            if (move_flush) begin
              commit_regfile_we = '1;
              rob_pop = '1;
            end
          end else begin
            commit_regfile_we = '1;
            rob_pop = '1;
          end
        end
        br_opcode: begin
          if (flush_branch) begin
            if (move_flush) begin
              commit_regfile_we = '0;
              rob_pop = '1;
            end
          end else begin
            commit_regfile_we = '0;
            rob_pop = '1;
          end
        end
        store_opcode: begin
          commit_regfile_we = '0;
          rob_pop = '1;
        end
        default: begin
          commit_regfile_we = '1;
          rob_pop = '1;
        end
      endcase
    end
  end
endmodule
