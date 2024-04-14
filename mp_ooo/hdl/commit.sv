module commit
  import rv32i_types::*;
(
    input logic rob_valid,
    input logic rob_ready,
    input logic [6:0] commit_opcode,
    output logic rob_pop,
    output logic commit_regfile_we
);
  always_comb begin
    commit_regfile_we = '0;
    rob_pop = '0;
    if (rob_valid && rob_ready) begin
      rob_pop = '1;
      case (commit_opcode)
        store_opcode, br_opcode: commit_regfile_we = '0;
        default: commit_regfile_we = '1;
      endcase
    end
  end
endmodule
