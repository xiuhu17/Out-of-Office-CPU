module top_tb;

    timeunit 1ps;
    timeprecision 1ps;

    int clock_half_period_ps = 5;

    bit clk;
    always #(clock_half_period_ps) clk = ~clk;

    bit rst;

    int timeout = 50000000; // in cycles, change according to your needs

    mem_itf mem_itf_i(.*);
    mem_itf mem_itf_d(.*);
    magic_dual_port mem(.itf_i(mem_itf_i), .itf_d(mem_itf_d));
    // ordinary_dual_port mem(.itf_i(mem_itf_i), .itf_d(mem_itf_d));
    // random_tb random_tb(.itf_i(mem_itf_i), .itf_d(mem_itf_d));

    mon_itf mon_itf(.*);    
    monitor monitor(.itf(mon_itf));

    cpu dut(
        .clk            (clk),
        .rst            (rst),

        .imem_addr      (mem_itf_i.addr),
        .imem_rmask     (mem_itf_i.rmask),
        .imem_rdata     (mem_itf_i.rdata),
        .imem_resp      (mem_itf_i.resp),

        .dmem_addr      (mem_itf_d.addr),
        .dmem_rmask     (mem_itf_d.rmask),
        .dmem_wmask     (mem_itf_d.wmask),
        .dmem_rdata     (mem_itf_d.rdata),
        .dmem_wdata     (mem_itf_d.wdata)
        ,.dmem_resp      (mem_itf_d.resp)
    );


    `include "../../hvl/rvfi_reference.svh"

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst <= 1'b0;
    end

    always @(posedge clk) begin
        if (mon_itf.halt) begin
            $finish;
        end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $finish;
        end
        if (mon_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $finish;
        end
        if (mem_itf_i.error != 0) begin
            repeat (5) @(posedge clk);
            $finish;
        end
        if (mem_itf_d.error != 0) begin
            repeat (5) @(posedge clk);
            $finish;
        end
        timeout <= timeout - 1;
    end

endmodule
