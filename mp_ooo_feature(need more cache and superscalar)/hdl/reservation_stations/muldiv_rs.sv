// module muldiv_rs
//   import rv32i_types::*;
// #(
//     parameter MULDIV_RS_DEPTH = 3,
//     parameter ROB_DEPTH = 3,
//     parameter CDB_SIZE = 3
// ) (
//     input logic clk,
//     input logic rst,
//     input logic move_flush,

//     output logic muldiv_rs_full,

//     input logic muldiv_rs_issue,

//     // instructions issued from instruction_queue
//     input logic [2:0] issue_funct3,

//     // 3 sources for rs1, rs2: CDB, regfile, and ROB
//     // from regfile with scoreboard
//     input logic                   issue_rs1_regfile_ready,
//     input logic                   issue_rs2_regfile_ready,
//     input logic [           31:0] issue_rs1_regfile_v,
//     input logic [           31:0] issue_rs2_regfile_v,
//     input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
//     input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,
//     // from ROB
//     input logic                   issue_rs1_rob_ready,
//     input logic                   issue_rs2_rob_ready,
//     input logic [           31:0] issue_rs1_rob_v,
//     input logic [           31:0] issue_rs2_rob_v,
//     // from CDB
//     input logic                   cdb_valid              [CDB_SIZE],
//     input logic [  ROB_DEPTH-1:0] cdb_rob                [CDB_SIZE],
//     input logic [           31:0] cdb_rd_v               [CDB_SIZE],

//     // target ROB
//     input logic [ROB_DEPTH-1:0] issue_target_rob,

//     // output result to CDB
//     output logic cdb_muldiv_rs_valid,
//     output logic [31:0] cdb_muldiv_rs_p,
//     output logic [ROB_DEPTH-1:0] cdb_muldiv_rs_rob
// );

//   localparam MULDIV_RS_NUM_ELEM = 2 ** MULDIV_RS_DEPTH;
//   // internal registers
//   logic muldiv_rs_available[MULDIV_RS_NUM_ELEM];
//   // instruction information
//   logic [2:0] funct3_arr[MULDIV_RS_NUM_ELEM];
//   // rs1_ready and rs2_ready determine if the value will be from ROB
//   logic rs1_ready_arr[MULDIV_RS_NUM_ELEM];
//   logic rs2_ready_arr[MULDIV_RS_NUM_ELEM];
//   logic [31:0] rs1_v_arr[MULDIV_RS_NUM_ELEM];
//   logic [31:0] rs2_v_arr[MULDIV_RS_NUM_ELEM];
//   logic [ROB_DEPTH-1:0] rs1_rob_arr[MULDIV_RS_NUM_ELEM];
//   logic [ROB_DEPTH-1:0] rs2_rob_arr[MULDIV_RS_NUM_ELEM];
//   // target ROB for the result
//   logic [ROB_DEPTH-1:0] target_rob_arr[MULDIV_RS_NUM_ELEM];

//   // counter for traversing stations
//   logic [MULDIV_RS_DEPTH-1:0] counter;

//   // common
//   logic [ROB_DEPTH-1:0] muldiv_rob_executing;

//   // mul
//   logic mul_rs_pop;
//   logic mul_executing;
//   logic mul_ready;
//   logic mul_start;
//   logic mul_done;
//   logic [MULDIV_RS_DEPTH-1:0] mul_rs_idx_executing;
//   logic [ROB_DEPTH-1:0] mul_rob_executing;
//   logic [31:0] mul_a_executing;
//   logic [31:0] mul_b_executing;
//   logic [2:0]  mul_funct3_executing;
//   logic [1:0] mul_type_executing;
//   logic [63:0] mul_p_executing; 
//   logic [63:0] mul_p_store;

//   // unsigned
//   logic udiv_rs_pop;
//   logic udiv_exectuing;
//   logic udiv_ready;
//   logic udiv_start;
//   logic udiv_done;
//   logic [MULDIV_RS_DEPTH-1:0] udiv_rs_idx_executing;
//   logic [ROB_DEPTH-1:0] udiv_rob_executing;
//   logic [31:0] udiv_a_executing;
//   logic [31:0] udiv_b_executing;
//   logic [2:0]  udiv_funct3_executing;
//   logic [31:0] udiv_q_executing; 
//   logic [31:0] udiv_r_executing; 
//   logic [31:0] udiv_q_store; 
//   logic [31:0] udiv_r_store; 

