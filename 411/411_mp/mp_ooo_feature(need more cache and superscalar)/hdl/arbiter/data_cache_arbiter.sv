module data_cache_arbiter (
    input logic arbiter_load_rs,
    input logic arbiter_store_rs,

    input logic [3:0] arbiter_load_rs_rmask,
    input logic [31:0] arbiter_load_rs_addr,

    input logic [31:0] cdb_arbiter_store_rs_wdata,
    input logic [3:0] cdb_arbiter_store_rs_wmask,
    input logic [31:0] cdb_arbiter_store_rs_addr,

    output logic [3:0] dmem_rmask,
    output logic [3:0] dmem_wmask,
    output logic [31:0] dmem_addr,
    output logic [31:0] dmem_wdata
);
  always_comb begin
    dmem_rmask = '0;
    dmem_wmask = '0;
    dmem_addr = '0;
    dmem_wdata = '0;
    if (arbiter_store_rs) begin
      dmem_wdata = cdb_arbiter_store_rs_wdata;
      dmem_wmask = cdb_arbiter_store_rs_wmask;
      dmem_addr = cdb_arbiter_store_rs_addr & 32'hfffffffc;
    end else if (arbiter_load_rs) begin
      dmem_rmask = arbiter_load_rs_rmask;
      dmem_addr = arbiter_load_rs_addr & 32'hfffffffc;
    end
  end
endmodule
