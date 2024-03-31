module alu_rs
  import rv32i_types::*;
#(
    parameter ALU_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 2
) (
    input  logic clk,
    input  logic rst,
    output logic alu_rs_full,

    // assigned issue
    input logic alu_rs_issue,

    // instructions issued from instruction_queue
    input logic [6:0]       opcode,
    input logic [2:0]       funct3,
    input logic [6:0]       funct7,
    input logic [31:0]      imm,
    input logic [31:0]      pc,


    // assigned rob
    input logic [ROB_DEPTH-1:0]   issue_target_rob,

    // 3 sources for rs1, rs2: CDB, regfile, and ROB
    // from regfile(with scoreboard)
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
    // immediate values and target ROB

    // read from CDB for waking up; pop from alu_rs if match
    input logic                   cdb_valid              [CDB_SIZE],
    input logic [  ROB_DEPTH-1:0] cdb_rob                [CDB_SIZE],
    input logic [           31:0] cdb_rd_v               [CDB_SIZE],

    // output result to CDB
    output logic alu_rs_valid,
    output logic [31:0] alu_rs_f,
    output logic [ROB_DEPTH-1:0] alu_rs_rob
);
  
  // number of elements in the ALU_RS
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
  
  // target ROB for the result
  logic [ROB_DEPTH-1:0] target_rob_arr[ALU_RS_NUM_ELEM];

  // counter for traversing stations
  logic [ALU_RS_DEPTH-1:0] counter;
  
  // pop logic
  logic alu_rs_pop;
  logic [ALU_RS_DEPTH-1:0] alu_rs_pop_index;

  // alu and cmp operands
  logic alu_en;
  logic cmp_en;
  logic [2:0]   alu_op;
  logic [2:0]   cmp_op;
  logic [31:0]  a;
  logic [31:0]  b;

  always_ff @(posedge clk) begin
    if (rst) begin
      counter <= '0;
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
        target_rob_arr[i] <= '0;
      end
    end else begin
      // issue logic
      if (alu_rs_issue) begin
        for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
          if (alu_rs_available[i]) begin
            alu_rs_available[i] <= '0;
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

            // for each opcode 
            case (opcode)
              lui_opcode: begin 
                rs1_ready_arr[i] <= '1;
                rs1_v_arr[i] <= '0;
                rs2_ready_arr[i] <= '1;
                rs2_v_arr[i] <= imm;
              end
              auipc_opcode: begin 
                rs1_ready_arr[i] <= '1;
                rs1_v_arr[i] <= pc;
                rs2_ready_arr[i] <= '1;
                rs2_v_arr[i] <= imm; 
              end 
              imm_opcode: begin 
                if (issue_rs1_regfile_ready) begin
                  rs1_ready_arr[i] <= '1;
                  rs1_v_arr[i] <= issue_rs1_regfile_v;
                end else if (issue_rs1_rob_ready) begin
                  rs1_ready_arr[i] <= '1;
                  rs1_v_arr[i] <= issue_rs1_rob_v;
                end else begin
                  rs1_ready_arr[i] <= '0;
                end
                rs2_ready_arr[i] <= '1;
                rs2_v_arr[i] <= imm;
                end 
              reg_opcode: begin 
                if (issue_rs1_regfile_ready) begin
                  rs1_ready_arr[i] <= '1;
                  rs1_v_arr[i] <= issue_rs1_regfile_v;
                end else if (issue_rs1_rob_ready) begin
                  rs1_ready_arr[i] <= '1;
                  rs1_v_arr[i] <= issue_rs1_rob_v;
                end else begin
                  rs1_ready_arr[i] <= '0;
                end
                if (issue_rs2_regfile_ready) begin
                  rs2_ready_arr[i] <= '1;
                  rs2_v_arr[i] <= issue_rs2_regfile_v;
                end else if (issue_rs2_rob_ready) begin
                  rs2_ready_arr[i] <= '1;
                  rs2_v_arr[i] <= issue_rs2_rob_v;
                end else begin
                  rs2_ready_arr[i] <= '0;
                end
              end
            endcase
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
        rs1_ready_arr[alu_rs_pop_index] <= '0;
        rs2_ready_arr[alu_rs_pop_index] <= '0;
        counter <= counter + 1'b1;
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

  // for selecting reservation waking up
  always_comb begin
    alu_rs_pop = '0;
    alu_rs_pop_index = '0;
    alu_rs_valid = '0;
    alu_rs_rob = '0;
    // execution logic
    for (int i = counter; i < ALU_RS_NUM_ELEM; i++) begin
      if (!alu_rs_available[i]) begin
        if (rs1_ready_arr[i] && rs2_ready_arr[i]) begin
          // signal pop in the next cycle
          alu_rs_pop = '1;
          alu_rs_pop_index = i;
          // signal for cdb
          alu_rs_valid = '1;
          alu_rs_rob = target_rob_arr[i];
          break;
        end
      end
    end
  end

  // calculating

  alu clu();
  cmp cmp();

endmodule
