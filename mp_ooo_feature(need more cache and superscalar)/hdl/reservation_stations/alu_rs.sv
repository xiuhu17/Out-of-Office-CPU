// module alu_rs
//   import rv32i_types::*;
// #(
//     parameter ALU_RS_DEPTH = 3,
//     parameter ROB_DEPTH = 3,
//     parameter CDB_SIZE = 3
// ) (
//     input logic clk,
//     input logic rst,
//     input logic move_flush,

//     output logic alu_rs_full,

//     // assigned issue
//     input logic alu_rs_issue,

//     // instructions issued from instruction_queue
//     input logic [ 6:0] issue_opcode,
//     input logic [ 2:0] issue_funct3,
//     input logic [ 6:0] issue_funct7,
//     input logic [31:0] issue_imm,
//     input logic [31:0] issue_pc,

//     // assigned rob
//     input logic [ROB_DEPTH-1:0] issue_target_rob,

//     // 3 sources for rs1, rs2: CDB, regfile, and ROB
//     // from regfile(with scoreboard)
//     input logic                   issue_rs1_regfile_ready,
//     input logic                   issue_rs2_regfile_ready,
//     input logic [           31:0] issue_rs1_regfile_v,
//     input logic [           31:0] issue_rs2_regfile_v,
//     input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
//     input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,
//     // from ROB
//     input logic [           31:0] issue_rs1_rob_v,
//     input logic [           31:0] issue_rs2_rob_v,
//     input logic                   issue_rs1_rob_ready,
//     input logic                   issue_rs2_rob_ready,

//     // read from CDB for waking up; pop from alu_rs if match
//     input logic                 cdb_valid[CDB_SIZE],
//     input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
//     input logic [         31:0] cdb_rd_v [CDB_SIZE],

//     // output result to CDB
//     output logic cdb_alu_rs_valid,
//     output logic [31:0] cdb_alu_rs_f,
//     output logic [ROB_DEPTH-1:0] cdb_alu_rs_rob
// );

//   // number of elements in the ALU_RS
//   localparam ALU_RS_NUM_ELEM = 2 ** ALU_RS_DEPTH;

//   // internal registers
//   logic                    alu_rs_available [ALU_RS_NUM_ELEM];

//   // instruction information
//   logic [             6:0] opcode_arr       [ALU_RS_NUM_ELEM];
//   logic [             2:0] funct3_arr       [ALU_RS_NUM_ELEM];
//   logic [             6:0] funct7_arr       [ALU_RS_NUM_ELEM];

//   // rs1_ready and rs2_ready determine if the value will be from ROB
//   logic                    rs1_ready_arr    [ALU_RS_NUM_ELEM];
//   logic                    rs2_ready_arr    [ALU_RS_NUM_ELEM];
//   logic [            31:0] rs1_v_arr        [ALU_RS_NUM_ELEM];
//   logic [            31:0] rs2_v_arr        [ALU_RS_NUM_ELEM];
//   logic [   ROB_DEPTH-1:0] rs1_rob_arr      [ALU_RS_NUM_ELEM];
//   logic [   ROB_DEPTH-1:0] rs2_rob_arr      [ALU_RS_NUM_ELEM];

//   // target ROB for the result
//   logic [   ROB_DEPTH-1:0] target_rob_arr   [ALU_RS_NUM_ELEM];

//   // counter for traversing stations
//   logic [ALU_RS_DEPTH-1:0] counter;

//   // pop logic
//   logic                    alu_rs_pop;
//   logic [ALU_RS_DEPTH-1:0] alu_rs_pop_index;

//   // alu and cmp operands
//   logic alu_rs_executing;
//   logic                    exe_alu_valid;
//   logic                    exe_cmp_valid;
//   logic [             2:0] exe_alu_op;
//   logic [             2:0] exe_cmp_op;
//   logic [            31:0] exe_a;
//   logic [            31:0] exe_b;
//   logic [            31:0] exe_alu_f;
//   logic                    exe_cmp_f;

