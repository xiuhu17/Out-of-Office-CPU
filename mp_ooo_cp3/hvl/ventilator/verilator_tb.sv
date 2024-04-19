module verilator_tb
(
  input         clk,
  input         rst,

  input         bmem_resp,
  input [63:0]  bmem_rdata,

  output        bmem_read,
  output        bmem_write,
  output [63:0] bmem_wdata,

  output [31:0] bmem_address,

  output logic halt,
  output logic error
);
    // Set below to "1" if you are ready to use superscalar
    // Requires two parameters - ROB_COMMITS, which is how many commits your ROB can handle at a time
    // Also requires RVFI_COMMITS, which is how many channels RVFI has
    // requires some changes to monitor.sv and mon_itf.sv, as well as your DUT. Will come in future MP_OOO patchset
    localparam  SUPERSCALAR = 0;
    localparam  ROB_COMMITS = 1;
    localparam  RVFI_COMMITS = 1;
   
    mon_itf mon_itf(.*);    
    ventilator_monitor monitor(.itf(mon_itf));

    cpu dut(
        .clk          (clk),
        .rst          (rst),

        .bmem_addr    (bmem_address),
        .bmem_read    (bmem_read),
        .bmem_write   (bmem_write),
        .bmem_rdata   (bmem_rdata),
        .bmem_wdata   (bmem_wdata),
        .bmem_resp    (bmem_resp)
    );

   `include "../../hvl/rvfi_reference.svh"

   assign error = mon_itf.error;
 
   generate
      if (SUPERSCALAR)
        begin
           int i;
           always_comb
             begin
                halt = '0;
                for (i=0; i<RVFI_COMMITS; i++)
                  if (mon_itf.halt[i])
                    halt = '1;
             end
        end
      else
        assign halt = mon_itf.halt;
   endgenerate

   longint lcom;
   longint cycles;
   longint total_cycles;
   
   generate
      if (SUPERSCALAR)
        begin
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

                     for (int i=0; i<ROB_COMMITS; i++)
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
        end
      else
        begin
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

                     for (int i=0; i<ROB_COMMITS; i++)
                       if (mon_itf.order % 1000 && mon_itf.valid)
                         begin
                            $fwrite(fd, "COMMIT %8d -- CYCLES: %8d -- IPC 1000: %f -- CUM IPC: %f\n", mon_itf.order,
                                    total_cycles, real'(1000)/cycles, real'(mon_itf.order)/total_cycles);
                            cycles = '0;
                         end
                  end  
             end
        end   
   endgenerate
   
   // cycle progress logging
   int fd;
   initial fd = $fopen("./progress.ansi", "w");
   final $fclose(fd);
endmodule
