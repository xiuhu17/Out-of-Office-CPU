module top_tb;

    timeunit 1ns;
    timeprecision 1ns;

    bit clk;
    initial clk = 1'b1;
    always #1 clk = ~clk;

    bit rst;

    int timeout = 10000000; // In cycles, change according to your needs

    mem_itf mem_itf(.*);
    mon_itf mon_itf(.*);

    // Pick one of the two options (only one of these should be uncommented at a time):
    // simple_memory simple_memory(.itf(mem_itf)); // For directed testing with PROG
    random_tb random_tb(.itf(mem_itf)); // For randomized testing

    monitor monitor(.itf(mon_itf));

    cpu dut(
        .clk          (clk),
        .rst          (rst),
        .mem_addr     (mem_itf.addr),
        .mem_read     (mem_itf.read),
        .mem_write    (mem_itf.write),
        .mem_wmask    (mem_itf.wmask),
        .mem_rdata    (mem_itf.rdata),
        .mem_wdata    (mem_itf.wdata),
        .mem_resp     (mem_itf.resp)
    );

    always_comb begin
        mon_itf.valid     = dut.monitor_valid;
        mon_itf.order     = dut.monitor_order;
        mon_itf.inst      = dut.monitor_inst;
        mon_itf.rs1_addr  = dut.monitor_rs1_addr;
        mon_itf.rs2_addr  = dut.monitor_rs2_addr;
        mon_itf.rs1_rdata = dut.monitor_rs1_rdata;
        mon_itf.rs2_rdata = dut.monitor_rs2_rdata;
        mon_itf.rd_addr   = dut.monitor_rd_addr;
        mon_itf.rd_wdata  = dut.monitor_rd_wdata;
        mon_itf.pc_rdata  = dut.monitor_pc_rdata;
        mon_itf.pc_wdata  = dut.monitor_pc_wdata;
        mon_itf.mem_addr  = dut.monitor_mem_addr;
        mon_itf.mem_rmask = dut.monitor_mem_rmask;
        mon_itf.mem_wmask = dut.monitor_mem_wmask;
        mon_itf.mem_rdata = dut.monitor_mem_rdata;
        mon_itf.mem_wdata = dut.monitor_mem_wdata;
    end

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        rst = 1'b1;
        repeat (5) @(posedge clk);
        rst = 1'b0;
    end

    always @(posedge clk) begin
        if (mon_itf.halt) begin
            $finish;
        end
        if (timeout == 0) begin
            $error("TB Error: Timed out");
            $finish;
        end
        if (mem_itf.error != 0 || mon_itf.error != 0) begin
            repeat (5) @(posedge clk);
            $finish;
        end
        timeout <= timeout - 1;
    end

endmodule : top_tb