//   always_ff @(posedge clk) begin
//     if (rst || move_flush) begin
//       counter <= '0;
//       for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
//         alu_rs_available[i] <= '1;
//         opcode_arr[i] <= '0;
//         funct3_arr[i] <= '0;
//         funct7_arr[i] <= '0;
//         rs1_ready_arr[i] <= '0;
//         rs2_ready_arr[i] <= '0;
//         rs1_v_arr[i] <= '0;
//         rs2_v_arr[i] <= '0;
//         rs1_rob_arr[i] <= '0;
//         rs2_rob_arr[i] <= '0;
//         target_rob_arr[i] <= '0;
//       end
//     end else begin
//       // issue logic
//       if (alu_rs_issue) begin
//         for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
//           if (alu_rs_available[i]) begin
//             alu_rs_available[i] <= '0;
//             opcode_arr[i] <= issue_opcode;
//             funct3_arr[i] <= issue_funct3;
//             funct7_arr[i] <= issue_funct7;
//             rs1_ready_arr[i] <= '0;
//             rs2_ready_arr[i] <= '0;
//             rs1_v_arr[i] <= '0;
//             rs2_v_arr[i] <= '0;
//             rs1_rob_arr[i] <= issue_rs1_regfile_rob;
//             rs2_rob_arr[i] <= issue_rs2_regfile_rob;
//             target_rob_arr[i] <= issue_target_rob;

//             // for each opcode
//             case (issue_opcode)
//               lui_opcode: begin
//                 rs1_ready_arr[i] <= '1;
//                 rs1_v_arr[i] <= '0;
//                 rs2_ready_arr[i] <= '1;
//                 rs2_v_arr[i] <= issue_imm;
//               end
//               auipc_opcode: begin
//                 rs1_ready_arr[i] <= '1;
//                 rs1_v_arr[i] <= issue_pc;
//                 rs2_ready_arr[i] <= '1;
//                 rs2_v_arr[i] <= issue_imm;
//               end
//               imm_opcode: begin
//                 if (issue_rs1_regfile_ready) begin
//                   rs1_ready_arr[i] <= '1;
//                   rs1_v_arr[i] <= issue_rs1_regfile_v;
//                 end else if (issue_rs1_rob_ready) begin
//                   rs1_ready_arr[i] <= '1;
//                   rs1_v_arr[i] <= issue_rs1_rob_v;
//                 end else begin
//                   rs1_ready_arr[i] <= '0;
//                 end
//                 rs2_ready_arr[i] <= '1;
//                 rs2_v_arr[i] <= issue_imm;
//               end
//               reg_opcode: begin
//                 if (issue_rs1_regfile_ready) begin
//                   rs1_ready_arr[i] <= '1;
//                   rs1_v_arr[i] <= issue_rs1_regfile_v;
//                 end else if (issue_rs1_rob_ready) begin
//                   rs1_ready_arr[i] <= '1;
//                   rs1_v_arr[i] <= issue_rs1_rob_v;
//                 end else begin
//                   rs1_ready_arr[i] <= '0;
//                 end
//                 if (issue_rs2_regfile_ready) begin
//                   rs2_ready_arr[i] <= '1;
//                   rs2_v_arr[i] <= issue_rs2_regfile_v;
//                 end else if (issue_rs2_rob_ready) begin
//                   rs2_ready_arr[i] <= '1;
//                   rs2_v_arr[i] <= issue_rs2_rob_v;
//                 end else begin
//                   rs2_ready_arr[i] <= '0;
//                 end
//               end
//             endcase
//             break;
//           end
//         end
//       end

//       // snoop CDB to update any rs1/rs2 values
//       for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
//         if (!alu_rs_available[i]) begin
//           for (int j = 0; j < CDB_SIZE; j++) begin
//             if (cdb_valid[j] && rs1_ready_arr[i] == 0 && (cdb_rob[j] == rs1_rob_arr[i])) begin
//               rs1_v_arr[i] <= cdb_rd_v[j];
//               rs1_ready_arr[i] <= '1;
//             end
//             if (cdb_valid[j] && rs2_ready_arr[i] == 0 && (cdb_rob[j] == rs2_rob_arr[i])) begin
//               rs2_v_arr[i] <= cdb_rd_v[j];
//               rs2_ready_arr[i] <= '1;
//             end
//           end
//         end
//       end

//       // remove once the result is computed and put on the CDB
//       if (alu_rs_pop) begin
//         alu_rs_available[alu_rs_pop_index] <= '1;
//         rs1_ready_arr[alu_rs_pop_index] <= '0;
//         rs2_ready_arr[alu_rs_pop_index] <= '0;
//         counter <= alu_rs_pop_index + 1'b1;
//       end
//     end
//   end

//   // output whether ALU_RS is full or not
//   always_comb begin
//     alu_rs_full = '1;
//     for (int i = 0; i < ALU_RS_NUM_ELEM; i++) begin
//       if (alu_rs_available[i]) begin
//         alu_rs_full = '0;
//         break;
//       end
//     end
//   end

