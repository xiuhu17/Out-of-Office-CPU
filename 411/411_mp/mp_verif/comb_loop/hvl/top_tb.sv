module top_tb;

  timeunit 1ns;
  timeprecision 1ns;

  //----------------------------------------------------------------------
  // Waveforms.
  //----------------------------------------------------------------------
  initial begin
    $fsdbDumpfile("dump.fsdb");
    $fsdbDumpvars(0, "+all");
  end

  //----------------------------------------------------------------------
  // Generate the clock.
  //----------------------------------------------------------------------
  bit clk;
  initial clk = 1'b1;
  always #5ns clk = ~clk;

  //----------------------------------------------------------------------
  // Generate the reset.
  //----------------------------------------------------------------------
  bit rst;
  task do_reset();
    rst = 1'b1;
    repeat (4) @(posedge clk);
    rst <= 1'b0;
  endtask : do_reset

  //----------------------------------------------------------------------
  // DUT instance.
  //----------------------------------------------------------------------

  logic       ack;

  top dut(.*);

  //----------------------------------------------------------------------
  // Verification tasks/functions
  //----------------------------------------------------------------------
  function display_colored(string s, string color);
    unique case (color)
      "blue": $write("%c[1;34m",27);
      "red": $write("%c[1;31m",27);
      "green": $write("%c[1;32m",27);
    endcase

    $display(s);
    $write("%c[0m",27);
  endfunction

  task verify_loop();
    @(posedge clk);

    repeat (100) begin
      repeat (15) @(posedge clk);
      if (!ack) begin
        display_colored("[FAILED] loop", "red");
        $finish;
      end
    end
    display_colored("[PASSED] loop", "green");
  endtask : verify_loop


  //----------------------------------------------------------------------
  // Main process.
  //----------------------------------------------------------------------
  initial begin
    do_reset();
    verify_loop();
    $finish;
  end

  //----------------------------------------------------------------------
  // Timeout.
  //----------------------------------------------------------------------
  initial begin
    #50us;
    $fatal("Timeout!");
  end

endmodule
