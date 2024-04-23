module verilator_tb
(
  input         clk,
  input         rst,

  input         rdy,
  input         bmem_resp,
  input [63:0]  bmem_rdata,

  output        bmem_read,
  output        bmem_write,
  output [63:0] bmem_wdata,

  input  [31:0] raddr,
  output [31:0] bmem_address,

  output logic halt,
  output logic error
);
    localparam  RVFI_COMMITS = 8;
   
    mon_itf mon_itf(.*);    
    ventilator_monitor monitor(.itf(mon_itf));

    cpu dut(
        .clk         (clk),
        .rst         (rst),

        .bmem_addr   (bmem_address),
        .bmem_read   (bmem_read),
        .bmem_write  (bmem_write),
        .bmem_rdata  (bmem_rdata),
        .bmem_wdata  (bmem_wdata),

        .bmem_rvalid (bmem_resp),
        .bmem_raddr  (raddr),

        .bmem_ready  (rdy)
    );

   `include "../../hvl/rvfi_reference.svh"

   assign error = mon_itf.error;
 
   always_comb
     begin
        halt = '0;
        for (int i=0; i<RVFI_COMMITS; i++)
          if (mon_itf.halt[i])
            halt = '1;
     end

   longint lcom;
   longint cycles;
   longint total_cycles;
   
   always_ff @ (posedge clk)
     begin
        if (rst)
          begin
             cycles = '0;
             total_cycles = '0;
          end
        else
          begin
             cycles++;
             total_cycles++;

             for (int i=0; i<RVFI_COMMITS; i++)
               if (mon_itf.order[i] % 1000 == 0 && mon_itf.order[i] != lcom && mon_itf.valid[i])
                 begin
                    $fwrite(fd, "COMMIT %8d -- CYCLES: %8d -- IPC 1000: %f -- CUM IPC: %f\n", mon_itf.order[i],
                            total_cycles, real'(1000)/cycles, real'(mon_itf.order[i])/total_cycles);
                    cycles = '0;
                    lcom = mon_itf.order[i];
                    break;
                 end
          end  
     end
   
   // cycle progress logging
   int fd;
   initial fd = $fopen("./progress.ansi", "w");
   final $fclose(fd);
endmodule