//   // for selecting reservation waking up
//   always_ff @(posedge clk) begin
//     if (rst || move_flush) begin
//       alu_rs_pop <= '0;
//       alu_rs_pop_index <= '0;
//       cdb_alu_rs_valid <= '0;
//       cdb_alu_rs_rob <= '0;
//       alu_rs_executing <= '0;
//     end else begin 
//         alu_rs_pop <= '0;
//         alu_rs_pop_index <= '0;
//         cdb_alu_rs_valid <= '0;
//         cdb_alu_rs_rob <= '0;
//         alu_rs_executing <= '0;
//         // two cases alu_rs_executing or not
//         for (int unsigned i = 0; i < ALU_RS_NUM_ELEM; i++) begin
//         // valied && ready, then execute and finish in the same cycle
//         if (!alu_rs_available[(ALU_RS_DEPTH)'(i+counter)]) begin
//           if (rs1_ready_arr[(ALU_RS_DEPTH)'(i+counter)] && rs2_ready_arr[(ALU_RS_DEPTH)'(i+counter)]) begin
//             if (alu_rs_executing) begin
//               if (alu_rs_pop_index != (ALU_RS_DEPTH)'(i+counter)) begin
//                 // signal pop in the next cycle
//                 alu_rs_pop <= '1;
//                 alu_rs_pop_index <= (ALU_RS_DEPTH)'(i + counter);
//                 // signal for cdb
//                 cdb_alu_rs_valid <= '1;
//                 cdb_alu_rs_rob <= target_rob_arr[(ALU_RS_DEPTH)'(i+counter)];
//                 alu_rs_executing <= '1;
//                 break;
//               end
//             end else begin
//               // signal pop in the next cycle
//                 alu_rs_pop <= '1;
//                 alu_rs_pop_index <= (ALU_RS_DEPTH)'(i + counter);
//                 // signal for cdb
//                 cdb_alu_rs_valid <= '1;
//                 cdb_alu_rs_rob <= target_rob_arr[(ALU_RS_DEPTH)'(i+counter)];
//                 alu_rs_executing <= '1;
//                 break;
//             end
//           end
//         end
//       end
//     end
//   end

//   // for inputting operand and selection
//   always_comb begin
//     exe_alu_valid = '0;
//     exe_cmp_valid = '0;
//     exe_alu_op = '0;
//     exe_cmp_op = '0;
//     exe_a = rs1_v_arr[alu_rs_pop_index];
//     exe_b = rs2_v_arr[alu_rs_pop_index];
//     case (opcode_arr[alu_rs_pop_index])
//       lui_opcode: begin
//         exe_alu_valid = '1;
//         exe_alu_op = add_alu_op;
//       end
//       auipc_opcode: begin
//         exe_alu_valid = '1;
//         exe_alu_op = add_alu_op;
//       end
//       imm_opcode: begin
//         case (funct3_arr[alu_rs_pop_index])
//           slt_funct3: begin
//             exe_cmp_valid = '1;
//             exe_cmp_op = blt_cmp_op;
//           end
//           sltu_funct3: begin
//             exe_cmp_valid = '1;
//             exe_cmp_op = bltu_cmp_op;
//           end
//           sr_funct3: begin
//             if (funct7_arr[alu_rs_pop_index][5]) begin
//               exe_alu_valid = '1;
//               exe_alu_op = sra_alu_op;
//             end else begin
//               exe_alu_valid = '1;
//               exe_alu_op = srl_alu_op;
//             end
//           end
//           default: begin
//             exe_alu_valid = '1;
//             exe_alu_op = funct3_arr[alu_rs_pop_index];
//           end
//         endcase
//       end
//       reg_opcode: begin
//         case (funct3_arr[alu_rs_pop_index])
//           slt_funct3: begin
//             exe_cmp_valid = '1;
//             exe_cmp_op = blt_cmp_op;
//           end
//           sltu_funct3: begin
//             exe_cmp_valid = '1;
//             exe_cmp_op = bltu_cmp_op;
//           end
//           sr_funct3: begin
//             if (funct7_arr[alu_rs_pop_index][5]) begin
//               exe_alu_valid = '1;
//               exe_alu_op = sra_alu_op;
//             end else begin
//               exe_alu_valid = '1;
//               exe_alu_op = srl_alu_op;
//             end
//           end
//           add_funct3: begin
//             if (funct7_arr[alu_rs_pop_index][5]) begin
//               exe_alu_valid = '1;
//               exe_alu_op = sub_alu_op;
//             end else begin
//               exe_alu_valid = '1;
//               exe_alu_op = add_alu_op;
//             end
//           end
//           default: begin
//             exe_alu_valid = '1;
//             exe_alu_op = funct3_arr[alu_rs_pop_index];
//           end
//         endcase
//       end
//     endcase
//   end

