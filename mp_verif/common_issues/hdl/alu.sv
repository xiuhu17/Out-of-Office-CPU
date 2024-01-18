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

  // store the value
  logic [63:0] internal_a, internal_b;
  logic [3:0] internal_op;
  logic [63:0] level_0[4];
  logic [63:0] level_1[2];
  logic [63:0] level_2;
  logic level_0_sig, level_1_sig, level_2_sig;

  enum logic [2:0] {Halted, Sel0, Sel1, Sel2, Sel3}, Curr_State_Q, Next_State_D; 

  always_ff @ ( posedge clk ) begin 
    if (rst) begin 
      Curr_State_Q <= Halted;
    end else if (valid_i && Curr_State_Q == Halted) begin 
      Curr_State_Q <= Sel0;
      internal_op <= op;
      internal_a <= a;
      internal_b <= b;
    end else begin
      Curr_State_Q <= Next_State_D;
    end
  end

  always_comb begin 
    // default
    Next_State_D = Curr_State_Q;
    valid_o = 0;
    level_0_sig = 0;
    level_1_sig = 0;
    level_2_sig = 0; 
    level_3_sig = 0;

    // state
    case(Curr_State_Q)
      Sel0:
          Next_State_D = Sel1;
      Sel1:
          Next_State_D = Sel2;
      Sel2:
          Next_State_D = Sel3;
      Sel3:
          Next_State_D = Halted;
    endcase

    // signal
    case(Curr_State_Q) 
      Sel0:
        level_0_sig = 1;
      Sel1:
        level_1_sig = 1;
      Sel2:
        level_2_sig = 1;
      Sel3:
        level_3_sig = 1;
        valid_o = 1;
    endcase
  end

  // Population count implementation
  logic [63:0] popcnt;

  always_comb begin
    popcnt = 0;
    foreach (internal_a[i]) begin
      if (internal_a[i]) popcnt = popcnt + 1'b1;
    end
  end

  always_ff @ ( posedge clk ) begin 
    if (rst) begin 
      level_0[0] <= 0;
      level_0[1] <= 0;
      level_0[2] <= 0;
      level_0[3] <= 0;
    end else if (level_0_sig) begin 
      if (internal_op[0]) {
        level_0[0] <= internal_a | internal_b;
        level_0[1] <= internal_a + internal_b;
        level_0[2] <= internal_a + 1'b1;
        level_0[3] <= internal_a >> internal_b[5:0];
      } else {
        level_0[0] <= internal_a & internal_b;
        level_0[1] <= !internal_a;
        level_0[2] <= internal_a - internal_b;
        level_0[3] <= internal_a << internal_b[5:0];
      }
    end
  end

  always_ff @ ( posedge clk ) begin 
    if (rst) begin 
      level_1[0] <= 0;
      level_1[1] <= 0;
    end else if (level_1_sig) begin 
      if (internal_op[1]) {
        level_1[0] <= level_0[1];
        level_1[1] <= level_0[3];
      } else {
        level_1[0] <= level_0[0];
        level_1[1] <= level_0[2];
      }
    end
  end

  always_ff @ ( posedge clk ) begin 
    if (rst) begin 
      level_2 <= 0;
    end else if (level_2_sig) begin 
      if (internal_op[2]) {
        level_2 <= level_1[1];
      } else {
        level_2 <= level_1[0];
      }
    end
  end

  always_ff @ ( posedge clk ) begin 
    if (rst) begin 
      z <= 0;
    end else if (level_3_sig) begin 
      if (internal_op[3]) {
        z <= popcnt;
      } else {
        z <= level_2;
      }
    end
  end

endmodule : alu
