module cache_dut_tb;
    //---------------------------------------------------------------------------------
    // Time unit setup.
    //---------------------------------------------------------------------------------
    timeunit 1ns;
    timeprecision 1ns;

    //---------------------------------------------------------------------------------
    // Waveform generation.
    //---------------------------------------------------------------------------------
    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
    end

    //---------------------------------------------------------------------------------
    // TODO: Declare cache port signals:
    //---------------------------------------------------------------------------------
    
       logic           clk;
       logic           rst;

    // cpu side signals, ufp -> upward facing port
       logic   [31:0]  ufp_addr;
       logic   [3:0]   ufp_rmask;
       logic   [3:0]   ufp_wmask;
      logic   [31:0]  ufp_rdata;
       logic   [31:0]  ufp_wdata;
      logic           ufp_resp;


    //---------------------------------------------------------------------------------
    // TODO: Generate a clock:
    //---------------------------------------------------------------------------------
  bit clk;
  initial clk = 1'b1;
  always #5ns clk = ~clk; 

    //---------------------------------------------------------------------------------
    // TODO: Write a task to generate reset:
    //---------------------------------------------------------------------------------

  bit rst;
  bit PASSED;
  
  function display_colored(string s, string color);
    unique case (color)
      "blue": $write("%c[1;34m", 27);
      "red": $write("%c[1;31m", 27);
      "green": $write("%c[1;32m", 27);
    endcase

    $display(s);
    $write("%c[0m",27);
  endfunction

  // TODO: Understand this reset task:
  task do_reset();
    rst = 1'b1; // Special case: using a blocking assignment to set rst
                // to 1'b1 at time 0.

    repeat (4) @(posedge clk); // Wait for 4 clock cycles.

    rst <= 1'b0; // Generally, non-blocking assignments when driving DUT
                 // signals.
  endtask : do_reset

    //---------------------------------------------------------------------------------
    // TODO: Instantiate the DUT and physical memory:
    //---------------------------------------------------------------------------------
    mem_itf mem_itf(.*);
    simple_memory simple_memory(.itf(mem_itf));
    cache dut(
    .clk          (clk),
        .rst          (rst),
        .dfp_addr     (mem_itf.addr),
        .dfp_read     (mem_itf.read),
        .dfp_write    (mem_itf.write),
        .dfp_rdata    (mem_itf.rdata),
        .dfp_wdata    (mem_itf.wdata),
        .dfp_resp     (mem_itf.resp),
        .ufp_addr(ufp_addr),
        .ufp_rmask(ufp_rmask),
        .ufp_wmask(ufp_wmask),
        .ufp_rdata(ufp_rdata),
        .ufp_wdata(ufp_wdata),
        .ufp_resp(ufp_resp)       
        );
    


    //---------------------------------------------------------------------------------
    // TODO: Write tasks to test various functionalities:
    //---------------------------------------------------------------------------------
