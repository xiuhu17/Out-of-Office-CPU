module instr_serve (
    input logic clk,
    input logic rst,
    input logic ufp_resp,

    input logic [31:0] cpu_ufp_addr,
    input logic [ 3:0] cpu_ufp_rmask,

    output logic [31:0] ufp_addr,
    output logic [ 3:0] ufp_rmask
);

  logic [31:0] internal_cpu_ufp_addr;
  logic [ 3:0] internal_cpu_ufp_rmask;

  always_ff @(posedge clk) begin
    if (rst) begin
      internal_cpu_ufp_addr  <= 32'h0;
      internal_cpu_ufp_rmask <= 4'h0;
    end else begin
      if (ufp_resp) begin
        if (cpu_ufp_rmask != '0) begin
          internal_cpu_ufp_addr  <= cpu_ufp_addr;
          internal_cpu_ufp_rmask <= cpu_ufp_rmask;
        end else begin
          internal_cpu_ufp_addr  <= 32'h0;
          internal_cpu_ufp_rmask <= 4'h0;
        end
      end else begin
        if (internal_cpu_ufp_rmask == '0) begin
          if (cpu_ufp_rmask != '0) begin
            internal_cpu_ufp_addr  <= cpu_ufp_addr;
            internal_cpu_ufp_rmask <= cpu_ufp_rmask;
          end
        end
      end
    end
  end


  always_comb begin
    ufp_addr  = internal_cpu_ufp_addr;
    ufp_rmask = internal_cpu_ufp_rmask;

    if (internal_cpu_ufp_rmask == '0) begin 
      ufp_addr  = cpu_ufp_addr;
      ufp_rmask = cpu_ufp_rmask;
    end 

  end

endmodule
