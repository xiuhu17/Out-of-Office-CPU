module data_cache_arbiter (
    // load_rs signals
    input  logic [31:0] data_cache_load_rs_addr,
    input  logic [ 3:0] data_cache_load_rs_rmask,
    // store_rs signals
    input  logic [31:0] data_cache_store_rs_addr,
    input  logic [ 3:0] data_cache_store_rs_wmask,
    input  logic [31:0] data_cache_store_rs_wdata,
    // output signals
    output logic [31:0] data_cache_addr,
    output logic [ 3:0] data_cache_rmask,
    output logic [ 3:0] data_cache_wmask,
    output logic [31:0] data_cache_wdata
);
  always_comb begin
    if (data_cache_store_rs_wmask != 0) begin
      data_cache_addr  = data_cache_store_rs_addr;
      data_cache_rmask = '0;
      data_cache_wmask = data_cache_store_rs_wmask;
      data_cache_wdata = data_cache_store_rs_wdata;
    end else begin
      data_cache_addr  = data_cache_load_rs_addr;
      data_cache_rmask = data_cache_load_rs_rmask;
      data_cache_wmask = '0;
      data_cache_wdata = '0;
    end
  end

endmodule