//   // signed
//   logic sdiv_rs_pop;
//   logic sdiv_executing;
//   logic sdiv_ready;
//   logic sdiv_start;
//   logic sdiv_done;
//   logic [MULDIV_RS_DEPTH-1:0] sdiv_rs_idx_executing;
//   logic [ROB_DEPTH-1:0] sdiv_rob_executing;
//   logic [31:0] sdiv_a_executing;
//   logic [31:0] sdiv_b_executing;
//   logic [2:0]  sdiv_funct3_executing;
//   logic [31:0] sdiv_q_executing; 
//   logic [31:0] sdiv_r_executing; 
//   logic [31:0] sdiv_q_store; 
//   logic [31:0] sdiv_r_store; 

//   always_ff @(posedge clk) begin
//     if (rst || move_flush) begin
//       counter <= '0;
//       for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
//         muldiv_rs_available[i] <= '1;
//         funct3_arr[i] <= '0;
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
//       if (muldiv_rs_issue) begin
//         for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
//           if (muldiv_rs_available[i]) begin
//             muldiv_rs_available[i] <= '0;
//             funct3_arr[i] <= issue_funct3;
//             rs1_ready_arr[i] <= '0;
//             rs2_ready_arr[i] <= '0;
//             rs1_v_arr[i] <= '0;
//             rs2_v_arr[i] <= '0;
//             rs1_rob_arr[i] <= issue_rs1_regfile_rob;
//             rs2_rob_arr[i] <= issue_rs2_regfile_rob;
//             target_rob_arr[i] <= issue_target_rob;

//             // rs1 value logic (check regfile, ROB, CDB in order)
//             if (issue_rs1_regfile_ready) begin
//               rs1_ready_arr[i] <= '1;
//               rs1_v_arr[i] <= issue_rs1_regfile_v;
//             end else if (issue_rs1_rob_ready) begin
//               rs1_ready_arr[i] <= '1;
//               rs1_v_arr[i] <= issue_rs1_rob_v;
//             end else begin
//               rs1_ready_arr[i] <= '0;
//             end

//             // rs2 value logic (check regfile, ROB, CDB in order)
//             if (issue_rs2_regfile_ready) begin
//               rs2_ready_arr[i] <= '1;
//               rs2_v_arr[i] <= issue_rs2_regfile_v;
//             end else if (issue_rs2_rob_ready) begin
//               rs2_ready_arr[i] <= '1;
//               rs2_v_arr[i] <= issue_rs2_rob_v;
//             end else begin
//               rs2_ready_arr[i] <= '0;
//             end
//             break;
//           end
//         end
//       end

//       // snoop CDB to update any rs1/rs2 values
//       for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
//         if (!muldiv_rs_available[i]) begin
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
//       if (mul_rs_pop) begin
//         muldiv_rs_available[mul_rs_idx_executing] <= '1;
//         rs1_ready_arr[mul_rs_idx_executing] <= '0;
//         rs2_ready_arr[mul_rs_idx_executing] <= '0;
//         counter <= mul_rs_idx_executing + 1'b1;
//       end
//       // remove once the result is computed and put on the CDB
//       if (udiv_rs_pop) begin
//         muldiv_rs_available[udiv_rs_idx_executing] <= '1;
//         rs1_ready_arr[udiv_rs_idx_executing] <= '0;
//         rs2_ready_arr[udiv_rs_idx_executing] <= '0;
//         counter <= udiv_rs_idx_executing + 1'b1;
//       end
//       // remove once the result is computed and put on the CDB
//       if (sdiv_rs_pop) begin
//         muldiv_rs_available[sdiv_rs_idx_executing] <= '1;
//         rs1_ready_arr[sdiv_rs_idx_executing] <= '0;
//         rs2_ready_arr[sdiv_rs_idx_executing] <= '0;
//         counter <= sdiv_rs_idx_executing + 1'b1;
//       end
//     end
//   end

