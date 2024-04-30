module branch_rs
  import rv32i_types::*;
#(
    parameter BRANCH_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    // control signal
    input logic branch_rs_issue,

    // output signal
    output logic branch_rs_full,

    // issue input data
    input logic [          6:0] issue_opcode,
    input logic [          2:0] issue_funct3,
    input logic [         31:0] issue_imm,
    input logic [         31:0] issue_pc,
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    // 3 sources for rs1, rs2: CDB, regfile, rob
    // from regfile
    input logic                   issue_rs1_regfile_ready,
    input logic                   issue_rs2_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic [           31:0] issue_rs2_regfile_v,
    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,

    // from ROB
    input logic [31:0] issue_rs1_rob_v,
    input logic [31:0] issue_rs2_rob_v,
    input logic        issue_rs1_rob_ready,
    input logic        issue_rs2_rob_ready,

    // snoop from CDB
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // output result to CDB
    output logic cdb_branch_rs_valid,
    output logic [31:0] cdb_branch_rs_v,
    output logic [ROB_DEPTH-1:0] cdb_branch_rs_rob,

    // output target branch_pc
    output logic cdb_branch_take,
    output logic [31:0] cdb_branch_target_pc
);

  localparam BRANCH_RS_NUM_ELEM = 2 ** BRANCH_RS_DEPTH;

  // valid and ready
  logic                       branch_rs_available [BRANCH_RS_NUM_ELEM];
  logic                       rs1_ready_arr       [BRANCH_RS_NUM_ELEM];
  logic                       rs2_ready_arr       [BRANCH_RS_NUM_ELEM];

  // internal data
  logic [                6:0] opcode_arr          [BRANCH_RS_NUM_ELEM];
  logic [                2:0] funct3_arr          [BRANCH_RS_NUM_ELEM];
  logic [               31:0] imm_arr             [BRANCH_RS_NUM_ELEM];
  logic [               31:0] pc_arr              [BRANCH_RS_NUM_ELEM];

  // rs1, rs2, target_rob
  logic [               31:0] rs1_v_arr           [BRANCH_RS_NUM_ELEM];
  logic [               31:0] rs2_v_arr           [BRANCH_RS_NUM_ELEM];
  logic [      ROB_DEPTH-1:0] rs1_rob_arr         [BRANCH_RS_NUM_ELEM];
  logic [      ROB_DEPTH-1:0] rs2_rob_arr         [BRANCH_RS_NUM_ELEM];
  logic [      ROB_DEPTH-1:0] target_rob_arr      [BRANCH_RS_NUM_ELEM];

  // pop logic
  logic                       branch_rs_pop;
  logic [BRANCH_RS_DEPTH-1:0] branch_rs_pop_index;

  // counter for traversing stations
  logic [BRANCH_RS_DEPTH-1:0] counter;

  // 
  logic                       br_en;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      counter <= '0;
      for (int i = 0; i < BRANCH_RS_NUM_ELEM; i++) begin
        branch_rs_available[i] <= '1;
        opcode_arr[i] <= '0;
        funct3_arr[i] <= '0;
        imm_arr[i] <= '0;
        pc_arr[i] <= '0;
        rs1_ready_arr[i] <= '0;
        rs2_ready_arr[i] <= '0;
        rs1_v_arr[i] <= '0;
        rs2_v_arr[i] <= '0;
        rs1_rob_arr[i] <= '0;
        rs2_rob_arr[i] <= '0;
        target_rob_arr[i] <= '0;
      end
    end else begin
      if (branch_rs_issue) begin
        for (int i = 0; i < BRANCH_RS_NUM_ELEM; i++) begin
          if (branch_rs_available[i]) begin
            branch_rs_available[i] <= '0;
            opcode_arr[i] <= issue_opcode;
            funct3_arr[i] <= issue_funct3;
            imm_arr[i] <= issue_imm;
            pc_arr[i] <= issue_pc;
            rs1_ready_arr[i] <= '0;
            rs2_ready_arr[i] <= '0;
            rs1_v_arr[i] <= '0;
            rs2_v_arr[i] <= '0;
            rs1_rob_arr[i] <= issue_rs1_regfile_rob;
            rs2_rob_arr[i] <= issue_rs2_regfile_rob;
            target_rob_arr[i] <= issue_target_rob;

            case (issue_opcode)
              // target addr: pc + imm
              // write to register: pc + 4
              jal_opcode: begin
                rs1_ready_arr[i] <= '1;
                rs2_ready_arr[i] <= '1;
              end
              // target addr: rs1_v + imm
              // write to register: pc + 4
              jalr_opcode: begin
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
              end
              // need rs1_v rs2_v to calculate whether take or not: pc + imm
              // do not write to register
              br_opcode: begin
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
      for (int i = 0; i < BRANCH_RS_NUM_ELEM; i++) begin
        if (!branch_rs_available[i]) begin
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

      // remove once the result is computed
      if (branch_rs_pop) begin
        branch_rs_available[branch_rs_pop_index] <= '1;
        rs1_ready_arr[branch_rs_pop_index] <= '0;
        rs2_ready_arr[branch_rs_pop_index] <= '0;
        counter <= branch_rs_pop_index + 1'b1;
      end
    end
  end


  // output whether branch_rs is full or not
  always_comb begin
    branch_rs_full = '1;
    for (int i = 0; i < BRANCH_RS_NUM_ELEM; i++) begin
      if (branch_rs_available[i]) begin
        branch_rs_full = '0;
        break;
      end
    end
  end

  // for selecting reservation waking up
  always_comb begin
    branch_rs_pop = '0;
    branch_rs_pop_index = '0;
    cdb_branch_rs_rob = '0;
    cdb_branch_rs_valid = '0;
    // execution logic
    for (int unsigned i = 0; i < BRANCH_RS_NUM_ELEM; i++) begin
      // valied && ready, then execute and finish in the same cycle
      if (!branch_rs_available[(BRANCH_RS_DEPTH)'(i+counter)]) begin
        if (rs1_ready_arr[(BRANCH_RS_DEPTH)'(i + counter)] && rs2_ready_arr[(BRANCH_RS_DEPTH)'(i + counter)]) begin
          // signal pop in the next cycle
          branch_rs_pop = '1;
          branch_rs_pop_index = (BRANCH_RS_DEPTH)'(i + counter);
          // branch rob
          cdb_branch_rs_rob = target_rob_arr[(BRANCH_RS_DEPTH)'(i+counter)];
          cdb_branch_rs_valid = '1;
          break;
        end
      end
    end
  end

  always_comb begin
    cdb_branch_take = '0;
    cdb_branch_target_pc = '0;
    cdb_branch_rs_v = '0;

    case (opcode_arr[branch_rs_pop_index])
      jal_opcode: begin
        cdb_branch_take = '1;
        cdb_branch_target_pc = pc_arr[branch_rs_pop_index] + imm_arr[branch_rs_pop_index];
        cdb_branch_rs_v = pc_arr[branch_rs_pop_index] + 32'h4;
      end
      jalr_opcode: begin
        cdb_branch_take = '1;
        cdb_branch_target_pc = rs1_v_arr[branch_rs_pop_index] + imm_arr[branch_rs_pop_index];
        cdb_branch_rs_v = pc_arr[branch_rs_pop_index] + 32'h4;
      end
      br_opcode: begin
        if (br_en) begin
          cdb_branch_take = '1;
          cdb_branch_target_pc = pc_arr[branch_rs_pop_index] + imm_arr[branch_rs_pop_index];
        end else begin 
          cdb_branch_take = '0;
          cdb_branch_target_pc = pc_arr[branch_rs_pop_index] + 32'h4;
        end 
      end
    endcase
  end

  cmp cmp (
      .cmpop(funct3_arr[branch_rs_pop_index]),
      .a(rs1_v_arr[branch_rs_pop_index]),
      .b(rs2_v_arr[branch_rs_pop_index]),
      .br_en(br_en)
  );

endmodule
