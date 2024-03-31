module alu_rs #(
    parameter ALU_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 2
) (
    input  logic clk,
    input  logic rst,
    output logic alu_rs_full,

    input logic alu_rs_issue,

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
    // read from CDB for waking up; pop from alu_rs if match
    input logic                   cdb_valid              [CDB_SIZE],
    input logic [  ROB_DEPTH-1:0] cdb_rob                [CDB_SIZE],
    input logic [           31:0] cdb_rd_v               [CDB_SIZE],

    // immediate values and target ROB
    input logic [31:0] imm,
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    // output result to CDB
    output logic alu_rs_valid,
    output logic [31:0] alu_rs_f,
    output logic [ROB_DEPTH-1:0] alu_rs_rob
);

  localparam ALU_RS_NUM_ELEM = 2 ** ALU_RS_DEPTH;
  // internal registers
  logic alu_rs_available[ALU_RS_NUM_ELEM];
  // instruction information
  logic [6:0] opcode_arr[ALU_RS_NUM_ELEM];
  logic [2:0] funct3_arr[ALU_RS_NUM_ELEM];
  logic [6:0] funct7_arr[ALU_RS_NUM_ELEM];
  // rs1_ready and rs2_ready determine if the value will be from ROB
  logic rs1_ready_arr[ALU_RS_NUM_ELEM];
  logic rs2_ready_arr[ALU_RS_NUM_ELEM];
  logic [31:0] rs1_v_arr[ALU_RS_NUM_ELEM];
  logic [31:0] rs2_v_arr[ALU_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs1_rob_arr[ALU_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs2_rob_arr[ALU_RS_NUM_ELEM];
  // immediate values can be known from the instruction
  logic [31:0] imm_arr[ALU_RS_NUM_ELEM];
  // target ROB for the result
  logic [ROB_DEPTH-1:0] target_rob_arr[ALU_RS_NUM_ELEM];

  // counter for traversing stations
  logic [ALU_RS_DEPTH-1:0] counter;
  // pop logic
  logic alu_rs_pop;
  logic [ALU_RS_DEPTH-1:0] alu_rs_pop_index;

  // ALU operands
  logic [3:0] aluop;
  logic [31:0] alu_a;
  logic [31:0] alu_b;


  always_ff @(posedge clk) begin
    if (rst) begin
      for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
        alu_rs_available[i] <= '1;
        opcode_arr[i] <= '0;
        funct3_arr[i] <= '0;
        funct7_arr[i] <= '0;
        rs1_ready_arr[i] <= '0;
        rs2_ready_arr[i] <= '0;
        rs1_v_arr[i] <= '0;
        rs2_v_arr[i] <= '0;
        rs1_rob_arr[i] <= '0;
        rs2_rob_arr[i] <= '0;
        imm_arr[i] <= '0;
        target_rob_arr[i] <= '0;
      end
      counter <= '0;
    end else begin
      // issue logic
      if (alu_rs_issue) begin
        for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
          if (alu_rs_available[i]) begin
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
            imm_arr[i] <= imm;
            target_rob_arr[i] <= issue_target_rob;
            alu_rs_available[i] <= '0;
            break;
          end
        end
      end

      // snoop CDB to update any rs1/rs2 values
      for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
        if (!alu_rs_available[i]) begin
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
      if (alu_rs_pop) begin
        alu_rs_available[alu_rs_pop_index] <= '1;
        counter <= counter + 1'b1;
      end
    end
  end

  always_comb begin
    alu_a = '0;
    alu_b = '0;
    alu_rs_valid = '0;
    alu_rs_rob = '0;
    alu_rs_pop = '0;
    alu_rs_pop_index = '0;
    // execution logic
    for (int i = counter; i < ALU_RS_NUM_ELEM; i++) begin
      if (!alu_rs_available[i]) begin
        if (rs1_ready_arr[i] && rs2_ready_arr[i]) begin
          // start execution
          alu_a = rs1_v_arr[i];
          alu_b = rs2_v_arr[i];
          alu_rs_valid = '1;
          alu_rs_rob = target_rob_arr[i];
          // signal pop in the next cycle
          alu_rs_pop = '1;
          alu_rs_pop_index = i;
          break;
        end
      end
    end
  end

  // output whether ALU_RS is full or not
  always_comb begin
    for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
      if (alu_rs_available[i]) begin
        alu_rs_full = '0;
        break;
      end
    end
  end

  alu alu (
      .aluop(aluop),
      .a(alu_a),
      .b(alu_b),
      .f(alu_rs_f)
  );

endmodule