//   // output whether MULDIV_RS is full or not
//   always_comb begin
//     muldiv_rs_full = '1;
//     for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
//       if (muldiv_rs_available[i]) begin
//         muldiv_rs_full = '0;
//         break;
//       end
//     end
//   end

//   // store the stage of the muldivtiplier
//   always_ff @(posedge clk) begin
//     if (rst || move_flush) begin
//       mul_executing <= '0;
//       mul_ready <= '0;
//       mul_start <= '0;
//       udiv_exectuing <= '0;
//       udiv_ready <= '0;
//       udiv_start <= '0;
//       sdiv_executing <= '0;
//       sdiv_ready <= '0;
//       sdiv_start <= '0;
//     end else begin
//         for (int unsigned i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
//           // valid & ready & spare muldivtiplier, then execute
//           if (!muldiv_rs_available[(MULDIV_RS_DEPTH)'(i+counter)]) begin
//             if (rs1_ready_arr[(MULDIV_RS_DEPTH)'(i+counter)] && rs2_ready_arr[(MULDIV_RS_DEPTH)'(i+counter)]) begin
//               case (funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)])
//                 mul_funct3, mulh_funct3: begin
//                   if (!mul_executing) begin 
//                     mul_executing <= '1;
//                     mul_start <= '1;
//                     mul_ready <= '0;
//                     mul_type_executing <= mul_signed_signed;
//                     mul_funct3_executing <= funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_rs_idx_executing <= (MULDIV_RS_DEPTH)'(i + counter);
//                     mul_rob_executing <= target_rob_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_a_executing <= rs1_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_b_executing <= rs2_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                   end
//                 end
//                 mulhsu_funct3: begin
//                    if (!mul_executing) begin 
//                     mul_executing <= '1;
//                     mul_start <= '1;
//                     mul_ready <= '0;
//                     mul_type_executing <= mul_signed_unsigned;
//                     mul_funct3_executing <= funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_rs_idx_executing <= (MULDIV_RS_DEPTH)'(i + counter);
//                     mul_rob_executing <= target_rob_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_a_executing <= rs1_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_b_executing <= rs2_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                   end
//                 end
//                 mulhu_funct3: begin
//                    if (!mul_executing) begin 
//                     mul_executing <= '1;
//                     mul_start <= '1;
//                     mul_ready <= '0;
//                     mul_type_executing <= mul_unsigned_unsigned;
//                     mul_funct3_executing <= funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_rs_idx_executing <= (MULDIV_RS_DEPTH)'(i + counter);
//                     mul_rob_executing <= target_rob_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_a_executing <= rs1_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     mul_b_executing <= rs2_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                   end
//                 end
//                 udiv_funct3, urem_funct3: begin
//                   if (!udiv_exectuing) begin 
//                     udiv_exectuing <= '1;
//                     udiv_start <= '1;
//                     udiv_ready <= '0;
//                     udiv_funct3_executing <= funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     udiv_rs_idx_executing <= (MULDIV_RS_DEPTH)'(i + counter);
//                     udiv_rob_executing <= target_rob_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     udiv_a_executing <= rs1_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     udiv_b_executing <= rs2_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                   end
//                 end
//                 div_funct3, rem_funct3: begin
//                   if (!sdiv_executing) begin 
//                     sdiv_executing <= '1;
//                     sdiv_start <= '1;
//                     sdiv_ready <= '0;
//                     sdiv_funct3_executing <= funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     sdiv_rs_idx_executing <= (MULDIV_RS_DEPTH)'(i + counter);
//                     sdiv_rob_executing <= target_rob_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     sdiv_a_executing <= rs1_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                     sdiv_b_executing <= rs2_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
//                   end
//                 end
//               endcase
//             end
//           end
//       end
//       if (mul_start) begin
//         mul_start <= '0;
//       end
//       if (udiv_start) begin
//         udiv_start <= '0;
//       end
//       if (sdiv_start) begin
//         sdiv_start <= '0;
//       end
//       if (mul_rs_pop) begin 
//         mul_executing <= '0;
//         mul_ready <= '0;
//       end
//       if (udiv_rs_pop) begin 
//         udiv_exectuing <= '0;
//         udiv_ready <= '0;
//       end
//       if (sdiv_rs_pop) begin 
//         sdiv_executing <= '0;
//         sdiv_ready <= '0;
//       end
//       if (mul_executing && mul_done) begin
//         mul_ready <= '1;
//         mul_p_store <= mul_p_executing;
//       end
//       if (udiv_exectuing && udiv_done && !udiv_start) begin
//         udiv_ready <= '1;
//         udiv_q_store <= udiv_q_executing;
//         udiv_r_store <= udiv_r_executing;
//       end
//       if (sdiv_executing && sdiv_done && !sdiv_start) begin
//         sdiv_ready <= '1;
//         sdiv_q_store <= sdiv_q_executing;
//         sdiv_r_store <= sdiv_r_executing;
//       end
//     end
//   end

