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
  bit          en;
  logic        rand_bit;
  logic [15:0] shift_reg;

  lfsr dut (
    .clk       (clk),
    .rst       (rst),
    .en        (en),
    .rand_bit  (rand_bit),
    .shift_reg (shift_reg)
  );


  //----------------------------------------------------------------------
  // LFSR modeling and verification API.
  //----------------------------------------------------------------------
  localparam bit [15:0] SEED_VALUE = 'hECEB;

  function bit lfsr_next(ref bit [15:0] state);
    bit new_bit;
    bit ret;

    new_bit = state[0] ^ state[2] ^ state[3] ^ state[5];
    ret = state[0];
    state >>= 1;
    state |= new_bit << 15;
    return ret;
  endfunction : lfsr_next

  function display_colored(string s, string color);
    unique case (color)
      "blue": $write("%c[1;34m",27);
      "red": $write("%c[1;31m",27);
      "green": $write("%c[1;32m",27);
    endcase

    $display(s);
    $write("%c[0m",27);
  endfunction

  function check_values(
    bit [15:0] shift_reg,
    bit [15:0] shift_reg_shadow,
    bit        rand_bit,
    bit        rand_bit_shadow
  );
    if (shift_reg !== shift_reg_shadow) begin
      display_colored($sformatf
                      ("[%0t ns] Expected shift_reg value of %x, got %x",
                       $time, shift_reg_shadow, shift_reg), "red");
      display_colored("[FAILED] sv_refresher", "red");
      $finish;
    end
    if (rand_bit !== rand_bit_shadow) begin
      display_colored($sformatf
                      ("[%0t ns] Expected rand_bit value of %x, got %x",
                       $time, rand_bit_shadow, rand_bit), "red");
      display_colored("[FAILED] sv_refresher", "red");
      $finish;
    end
  endfunction : check_values

  task verify_lfsr();
    bit [15:0] shift_reg_shadow;
    bit        rand_bit_shadow;
    int        delay;

    shift_reg_shadow = SEED_VALUE;

    repeat (2**16 - 1) begin
      en <= 1'b1;
      @(posedge clk);
      en <= 1'b0;
      @(posedge clk);
      rand_bit_shadow = lfsr_next(shift_reg_shadow);
      check_values(shift_reg, shift_reg_shadow, rand_bit, rand_bit_shadow);
      std::randomize(delay) with { delay inside {[0:3]}; };
      repeat (delay) @(posedge clk);
    end

    // Check that LFSR is maximal-length (spec provides primitive polynomial)
    if (shift_reg !== SEED_VALUE) begin
      $fatal("Shift register not of maximum period.");
      display_colored("[FAILED] sv_refresher", "red");
      $finish;
    end

    display_colored("[PASSED] sv_refresher", "green");
  endtask : verify_lfsr


  //----------------------------------------------------------------------
  // Main process.
  //----------------------------------------------------------------------
  initial begin
    do_reset();
    verify_lfsr();
    $finish;
  end

  //----------------------------------------------------------------------
  // Timeout.
  //----------------------------------------------------------------------
  initial begin
    #1s;
    $fatal("Timeout!");
  end

endmodule
