module top_tb;

  // TODO: Complete all the TODOs to get a working testbench!

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
  // Coverage
  //----------------------------------------------------------------------
  `include "../../hvl/coverage.svh"
  cg cg_inst = new;

  //----------------------------------------------------------------------
  // Generate the clock.
  //----------------------------------------------------------------------
  bit clk;
  initial clk = 1'b1;
  always #5ns clk = ~clk; // Always drive clocks with blocking assignment.

  //----------------------------------------------------------------------
  // Generate the reset.
  //----------------------------------------------------------------------
  bit rst;

  // TODO: Understand this reset task:
  task do_reset();
    rst = 1'b1; // Special case: using a blocking assignment to set rst
                // to 1'b1 at time 0.

    repeat (4) @(posedge clk); // Wait for 4 clock cycles.

    rst <= 1'b0; // Generally, non-blocking assignments when driving DUT
                 // signals.
  endtask : do_reset

  //----------------------------------------------------------------------
  // DUT instance.
  //----------------------------------------------------------------------
  logic [63:0] a;
  logic [63:0] b;
  logic        valid_i;
  logic [3:0]  op;
  logic [63:0] z;
  logic        valid_o;

  alu dut (
    .clk     (clk),
    .rst     (rst)
    // TODO: hook up the rest of the DUT signals!
  );


  //----------------------------------------------------------------------
  // Verification helper functions/tasks.
  //----------------------------------------------------------------------
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

  function sample_cg(bit [63:0] a, bit [63:0] b, bit [3:0] op);
    cg_inst.sample(a, b, op, b[5:0]);
  endfunction : sample_cg

  task do_transaction (
    logic [63:0] a_in,
    logic [63:0] b_in,
    logic [3:0]  op_in,
    logic [63:0] exp_z_out
  );

    // TODO: Drive the DUT signals:
    // valid_i <= ...;
    // a <= ...;
    // ...

    // Fork...join runs N processes in parallel and joins once the
    // last one finishes.
    fork
      begin
        // Deassert the signals after a cycle.
        @(posedge clk);
        valid_i <= 1'b0;
        a <= 'x;
        b <= 'x;
        op <= 'x;
      end

      begin
        // Wait for the ALU to respond.
        // TODO: Complete this statement.
        // @(posedge clk iff ...);
      end
    join

    if (z !== exp_z_out) begin
      display_colored($sformatf
                      ("[%0t ns] op == %x: Expected alu result (z) %x, got %x",
                       $time, op_in, exp_z_out, z), "red");
      PASSED = 1'b0;
    end
  endtask : do_transaction


  task verify_alu();
    bit [63:0] a_rand;
    bit [63:0] b_rand;
    bit [63:0] exp_z;

    PASSED = 1'b1;

    // For each kind of operation, send one transaction.
    // TODO: Modify this code to cover all coverpoints in coverage.svh.
    for (int i = 0; i < 9; ++i) begin
      std::randomize(a_rand);
      // TODO: Randomize b_rand using std::randomize.

      case (i)
        0: exp_z = a_rand & b_rand;
        1: exp_z = a_rand | b_rand;
        // TODO: Fill out the rest of the operations.
      endcase

      do_transaction(a_rand, b_rand, i, exp_z);

      // TODO: Call the sample_cg function with the right arguments.
      // This tells the covergroup about what stimulus you sent
      // to the DUT.

      // sample_cg(...);
    end

    if (PASSED) display_colored("[PASSED] ALU", "green");
    else display_colored("[FAILED] ALU", "red");
  endtask : verify_alu

  //----------------------------------------------------------------------
  // Main process.
  //----------------------------------------------------------------------
  initial begin
    do_reset();
    verify_alu();
    $finish;
  end

  //----------------------------------------------------------------------
  // Timeout.
  //----------------------------------------------------------------------
  initial begin
    #1s;
    $fatal("Timeout!");
  end

  //----------------------------------------------------------------------
  // Final coverage checking.
  //----------------------------------------------------------------------
  `include "../../hvl/final.svh"

endmodule
