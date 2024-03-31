module mul_rs
  import rv32i_types::*;
#(
    parameter MUL_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 2
) (
    input  logic clk,
    input  logic rst,
    output logic mul_rs_full,

    input logic mul_rs_issue,

    // instructions issued from instruction_queue
    input logic [6:0] opcode,
    input logic [2:0] funct3,
    input logic [6:0] funct7,

    // 3 sources for rs1, rs2: CDB, regfile, and ROB
    // from regfile with scoreboard
    input logic                   issue_rs1_regfile_ready,
    input logic                   issue_rs2_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic [           31:0] issue_rs2_regfile_v,
    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,
    // from ROB
    input logic                   issue_rs1_rob_ready,
    input logic                   issue_rs2_rob_ready,
    input logic [           31:0] issue_rs1_rob_v,
    input logic [           31:0] issue_rs2_rob_v,
    // from CDB
    input logic                   cdb_valid              [CDB_SIZE],
    input logic [  ROB_DEPTH-1:0] cdb_rob                [CDB_SIZE],
    input logic [           31:0] cdb_rd_v               [CDB_SIZE],

    // target ROB
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    // output result to CDB
    output logic mul_rs_valid,
    output logic [31:0] mul_rs_f,
    output logic [ROB_DEPTH-1:0] mul_rs_rob
);

  localparam MUL_RS_NUM_ELEM = 2 ** MUL_RS_DEPTH;
  // internal registers
  logic mul_rs_available[MUL_RS_NUM_ELEM];
  // instruction information
  logic [6:0] opcode_arr[MUL_RS_NUM_ELEM];
  logic [2:0] funct3_arr[MUL_RS_NUM_ELEM];
  logic [6:0] funct7_arr[MUL_RS_NUM_ELEM];
  // rs1_ready and rs2_ready determine if the value will be from ROB
  logic rs1_ready_arr[MUL_RS_NUM_ELEM];
  logic rs2_ready_arr[MUL_RS_NUM_ELEM];
  logic [31:0] rs1_v_arr[MUL_RS_NUM_ELEM];
  logic [31:0] rs2_v_arr[MUL_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs1_rob_arr[MUL_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs2_rob_arr[MUL_RS_NUM_ELEM];
  // target ROB for the result
  logic [ROB_DEPTH-1:0] target_rob_arr[MUL_RS_NUM_ELEM];

  // counter for traversing stations
  logic [MUL_RS_DEPTH-1:0] counter;
  // pop logic
  logic mul_rs_pop;
  logic [MUL_RS_DEPTH-1:0] mul_rs_pop_index;

  // multiplier operands
  logic [1:0] mul_type;
  logic [31:0] mul_a;
  logic [31:0] mul_b;
  logic [63:0] mul_p;  // result is 64 bits, we output 32 bits based on funct3
  logic mul_start;
  logic mul_done;
  logic mul_executing;
  logic mul_rs_idx_executing;
  logic mul_rob_executing;

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
      for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
        mul_rs_available[i] <= '1;
        opcode_arr[i] <= '0;
        funct3_arr[i] <= '0;
        funct7_arr[i] <= '0;
        rs1_ready_arr[i] <= '0;
        rs2_ready_arr[i] <= '0;
        rs1_v_arr[i] <= '0;
        rs2_v_arr[i] <= '0;
        rs1_rob_arr[i] <= '0;
        rs2_rob_arr[i] <= '0;
        target_rob_arr[i] <= '0;
      end
    end else begin
      // issue logic
      if (mul_rs_issue) begin
        for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
          if (mul_rs_available[i]) begin
            mul_rs_available[i] <= '0;
            opcode_arr[i] <= opcode;
            funct3_arr[i] <= funct3;
            funct7_arr[i] <= funct7;
            rs1_ready_arr[i] <= '0;
            rs2_ready_arr[i] <= '0;
            rs1_v_arr[i] <= '0;
            rs2_v_arr[i] <= '0;
            rs1_rob_arr[i] <= issue_rs1_regfile_rob;
            rs2_rob_arr[i] <= issue_rs2_regfile_rob;
            target_rob_arr[i] <= issue_target_rob;
            
            // rs1 value logic (check regfile, ROB, CDB in order)
            if (issue_rs1_regfile_ready) begin
              rs1_ready_arr[i] <= '1;
              rs1_v_arr[i] <= issue_rs1_regfile_v;
            end else if (issue_rs1_rob_ready) begin
              rs1_ready_arr[i] <= '1;
              rs1_v_arr[i] <= issue_rs1_rob_v;
            end else begin
              rs1_ready_arr[i] <= '0;
            end

            // rs2 value logic (check regfile, ROB, CDB in order)
            if (issue_rs2_regfile_ready) begin
              rs2_ready_arr[i] <= '1;
              rs2_v_arr[i] <= issue_rs2_regfile_v;
            end else if (issue_rs2_rob_ready) begin
              rs2_ready_arr[i] <= '1;
              rs2_v_arr[i] <= issue_rs2_rob_v;
            end else begin
              rs2_ready_arr[i] <= '0;
            end
            break;
          end
        end
      end

      // snoop CDB to update any rs1/rs2 values
      for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
        if (!mul_rs_available[i]) begin
          for (int j = 0; j < CDB_SIZE; j++) begin
            if (cdb_valid[j] && rs1_ready_arr[i] == 0 && (cdb_rob[j] == rs1_rob_arr[i])) begin
              rs1_v_arr[i] <= cdb_rd_v[j];
              rs1_ready_arr[i] <= '1;
            end
            if (cdb_valid[j] && rs2_ready_arr[i] == 0 && (cdb_rob[j] == rs2_rob_arr[i])) begin
              rs2_v_arr[i] <= cdb_rd_v[j];
              rs2_ready_arr[i] <= '1;
            end
          end
        end
      end

      // remove once the result is computed and put on the CDB
      if (mul_rs_pop) begin
        mul_rs_available[mul_rs_pop_index] <= '1;
        rs1_ready_arr[mul_rs_pop_index] <= '0;
        rs2_ready_arr[mul_rs_pop_index] <= '0;
        counter <= mul_rs_pop_index + 1'b1;
      end
    end
  end

  // output whether MUL_RS is full or not
  always_comb begin
    mul_rs_full = '1;
    for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
      if (mul_rs_available[i] == 1) begin
        mul_rs_full = '0;
        break;
      end
    end
  end

  always_ff @(posedge clk) begin
    for (int i = counter; i < MUL_RS_NUM_ELEM; i++) begin
      // valied && ready, then execute and finish in the same cycle
      if (!mul_rs_available[i]) begin
        if (rs1_ready_arr[i] && rs2_ready_arr[i]) begin
          if (!mul_executing) begin 
            mul_executing <= '1;
            mul_rs_idx_executing <= i;
            mul_rob_executing <= target_rob_arr[i];
            mul_start <= '1;
          end 
          break;
        end
      end
    end
  end


  shift_add_multiplier multiplier (
      .clk(clk),
      .rst(rst),
      .start(),
      .mul_type(),
      .a(),
      .b(),
      .p(),
      .done()
  );

endmodule
