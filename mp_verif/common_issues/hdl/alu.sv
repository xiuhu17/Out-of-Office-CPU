module alu (
  input               clk,
  input               rst,
  input [63:0]        a,
  input [63:0]        b,
  input               valid_i,
  input [3:0]         op,
  output logic [63:0] z,
  output logic        valid_o
);

  //----------------------------------------------------------------------------
  // Valid signaling
  //----------------------------------------------------------------------------
  // The ALU is currently purely combinational, so it responds as soon as
  // it gets input.
  assign valid_o = valid_i;

  //----------------------------------------------------------------------------
  // Population count implementation
  //----------------------------------------------------------------------------
  // Popcount = number of '1' bits in a
  logic [63:0] popcnt;

  always_comb begin
    foreach (a[i]) begin
      if (a[i]) popcnt = popcnt + 1'b1;
    end
  end

  //----------------------------------------------------------------------------
  // Simple logical/arithmetic operations
  //----------------------------------------------------------------------------
  logic [63:0] land;
  logic [63:0] lor;
  logic [63:0] lnot;
  logic [63:0] add;
  logic [63:0] sub;
  logic [63:0] inc;
  logic [63:0] shl;
  logic [63:0] shr;

  always_comb begin
      land = a & b;
      lor  = a | b;
      lnot = !a;
      add  = a + b;
      sub  = a - b;
      inc  = a + 1'b1;
      shl  = a << b[5:0];
      shr  = a >> b[5:0];
  end

  //----------------------------------------------------------------------------
  // Output MUX
  //----------------------------------------------------------------------------
  always_comb begin
    case (op)
      0: z = land;
      1: z = lor;
      2: z = lnot;
      3: z = add;
      4: z = sub;
      5: z = inc;
      6: z = shl;
      7: z = shr;
      8: z = popcnt;
    endcase
  end

endmodule : alu
