module data_serve (
    input logic clk,
    input logic rst,
    input logic ufp_resp,

    input logic [31:0] cpu_ufp_addr,
    input logic [ 3:0] cpu_ufp_rmask,
    input logic [ 3:0] cpu_ufp_wmask,
    input logic [31:0] cpu_ufp_wdata,

    output logic [31:0] ufp_addr,
    output logic [ 3:0] ufp_rmask,
    output logic [ 3:0] ufp_wmask,
    output logic [31:0] ufp_wdata

);

  logic [31:0] internal_cpu_ufp_addr;
  logic [ 3:0] internal_cpu_ufp_rmask;
  logic [ 3:0] internal_cpu_ufp_wmask;
  logic [31:0] internal_cpu_ufp_wdata;

  always_ff @(posedge clk) begin
    if (rst) begin
      internal_cpu_ufp_addr  <= 32'h0;
      internal_cpu_ufp_rmask <= 4'h0;
      internal_cpu_ufp_wmask <= 4'h0;
      internal_cpu_ufp_wdata <= 32'h0;
    end else begin
      if (ufp_resp) begin
        if (cpu_ufp_rmask != '0 || cpu_ufp_wmask != '0) begin
          internal_cpu_ufp_addr  <= cpu_ufp_addr;
          internal_cpu_ufp_rmask <= cpu_ufp_rmask;
          internal_cpu_ufp_wmask <= cpu_ufp_wmask;
          internal_cpu_ufp_wdata <= cpu_ufp_wdata;
        end else begin
          internal_cpu_ufp_addr  <= 32'h0;
          internal_cpu_ufp_rmask <= 4'h0;
          internal_cpu_ufp_wmask <= 4'h0;
          internal_cpu_ufp_wdata <= 32'h0;
        end
      end else begin
        if (internal_cpu_ufp_rmask == '0 && internal_cpu_ufp_wmask == '0) begin
          if (cpu_ufp_rmask != '0 || cpu_ufp_wmask != '0) begin
            internal_cpu_ufp_addr  <= cpu_ufp_addr;
            internal_cpu_ufp_rmask <= cpu_ufp_rmask;
            internal_cpu_ufp_wmask <= cpu_ufp_wmask;
            internal_cpu_ufp_wdata <= cpu_ufp_wdata;
          end
        end
      end
    end
  end


  always_comb begin
    ufp_addr  = internal_cpu_ufp_addr;
    ufp_rmask = internal_cpu_ufp_rmask;
    ufp_wmask = internal_cpu_ufp_wmask;
    ufp_wdata = internal_cpu_ufp_wdata;

    if (internal_cpu_ufp_rmask == '0 && internal_cpu_ufp_wmask == '0) begin
        ufp_addr  = cpu_ufp_addr;
        ufp_rmask = cpu_ufp_rmask;
        ufp_wmask = cpu_ufp_wmask;
        ufp_wdata = cpu_ufp_wdata;
    end
  end

endmodule