task automatic test_hit_read(logic [31:0] addr, logic [31:0] expect_data, int line);
    PASSED = 1'b1;
    if (addr[1:0] != 2'b00) $fatal("%0t %s %0d: Addr not aligned", $time, `__FILE__, line);
    ufp_addr = addr;
    ufp_rmask = 4'b1111;
    ufp_wmask = '0;
    repeat(2) @(posedge clk);
    
    if (~ufp_resp) begin
    PASSED = 1'b0;
     display_colored("Hit timeout", "red");
     $fatal("%0t %s %0d: Hit timeout", $time, `__FILE__, line);
     end
    if (ufp_rdata !== expect_data) begin
     PASSED = 1'b0;
    display_colored(" Data error", "red");
     $fatal("%0t %s %0d: Data error", $time, `__FILE__, line);
     end
    if (mem_itf.read) begin
     PASSED = 1'b0;
    display_colored(" Should not read from mem", "red");
     $fatal("%0t %s %0d: Should not read from mem", $time, `__FILE__, line);
     end
    if (mem_itf.write) begin
     PASSED = 1'b0;
    display_colored(" Should not write to mem", "red");
     $fatal("%0t %s %0d: Should not write to mem", $time, `__FILE__, line);
     end
    
    if (PASSED) display_colored("[PASSED] CACHE", "green");
    else display_colored("[FAILED] CACHE", "red");
    
    ufp_rmask = '0;
endtask

task automatic test_clean_miss_read(logic [31:0] addr, logic [31:0] expect_data, int line);
    PASSED = 1'b1;
    
    if (addr[1:0] != 2'b00) begin
    PASSED = 1'b0;
    display_colored(" Addr not aligned", "red");
    $fatal("%0t %s %0d: Addr not aligned", $time, `__FILE__, line, "red");
    end
    
    ufp_addr = addr;
    ufp_rmask = 4'b1111;
    ufp_wmask = '0;
    @(posedge clk);
    if (ufp_resp) begin
    PASSED = 1'b0;
    display_colored("Should not hit", "red");
    $fatal("%0t %s %0d: Should not hit", $time, `__FILE__, line, "red");
     end
    @(posedge clk);
    @(negedge clk);
    
    if (~mem_itf.read) begin
    PASSED = 1'b0;
    display_colored("Not reading from mem", "red");
     $fatal("%0t %s %0d: Not reading from mem", $time, `__FILE__, line, "red");   
    end
    if (mem_itf.write) begin
    display_colored("Read/write mem at the same time", "red");
     $fatal("%0t %s %0d: Read/write mem at the same time", $time, `__FILE__, line, "red");
     
     end
    begin 
    @(posedge clk iff mem_itf.resp);
    end
    repeat (2) @(posedge clk);
    if (ufp_rdata !== expect_data) begin
    PASSED = 1'b0; 
    display_colored("Data error", "red");
    $fatal("%0t %s %0d: Data error", $time, `__FILE__, line, "red");
    
    end
    
    if (PASSED) display_colored("[PASSED] CACHE", "green");
    else display_colored("[FAILED] ALU", "red");

    ufp_rmask = '0;
endtask

task automatic test_clean_miss_write(logic [31:0] addr, logic [31:0] wdata, int line);
    PASSED = 1'b1;
   
    if (addr[1:0] != 2'b00) begin
    PASSED = 1'b0;
    display_colored(" Addr not aligned", "red");
    $fatal("%0t %s %0d: Addr not aligned", $time, `__FILE__, line, "red");
    end
   
    ufp_addr = addr;
    ufp_wmask = 4'b1111;
    ufp_rmask = '0;
    ufp_wdata = wdata;
    @(posedge clk);
    if (ufp_resp) begin
    PASSED = 1'b0;
    display_colored("Should not hit", "red");
    $fatal("%0t %s %0d: Should not hit", $time, `__FILE__, line, "red");
     end
    @(posedge clk);
    @(negedge clk);
   
    if (~mem_itf.read) begin
    PASSED = 1'b0;
    display_colored("Not reading from mem", "red");
     $fatal("%0t %s %0d: Not reading from mem", $time, `__FILE__, line, "red");  
    end
    if (mem_itf.write) begin
    display_colored("Read/write mem at the same time", "red");
     $fatal("%0t %s %0d: Read/write mem at the same time", $time, `__FILE__, line, "red");
     
     end
    begin
    @(posedge clk iff mem_itf.resp);
    end
    repeat (2) @(posedge clk);
    if (!ufp_resp) begin
        PASSED = 1'b0;
        display_colored("Write should have hit now man", "red");
        $fatal("%0t %s %0d: Write should have hit now man", $time, `__FILE__, line, "red");
    end

    if (PASSED) display_colored("[PASSED] CACHE", "green");
    else display_colored("[FAILED] ALU", "red");

    ufp_wmask = '0;
    ufp_wdata  = '0;
endtask

task automatic test_dirty_miss_read(logic [31:0] addr, logic [31:0] expect_data, int line);
    PASSED = 1'b1;
    
    if (addr[1:0] != 2'b00) begin
    PASSED = 1'b0;
    display_colored(" Addr not aligned", "red");
    $fatal("%0t %s %0d: Addr not aligned", $time, `__FILE__, line, "red");
    end
    
    ufp_addr = addr;
    ufp_rmask = 4'b1111;
    ufp_wmask = 4'b0000;
    @(posedge clk);
    if (ufp_resp) begin
    PASSED = 1'b0;
    display_colored("Should not hit", "red");
    $fatal("%0t %s %0d: Should not hit", $time, `__FILE__, line, "red");
     end
    @(posedge clk);
    @(negedge clk);
    if (~mem_itf.write) begin 
        PASSED = 1'b0;
        display_colored("Should start write to main mem", "red");
        $fatal("%0t %s %0d: Should start write to main mem", $time, `__FILE__, line, "red");
    end 
    if (mem_itf.read) begin 
        PASSED = 1'b0;
        display_colored("Should not read from main mem", "red");
        $fatal("%0t %s %0d: Should not read from main mem", $time, `__FILE__, line, "red");
    end 
    begin 
    @(posedge clk iff mem_itf.resp);
    end
    @(posedge clk);
    if (~mem_itf.read) begin 
        PASSED = 1'b0;
        display_colored("Should start read from main mem", "red");
        $fatal("%0t %s %0d: Should start read from main mem", $time, `__FILE__, line, "red");
    end 
    if (mem_itf.write) begin 
        PASSED = 1'b0;
        display_colored("Should not write to main mem", "red");
        $fatal("%0t %s %0d: Should start write to main mem", $time, `__FILE__, line, "red");
    end
    begin 
    @(posedge clk iff mem_itf.resp);
    end
    repeat (2) @(posedge clk);
    if (~ufp_resp) begin 
        PASSED = 1'b0;
        display_colored("Should report to cpu", "red");
        $fatal("%0t %s %0d: Should report to cpu", $time, `__FILE__, line, "red");
    end 
    if (ufp_rdata !== expect_data) begin
        PASSED = 1'b0; 
        display_colored("Data error", "red");
        $fatal("%0t %s %0d: Data error", $time, `__FILE__, line, "red");
    end

    if (PASSED) display_colored("[PASSED] CACHE", "green");
    else display_colored("[FAILED] ALU", "red");

    ufp_rmask = 4'b0000;
endtask

task automatic test_dirty_miss_write(logic [31:0] addr, logic [31:0] expect_data, int line);
    PASSED = 1'b1;
    
    if (addr[1:0] != 2'b00) begin
    PASSED = 1'b0;
    display_colored(" Addr not aligned", "red");
    $fatal("%0t %s %0d: Addr not aligned", $time, `__FILE__, line, "red");
    end
    
    ufp_addr = addr;
    ufp_wmask = 4'b1111;
    ufp_rmask = 4'b0000;
    ufp_wdata = expect_data;

    @(posedge clk);
    if (ufp_resp) begin
    PASSED = 1'b0;
    display_colored("Should not hit", "red");
    $fatal("%0t %s %0d: Should not hit", $time, `__FILE__, line, "red");
     end
    @(posedge clk);
    @(negedge clk);
    if (~mem_itf.write) begin 
        PASSED = 1'b0;
        display_colored("Should start write to main mem", "red");
        $fatal("%0t %s %0d: Should start write to main mem", $time, `__FILE__, line, "red");
    end 
    if (mem_itf.read) begin 
        PASSED = 1'b0;
        display_colored("Should not read from main mem", "red");
        $fatal("%0t %s %0d: Should not read from main mem", $time, `__FILE__, line, "red");
    end 
    begin 
    @(posedge clk iff mem_itf.resp);
    end
    @(posedge clk);
    if (~mem_itf.read) begin 
        PASSED = 1'b0;
        display_colored("Should start read from main mem", "red");
        $fatal("%0t %s %0d: Should start read from main mem", $time, `__FILE__, line, "red");
    end 
    if (mem_itf.write) begin 
        PASSED = 1'b0;
        display_colored("Should not write to main mem", "red");
        $fatal("%0t %s %0d: Should start write to main mem", $time, `__FILE__, line, "red");
    end
    begin 
    @(posedge clk iff mem_itf.resp);
    end
    repeat (2) @(posedge clk);
    if (~ufp_resp) begin 
        PASSED = 1'b0;
        display_colored("Should report to cpu", "red");
        $fatal("%0t %s %0d: Should report to cpu", $time, `__FILE__, line, "red");
    end 

    if (PASSED) display_colored("[PASSED] CACHE", "green");
    else display_colored("[FAILED] ALU", "red");

    ufp_wmask = 4'b0000;
    ufp_wdata = '0;
endtask

task automatic test_hit_write(logic [31:0] addr, logic [31:0] wdata, int line);
 PASSED = 1'b1;
    if (addr[1:0] != 2'b00) $fatal("%0t %s %0d: Addr not aligned", $time, `__FILE__, line);
    ufp_addr = addr;
    ufp_wmask = 4'b1111;
    ufp_rmask = '0;
    ufp_wdata = wdata;
    repeat(2) @(posedge clk);
   
    if (~ufp_resp) begin
    PASSED = 1'b0;
     display_colored("Hit timeout", "red");
     $fatal("%0t %s %0d: Hit timeout", $time, `__FILE__, line);
     end
     
    if (mem_itf.read) begin
     PASSED = 1'b0;
    display_colored(" Should not read from mem", "red");
     $fatal("%0t %s %0d: Should not read from mem", $time, `__FILE__, line);
     end
     
    if (mem_itf.write) begin
     PASSED = 1'b0;
    display_colored(" Should not write to mem", "red");
     $fatal("%0t %s %0d: Should not write to mem", $time, `__FILE__, line);
     end

    if (PASSED) display_colored("[PASSED] CACHE", "green");
    else display_colored("[FAILED] CACHE", "red");
   
    ufp_wmask = '0;
    ufp_wdata = '0;
 
endtask


    //---------------------------------------------------------------------------------
    // TODO: Main initial block that calls your tasks, then calls $finish
    //---------------------------------------------------------------------------------
    
    initial begin
    do_reset();
   // verify_hits();
    test_clean_miss_read( 32'h00000000, 32'h00000000,`__LINE__ );
    test_clean_miss_write(32'h00000200, 32'h11111111, `__LINE__);
    test_hit_read(32'h00000200, 32'h11111111, `__LINE__);
    // test_clean_miss_read(32'h00000200, 32'h11111111, `__LINE__);
    test_clean_miss_read(32'h00000400, 32'h22222222, `__LINE__);
    test_clean_miss_read(32'h00000600, 32'h33333333, `__LINE__);
    test_hit_read( 32'h00000000, 32'h00000000,`__LINE__ );
    test_hit_read(32'h00000200, 32'h11111111, `__LINE__);
    test_hit_read(32'h00000400, 32'h22222222, `__LINE__);
    test_hit_read(32'h00000600, 32'h33333333, `__LINE__);
    test_hit_read(32'h00000400, 32'h22222222, `__LINE__);
    test_hit_read( 32'h00000000, 32'h00000000,`__LINE__ );
    test_clean_miss_read(32'h00000800, 32'h44444444, `__LINE__);
    test_dirty_miss_read(32'h00000600, 32'h33333333, `__LINE__);
    test_hit_write(32'h00000600, 32'haaaaaaaa, `__LINE__);
    test_hit_write(32'h00000400, 32'hbbbbbbbb, `__LINE__);
    test_hit_write(32'h00000000, 32'hcccccccc, `__LINE__);
    test_hit_write(32'h00000400, 32'hbbbbbbbb, `__LINE__);
    test_hit_write(32'h00000800, 32'hdddddddd, `__LINE__);
    test_dirty_miss_write(32'h00000200, 32'heeeeeeee, `__LINE__);
    test_dirty_miss_read(32'h00000600, 32'haaaaaaaa, `__LINE__);
    test_dirty_miss_read(32'h00000400, 32'hbbbbbbbb, `__LINE__);
    test_dirty_miss_read(32'h00000000, 32'hcccccccc, `__LINE__);
    test_dirty_miss_read(32'h00000800, 32'hdddddddd, `__LINE__);
    test_hit_read(32'h00000600, 32'haaaaaaaa, `__LINE__);

    // test_read_hit(32'h00000800, 32'h11111111, `__LINE__);
    
    //  test_read_miss(
    //     32'h0000020C,
    //     32'hCCCCCCCC,
    //     `__LINE__
    // );
    
    // test_read_hit(32'h00000218, 32'h99999999, `__LINE__);

  
    // test_read_hit(32'h0000000C, 32'h55555555, `__LINE__);
    // test_read_hit(32'h00000010, 32'h44444444, `__LINE__);
    
    
    //  test_read_miss(
    //     32'h0000002C,
    //     32'h12345678,
    //     `__LINE__
    // );
    
    
    // test_read_hit(32'h00000200, 32'hFFFFFFFF, `__LINE__);
    // test_read_hit(32'h00000008, 32'h66666666, `__LINE__);
    
    // test_read_miss(
    //     32'h0000060C,
    //     32'h403202B3,
    //     `__LINE__
    // );
    
    // test_read_miss(
    //     32'h0000040C,
    //     32'h9876ABCD,
    //     `__LINE__
    // );
    
    //  test_read_miss(
    //     32'h0000080C,
    //     32'h003262B3,
    //     `__LINE__
    // );
    
    
    // test_read_hit(32'h00000000, 32'h88888888, `__LINE__);
    // test_read_hit(32'h0000001C, 32'h11111111, `__LINE__);
    
    // test_read_hit(
    //     32'h00000600,
    //     32'h403202B3,
    //     `__LINE__
    // );
    
    // test_read_hit(
    //     32'h00000400,
    //     32'h9876ABCD,
    //     `__LINE__
    // );
    
    //  test_read_hit(
    //     32'h00000404,
    //     32'h9876ABCD,
    //     `__LINE__
    // );
    
    //   test_read_miss(
    //     32'h0000020C,
    //     32'hCCCCCCCC,
    //     `__LINE__
    // );
    
    // test_read_hit(
    //     32'h00000600,
    //     32'h403202B3,
    //     `__LINE__
    // );
    
    //  test_read_hit(
    //     32'h00000404,
    //     32'h9876ABCD,
    //     `__LINE__
    // );
    
    //   test_read_miss(
    //     32'h0000080C,
    //     32'h003262B3,
    //     `__LINE__
    // );
    
    
    $finish;
  end

  //----------------------------------------------------------------------
  // Timeout.
  //----------------------------------------------------------------------
  initial begin
    #1s;
    $fatal("Timeout!");
  end

endmodule : cache_dut_tb