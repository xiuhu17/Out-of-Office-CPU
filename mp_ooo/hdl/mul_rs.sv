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

  always_ff @(posedge clk) begin
    if (rst) begin
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
      counter <= '0;
    end else begin
      // issue logic
      if (mul_rs_issue) begin
        for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
          if (mul_rs_available[i]) begin
            opcode_arr[i] <= opcode;
            funct3_arr[i] <= funct3;
            funct7_arr[i] <= funct7;
            // rs1 value logic (check regfile, ROB, CDB in order)
            if (issue_rs1_regfile_ready) begin
              rs1_v_arr[i] <= issue_rs1_regfile_v;
              rs1_ready_arr[i] <= '1;
            end else begin
              if (issue_rs1_rob_ready) begin
                rs1_v_arr[i] <= issue_rs1_rob_v;
                rs1_ready_arr[i] <= '1;
              end else begin
                rs1_rob_arr[i]   <= issue_rs1_regfile_rob;
                rs1_ready_arr[i] <= '0;
              end
            end
            // rs2 value logic (check regfile, ROB, CDB in order)
            if (issue_rs2_regfile_ready) begin
              rs2_v_arr[i] <= issue_rs2_regfile_v;
              rs2_ready_arr[i] <= '1;
            end else begin
              if (issue_rs2_rob_ready) begin
                rs2_v_arr[i] <= issue_rs2_rob_v;
                rs2_ready_arr[i] <= '1;
              end else begin
                rs2_rob_arr[i]   <= issue_rs2_regfile_rob;
                rs2_ready_arr[i] <= '0;
              end
            end
            target_rob_arr[i]   <= issue_target_rob;
            mul_rs_available[i] <= '0;
            break;
          end
        end
      end
      // snoop CDB to update any rs1/rs2 values
      for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
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
      // remove once the result is computed and put on the CDB
      if (mul_rs_pop) begin
        mul_rs_available[mul_rs_pop_index] <= '1;
        counter <= counter + 1'b1;
      end
    end
  end

  always_comb begin
    mul_a = '0;
    mul_b = '0;
    mul_start = '0;
    mul_rs_valid = '0;
    mul_rs_rob = '0;
    mul_rs_pop = '0;
    mul_rs_pop_index = '0;
    // check if execution is done
    if (mul_done) begin
      mul_rs_valid = '1;
      // output the result based on funct3
      unique case (funct3)
        mul: mul_rs_f = mul_p[31:0];
        mulh, mulhsu, mulhu: mul_rs_f = mul_p[63:32];
        default: mul_rs_f = 'x;
      endcase
      mul_rs_rob = target_rob_arr[counter];
      // signal pop in the next cycle
      mul_rs_pop = '1;
      mul_rs_pop_index = counter;
    end else begin
      // execution logic (only execute when multiplier in IDLE state)
      for (int i = counter; i < MUL_RS_NUM_ELEM; i++) begin
        if (mul_rs_available[i] == '0) begin
          if (rs1_ready_arr[i] && rs2_ready_arr[i]) begin
            // decode funct3 to mul_type
            unique case (funct3)
              mul: mul_type = mul_unsigned_unsigned;
              mulh: mul_type = mul_signed_signed;
              mulhsu: mul_type = mul_signed_unsigned;
              mulhu: mul_type = mul_unsigned_unsigned;
              default: mul_type = 2'b00;
            endcase
            // start execution
            mul_a = rs1_v_arr[i];
            mul_b = rs2_v_arr[i];
            mul_start = '1;
            counter = i;  // use counter to keep track of which station is executing
            break;
          end
        end
      end
    end
  end

  // output whether MUL_RS is full or not
  always_comb begin
    for (int i = 0; i < MUL_RS_NUM_ELEM; i++) begin
      if (mul_rs_available[i] == 1) begin
        mul_rs_full = '0;
        break;
      end
    end
  end

  shift_add_multiplier multiplier (
      .clk(clk),
      .rst(rst),
      .start(mul_start),
      .mul_type(mul_type),
      .a(mul_a),
      .b(mul_b),
      .p(mul_p),
      .done(mul_done)
  );

endmodule
