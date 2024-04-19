module CDB #(
    parameter CDB_SIZE  = 3,  // total number of reservation stations (one CDB slot for each)
    parameter ROB_DEPTH = 4
) (
    input logic                 exe_valid[CDB_SIZE],  // valid bit for each reservation station
    input logic [         31:0] exe_alu_f[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] exe_rob  [CDB_SIZE],

    output logic                 cdb_valid[CDB_SIZE],
    output logic [         31:0] cdb_rd_v [CDB_SIZE],
    output logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE]
);

  always_comb begin
    for (int i = 0; i < CDB_SIZE; i++) begin
      cdb_valid[i] = exe_valid[i];
      cdb_rd_v[i]  = exe_alu_f[i];
      cdb_rob[i]   = exe_rob[i];
    end
  end

endmodule

