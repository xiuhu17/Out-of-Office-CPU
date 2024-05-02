module data_cache_arbiter (
    input logic arbiter_load_rs,
    input logic arbiter_store_buffer,

    input logic [3:0] arbiter_load_rs_rmask,
    input logic [31:0] arbiter_load_rs_addr,

    input logic [3:0] arbiter_store_buffer_wmask,
    input logic [31:0] arbiter_store_buffer_addr,
    input logic [31:0] arbiter_store_buffer_wdata,

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
    if (arbiter_store_buffer) begin
      dmem_wmask = arbiter_store_buffer_wmask;
      dmem_addr = arbiter_store_buffer_addr & 32'hfffffffc;
      dmem_wdata = arbiter_store_buffer_wdata;
    end else if (arbiter_load_rs) begin
      dmem_rmask = arbiter_load_rs_rmask;
      dmem_addr = arbiter_load_rs_addr & 32'hfffffffc;
    end
  end
endmodule