//   always_comb begin
//     cdb_muldiv_rs_valid = '0;
//     cdb_muldiv_rs_rob = '0;
//     cdb_muldiv_rs_p = '0;
//     mul_rs_pop = '0;
//     udiv_rs_pop = '0;
//     sdiv_rs_pop = '0;
//     if (mul_ready) begin 
//       mul_rs_pop = '1;
//       cdb_muldiv_rs_valid = '1;
//       cdb_muldiv_rs_rob = mul_rob_executing;
//       case (mul_funct3_executing)
//         mul_funct3: cdb_muldiv_rs_p = mul_p_store[31:0];
//         mulh_funct3, mulhsu_funct3, mulhu_funct3: cdb_muldiv_rs_p = mul_p_store[63:32];
//       endcase
//     end else if(udiv_ready) begin 
//       udiv_rs_pop = '1;
//       cdb_muldiv_rs_valid = '1;
//       cdb_muldiv_rs_rob = udiv_rob_executing;
//       case (udiv_funct3_executing)
//         udiv_funct3: cdb_muldiv_rs_p = udiv_q_store;
//         urem_funct3: cdb_muldiv_rs_p = udiv_r_store;
//       endcase
//     end else if (sdiv_ready) begin 
//       sdiv_rs_pop = '1;
//       cdb_muldiv_rs_valid = '1;
//       cdb_muldiv_rs_rob = sdiv_rob_executing;
//       case (sdiv_funct3_executing)
//         div_funct3: cdb_muldiv_rs_p = sdiv_q_store;
//         rem_funct3: cdb_muldiv_rs_p = sdiv_r_store;
//       endcase
//     end
//   end

//   dadda_multiplier32 dadda_multiplier32 (
//       .clk(clk),
//       .rst(rst),
//       .move_flush(move_flush),
//       .start(mul_start),
//       .mul_type(mul_type_executing),
//       .a(mul_a_executing),
//       .b(mul_b_executing),
//       .p(mul_p_executing),
//       .done(mul_done)
//   );

//   DW_div_seq #(32, 32, 0, 16, 0, 0, 1, 0) 
//     udiv (
//     .clk(clk),
//     .rst_n(~(rst || move_flush)),
//     .hold('0),
//     .start(udiv_start),
//     .a(udiv_a_executing),
//     .b(udiv_b_executing),
//     .complete(udiv_done),
//     .quotient(udiv_q_executing),
//     .remainder(udiv_r_executing)
//   );

//     DW_div_seq #(32, 32, 1, 16, 0, 0, 1, 0) 
//       sdiv (
//       .clk(clk),
//       .rst_n(~(rst || move_flush)),
//       .hold('0),
//       .start(sdiv_start),
//       .a(sdiv_a_executing),
//       .b(sdiv_b_executing),
//       .complete(sdiv_done),
//       .quotient(sdiv_q_executing),
//       .remainder(sdiv_r_executing)
//     );
// endmodule

module muldiv_rs
  import rv32i_types::*;
