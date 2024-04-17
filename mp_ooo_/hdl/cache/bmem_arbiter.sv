module bmem_arbiter (
    // bmem signal
    input logic bmem_ready,
    // instr_cache signals
    input logic instr_cache_read_stage,
    input logic instr_cache_bmem_read,
    input logic [31:0] instr_cache_bmem_addr,
    // data_cache signals
    input logic data_cache_read_stage,
    input logic data_cache_write_stage,
    input logic data_cache_bmem_read,
    input logic data_cache_bmem_write,
    input logic [31:0] data_cache_bmem_addr,
    input logic [63:0] data_cache_bmem_wdata,

    // output signals for caches
    output logic instr_cache_bmem_ready,
    output logic data_cache_bmem_ready,
    output logic bmem_read,
    output logic bmem_write,
    // output signals for bmem
    output logic [31:0] bmem_addr,
    output logic [63:0] bmem_wdata
);
  always_comb begin
    instr_cache_bmem_ready = '0;
    data_cache_bmem_ready  = '0;
    bmem_addr              = '0;
    bmem_read              = '0;
    bmem_write             = '0;
    bmem_wdata             = '0;
    if (bmem_ready) begin
      if (data_cache_read_stage || data_cache_write_stage) begin
        data_cache_bmem_ready = '1;
        bmem_addr = data_cache_bmem_addr;
        bmem_read = data_cache_bmem_read;
        bmem_write = data_cache_bmem_write;
        bmem_wdata = data_cache_bmem_wdata;
      end else if (instr_cache_read_stage) begin
        instr_cache_bmem_ready = '1;
        bmem_addr = instr_cache_bmem_addr;
        bmem_read = instr_cache_bmem_read;
      end
    end
  end

endmodule