//   // calculating
//   alu clu (
//       .aluop(exe_alu_op),
//       .a(exe_a),
//       .b(exe_b),
//       .f(exe_alu_f)
//   );

//   cmp cmp (
//       .cmpop(exe_cmp_op),
//       .a(exe_a),
//       .b(exe_b),
//       .br_en(exe_cmp_f)
//   );

//   // for outputting
//   always_comb begin
//     cdb_alu_rs_f = '0;
//     if (exe_alu_valid) begin
//       cdb_alu_rs_f = exe_alu_f;
//     end else if (exe_cmp_valid) begin
//       cdb_alu_rs_f = {31'b0, exe_cmp_f};
//     end
//   end

// endmodule

module alu_rs
  import rv32i_types::*;
#(
    parameter ALU_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    output logic alu_rs_full,

    // assigned issue
    input logic alu_rs_issue,

    // instructions issued from instruction_queue
    input logic [ 6:0] issue_opcode,
    input logic [ 2:0] issue_funct3,
    input logic [ 6:0] issue_funct7,
    input logic [31:0] issue_imm,
    input logic [31:0] issue_pc,

    // assigned rob
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    // 3 sources for rs1, rs2: CDB, regfile, and ROB
    // from regfile(with scoreboard)
    input logic                   issue_rs1_regfile_ready,
    input logic                   issue_rs2_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic [           31:0] issue_rs2_regfile_v,
    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,
    // from ROB
    input logic [           31:0] issue_rs1_rob_v,
    input logic [           31:0] issue_rs2_rob_v,
    input logic                   issue_rs1_rob_ready,
    input logic                   issue_rs2_rob_ready,

    // read from CDB for waking up; pop from alu_rs if match
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // output result to CDB
    output logic cdb_alu_rs_valid,
    output logic [31:0] cdb_alu_rs_f,
    output logic [ROB_DEPTH-1:0] cdb_alu_rs_rob
);

  // number of elements in the ALU_RS
  localparam ALU_RS_NUM_ELEM = 2 ** ALU_RS_DEPTH;

  // internal registers
  logic                    alu_rs_available [ALU_RS_NUM_ELEM];

  // instruction information
  logic [             6:0] opcode_arr       [ALU_RS_NUM_ELEM];
  logic [             2:0] funct3_arr       [ALU_RS_NUM_ELEM];
  logic [             6:0] funct7_arr       [ALU_RS_NUM_ELEM];

  // rs1_ready and rs2_ready determine if the value will be from ROB
  logic                    rs1_ready_arr    [ALU_RS_NUM_ELEM];
  logic                    rs2_ready_arr    [ALU_RS_NUM_ELEM];
  logic [            31:0] rs1_v_arr        [ALU_RS_NUM_ELEM];
  logic [            31:0] rs2_v_arr        [ALU_RS_NUM_ELEM];
  logic [   ROB_DEPTH-1:0] rs1_rob_arr      [ALU_RS_NUM_ELEM];
  logic [   ROB_DEPTH-1:0] rs2_rob_arr      [ALU_RS_NUM_ELEM];

  // target ROB for the result
  logic [   ROB_DEPTH-1:0] target_rob_arr   [ALU_RS_NUM_ELEM];

  // counter for traversing stations
  logic [ALU_RS_DEPTH-1:0] counter;

  // pop logic
  logic                    alu_rs_pop;
  logic [ALU_RS_DEPTH-1:0] alu_rs_pop_index;

  // alu and cmp operands
  logic                    exe_alu_valid;
  logic                    exe_cmp_valid;
  logic [             2:0] exe_alu_op;
  logic [             2:0] exe_cmp_op;
  logic [            31:0] exe_a;
  logic [            31:0] exe_b;
  logic [            31:0] exe_alu_f;
  logic                    exe_cmp_f;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
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
            opcode_arr[i] <= issue_opcode;
            funct3_arr[i] <= issue_funct3;
            funct7_arr[i] <= issue_funct7;
            rs1_ready_arr[i] <= '0;
            rs2_ready_arr[i] <= '0;
            rs1_v_arr[i] <= '0;
            rs2_v_arr[i] <= '0;
            rs1_rob_arr[i] <= issue_rs1_regfile_rob;
            rs2_rob_arr[i] <= issue_rs2_regfile_rob;
            target_rob_arr[i] <= issue_target_rob;

            // for each opcode
            case (issue_opcode)
              lui_opcode: begin
                rs1_ready_arr[i] <= '1;
                rs1_v_arr[i] <= '0;
                rs2_ready_arr[i] <= '1;
                rs2_v_arr[i] <= issue_imm;
              end
              auipc_opcode: begin
                rs1_ready_arr[i] <= '1;
                rs1_v_arr[i] <= issue_pc;
                rs2_ready_arr[i] <= '1;
                rs2_v_arr[i] <= issue_imm;
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
                rs2_v_arr[i] <= issue_imm;
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
        counter <= alu_rs_pop_index + 1'b1;
      end
    end
  end

  // output whether ALU_RS is full or not
  always_comb begin
    alu_rs_full = '1;
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
    cdb_alu_rs_valid = '0;
    cdb_alu_rs_rob = '0;
    // execution logic
    for (int unsigned i = 0; i < ALU_RS_NUM_ELEM; i++) begin
      // valied && ready, then execute and finish in the same cycle
      if (!alu_rs_available[(ALU_RS_DEPTH)'(i+counter)]) begin
        if (rs1_ready_arr[(ALU_RS_DEPTH)'(i+counter)] && rs2_ready_arr[(ALU_RS_DEPTH)'(i+counter)]) begin
          // signal pop in the next cycle
          alu_rs_pop = '1;
          alu_rs_pop_index = (ALU_RS_DEPTH)'(i + counter);
          // signal for cdb
          cdb_alu_rs_valid = '1;
          cdb_alu_rs_rob = target_rob_arr[(ALU_RS_DEPTH)'(i+counter)];
          break;
        end
      end
    end
  end

  // for inputting operand and selection
  always_comb begin
    exe_alu_valid = '0;
    exe_cmp_valid = '0;
    exe_alu_op = '0;
    exe_cmp_op = '0;
    exe_a = rs1_v_arr[alu_rs_pop_index];
    exe_b = rs2_v_arr[alu_rs_pop_index];
    case (opcode_arr[alu_rs_pop_index])
      lui_opcode: begin
        exe_alu_valid = '1;
        exe_alu_op = add_alu_op;
      end
      auipc_opcode: begin
        exe_alu_valid = '1;
        exe_alu_op = add_alu_op;
      end
      imm_opcode: begin
        case (funct3_arr[alu_rs_pop_index])
          slt_funct3: begin
            exe_cmp_valid = '1;
            exe_cmp_op = blt_cmp_op;
          end
          sltu_funct3: begin
            exe_cmp_valid = '1;
            exe_cmp_op = bltu_cmp_op;
          end
          sr_funct3: begin
            if (funct7_arr[alu_rs_pop_index][5]) begin
              exe_alu_valid = '1;
              exe_alu_op = sra_alu_op;
            end else begin
              exe_alu_valid = '1;
              exe_alu_op = srl_alu_op;
            end
          end
          default: begin
            exe_alu_valid = '1;
            exe_alu_op = funct3_arr[alu_rs_pop_index];
          end
        endcase
      end
      reg_opcode: begin
        case (funct3_arr[alu_rs_pop_index])
          slt_funct3: begin
            exe_cmp_valid = '1;
            exe_cmp_op = blt_cmp_op;
          end
          sltu_funct3: begin
            exe_cmp_valid = '1;
            exe_cmp_op = bltu_cmp_op;
          end
          sr_funct3: begin
            if (funct7_arr[alu_rs_pop_index][5]) begin
              exe_alu_valid = '1;
              exe_alu_op = sra_alu_op;
            end else begin
              exe_alu_valid = '1;
              exe_alu_op = srl_alu_op;
            end
          end
          add_funct3: begin
            if (funct7_arr[alu_rs_pop_index][5]) begin
              exe_alu_valid = '1;
              exe_alu_op = sub_alu_op;
            end else begin
              exe_alu_valid = '1;
              exe_alu_op = add_alu_op;
            end
          end
          default: begin
            exe_alu_valid = '1;
            exe_alu_op = funct3_arr[alu_rs_pop_index];
          end
        endcase
      end
    endcase
  end

  // calculating
  alu clu (
      .aluop(exe_alu_op),
      .a(exe_a),
      .b(exe_b),
      .f(exe_alu_f)
  );

  cmp cmp (
      .cmpop(exe_cmp_op),
      .a(exe_a),
      .b(exe_b),
      .br_en(exe_cmp_f)
  );

  // for outputting
  always_comb begin
    cdb_alu_rs_f = '0;
    if (exe_alu_valid) begin
      cdb_alu_rs_f = exe_alu_f;
    end else if (exe_cmp_valid) begin
      cdb_alu_rs_f = {31'b0, exe_cmp_f};
    end
  end

endmodule