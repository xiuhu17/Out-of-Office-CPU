module commit (
    input  logic rob_valid,
    input  logic rob_ready,
    output logic rob_pop,
    output logic commit_regfile_we
);
  always_comb begin
    commit_regfile_we = '0;
    rob_pop = '0;
    if (rob_valid && rob_ready) begin
      commit_regfile_we = '1;
      rob_pop = '1;
    end
  end
endmodule