#(
    parameter MULDIV_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    output logic muldiv_rs_full,

    input logic muldiv_rs_issue,

    // instructions issued from instruction_queue
    input logic [2:0] issue_funct3,

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
    output logic cdb_muldiv_rs_valid,
    output logic [31:0] cdb_muldiv_rs_p,
    output logic [ROB_DEPTH-1:0] cdb_muldiv_rs_rob
);

  localparam MULDIV_RS_NUM_ELEM = 2 ** MULDIV_RS_DEPTH;
  // internal registers
  logic muldiv_rs_available[MULDIV_RS_NUM_ELEM];
  // instruction information
  logic [2:0] funct3_arr[MULDIV_RS_NUM_ELEM];
  // rs1_ready and rs2_ready determine if the value will be from ROB
  logic rs1_ready_arr[MULDIV_RS_NUM_ELEM];
  logic rs2_ready_arr[MULDIV_RS_NUM_ELEM];
  logic [31:0] rs1_v_arr[MULDIV_RS_NUM_ELEM];
  logic [31:0] rs2_v_arr[MULDIV_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs1_rob_arr[MULDIV_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs2_rob_arr[MULDIV_RS_NUM_ELEM];
  // target ROB for the result
  logic [ROB_DEPTH-1:0] target_rob_arr[MULDIV_RS_NUM_ELEM];

  // counter for traversing stations
  logic [MULDIV_RS_DEPTH-1:0] counter;

  // common
  logic muldiv_rs_pop;
  logic [2:0]  funct3_executing;
  logic [31:0] a_executing;
  logic [31:0] b_executing;
  logic [MULDIV_RS_DEPTH-1:0] muldiv_rs_idx_executing;
  logic [ROB_DEPTH-1:0] muldiv_rob_executing;

  // mul
  logic mul_executing;
  logic mul_start;
  logic mul_done;
  logic [1:0] mul_type_executing;
  logic [63:0] mul_p_executing; 

  // unsigned
  logic udiv_exectuing;
  logic udiv_start;
  logic udiv_done;
  logic [31:0] udiv_q_executing; 
  logic [31:0] udiv_r_executing; 


  // signed
  logic sdiv_executing;
  logic sdiv_start;
  logic sdiv_done;
  logic [31:0] sdiv_q_executing; 
  logic [31:0] sdiv_r_executing; 

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      counter <= '0;
      for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
        muldiv_rs_available[i] <= '1;
        funct3_arr[i] <= '0;
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
      if (muldiv_rs_issue) begin
        for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
          if (muldiv_rs_available[i]) begin
            muldiv_rs_available[i] <= '0;
            funct3_arr[i] <= issue_funct3;
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
      for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
        if (!muldiv_rs_available[i]) begin
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
      if (muldiv_rs_pop) begin
        muldiv_rs_available[muldiv_rs_idx_executing] <= '1;
        rs1_ready_arr[muldiv_rs_idx_executing] <= '0;
        rs2_ready_arr[muldiv_rs_idx_executing] <= '0;
        counter <= muldiv_rs_idx_executing + 1'b1;
      end
    end
  end

  // output whether MULDIV_RS is full or not
  always_comb begin
    muldiv_rs_full = '1;
    for (int i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
      if (muldiv_rs_available[i]) begin
        muldiv_rs_full = '0;
        break;
      end
    end
  end

  // store the stage of the muldivtiplier
  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      funct3_executing <= '0;
      a_executing <= '0;
      b_executing <= '0;
      muldiv_rs_idx_executing <= '0;
      muldiv_rob_executing <= '0;
      mul_start <= '0;
      mul_type_executing <= '0;
      udiv_start <= '0;
      sdiv_start <= '0;
      mul_executing <= '0;
      udiv_exectuing <= '0;
      sdiv_executing <= '0;
    end else begin
      if (!(mul_executing || udiv_exectuing || sdiv_executing)) begin
        for (int unsigned i = 0; i < MULDIV_RS_NUM_ELEM; i++) begin
          // valid & ready & spare muldivtiplier, then execute
          if (!muldiv_rs_available[(MULDIV_RS_DEPTH)'(i+counter)]) begin
            if (rs1_ready_arr[(MULDIV_RS_DEPTH)'(i+counter)] && rs2_ready_arr[(MULDIV_RS_DEPTH)'(i+counter)]) begin
              funct3_executing <= funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)];
              a_executing <= rs1_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
              b_executing <= rs2_v_arr[(MULDIV_RS_DEPTH)'(i+counter)];
              muldiv_rs_idx_executing <= (MULDIV_RS_DEPTH)'(i + counter);
              muldiv_rob_executing <= target_rob_arr[(MULDIV_RS_DEPTH)'(i+counter)];
              case (funct3_arr[(MULDIV_RS_DEPTH)'(i+counter)])
                mul_funct3, mulh_funct3: begin
                  mul_executing <= '1;
                  mul_start <= '1;
                  mul_type_executing <= mul_signed_signed;
                  udiv_start <= '0;
                  sdiv_start <= '0;
                end
                mulhsu_funct3: begin
                  mul_executing <= '1;
                  mul_start <= '1;
                  mul_type_executing <= mul_signed_unsigned;
                  udiv_start <= '0;
                  sdiv_start <= '0;
                end
                mulhu_funct3: begin
                  mul_executing <= '1;
                  mul_start <= '1;
                  mul_type_executing <= mul_unsigned_unsigned;
                  udiv_start <= '0;
                  sdiv_start <= '0;
                end
                udiv_funct3, urem_funct3: begin
                  udiv_exectuing <= '1;
                  mul_start <= '0;
                  udiv_start <= '1;
                  sdiv_start <= '0;
                end
                div_funct3, rem_funct3: begin
                  sdiv_executing <= '1;
                  mul_start <= '0;
                  udiv_start <= '0;
                  sdiv_start <= '1;
                end
              endcase
              break;
            end
          end
        end
      end
      if (mul_start) begin
        mul_start <= '0;
      end
      if (udiv_start) begin
        udiv_start <= '0;
      end
      if (sdiv_start) begin
        sdiv_start <= '0;
      end
      if (mul_executing && mul_done) begin
        mul_executing <= '0;
      end
      if (udiv_exectuing && udiv_done && !udiv_start) begin
        udiv_exectuing <= '0;
      end
      if (sdiv_executing && sdiv_done && !sdiv_start) begin
        sdiv_executing <= '0;
      end
    end
  end

  always_comb begin
    cdb_muldiv_rs_valid = '0;
    muldiv_rs_pop = '0;
    cdb_muldiv_rs_rob = '0;
    cdb_muldiv_rs_p = '0;
    if ((mul_executing && mul_done) || (udiv_exectuing && udiv_done && !udiv_start) || (sdiv_executing && sdiv_done && !sdiv_start)) begin
      cdb_muldiv_rs_valid = '1;
      muldiv_rs_pop = '1;
      cdb_muldiv_rs_rob = muldiv_rob_executing;
      cdb_muldiv_rs_p = '0;
      case (funct3_executing)
        mul_funct3: cdb_muldiv_rs_p = mul_p_executing[31:0];
        mulh_funct3, mulhsu_funct3, mulhu_funct3: cdb_muldiv_rs_p = mul_p_executing[63:32];
        udiv_funct3: cdb_muldiv_rs_p = udiv_q_executing;
        urem_funct3: cdb_muldiv_rs_p = udiv_r_executing;
        div_funct3: cdb_muldiv_rs_p = sdiv_q_executing;
        rem_funct3: cdb_muldiv_rs_p = sdiv_r_executing;
      endcase
    end
  end

  dadda_multiplier32 dadda_multiplier32 (
      .clk(clk),
      .rst(rst),
      .move_flush(move_flush),
      .start(mul_start),
      .mul_type(mul_type_executing),
      .a(a_executing),
      .b(b_executing),
      .p(mul_p_executing),
      .done(mul_done)
  );

  DW_div_seq #(32, 32, 0, 16, 0, 0, 1, 0) 
    udiv (
    .clk(clk),
    .rst_n(~(rst || move_flush)),
    .hold('0),
    .start(udiv_start),
    .a(a_executing),
    .b(b_executing),
    .complete(udiv_done),
    .quotient(udiv_q_executing),
    .remainder(udiv_r_executing)
  );

    DW_div_seq #(32, 32, 1, 16, 0, 0, 1, 0) 
      sdiv (
      .clk(clk),
      .rst_n(~(rst || move_flush)),
      .hold('0),
      .start(sdiv_start),
      .a(a_executing),
      .b(b_executing),
      .complete(sdiv_done),
      .quotient(sdiv_q_executing),
      .remainder(sdiv_r_executing)
    );

endmodule