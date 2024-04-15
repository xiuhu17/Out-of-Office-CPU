// module store_rs
// import rv32i_types::*;
// #(
//     parameter STORE_RS_DEPTH = 3,
//     parameter ROB_DEPTH = 3,
//     parameter CDB_SIZE = 3,
//     parameter STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH
// ) 
// (
//     input logic clk,
//     input logic rst,
    
//     // input signal
//     input logic store_rs_issue,
//     input logic store_rs_pop,

//     // output signal
//     output logic store_rs_full,
//     output logic store_rs_valid,
//     output logic store_rs_ready,
//     // for writing to dmem purpose
//     output logic [ROB_DEPTH-1:0] store_rs_rob,

//     // issue input data
//     input logic [ 2:0] issue_funct3,
//     input logic [31:0] issue_imm,
//     input logic [ROB_DEPTH-1:0] issue_target_rob,
//     input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
//     input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,
//     input logic                   issue_rs1_regfile_ready,
//     input logic                   issue_rs2_regfile_ready,
//     input logic [           31:0] issue_rs1_regfile_v,
//     input logic [           31:0] issue_rs2_regfile_v,
//     input logic                   issue_rs1_rob_ready,
//     input logic                   issue_rs2_rob_ready,
//     input logic [           31:0] issue_rs1_rob_v,
//     input logic [           31:0] issue_rs2_rob_v,
//     output logic [STORE_RS_DEPTH:0] issue_store_rs_counter,
//     output logic [STORE_RS_DEPTH-1:0] issue_store_rs_tail,

//     // snoop cdb data
//     input logic                 cdb_valid[CDB_SIZE],
//     input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
//     input logic [         31:0] cdb_rd_v [CDB_SIZE],

//     // forward to load queue
//     output logic forward_w_valid[STORE_RS_NUM_ELEM],
//     output logic forward_w_ready[STORE_RS_NUM_ELEM],
//     output logic [31:0] forward_waddr[STORE_RS_NUM_ELEM],
//     output logic [3:0] forward_wmask[STORE_RS_NUM_ELEM],
//     output logic [31:0] forward_wdata[STORE_RS_NUM_ELEM]
// );

//     // valid and ready
//     logic valid_arr[STORE_RS_NUM_ELEM];
//     logic rs1_ready_arr    [STORE_RS_NUM_ELEM];
//     logic rs2_ready_arr    [STORE_RS_NUM_ELEM];

//     // issuing value
//     logic [ 2:0] funct3_arr[STORE_RS_NUM_ELEM];
//     logic [31:0] imm_arr[STORE_RS_NUM_ELEM];

//     // operands
//     logic [            31:0] rs1_v_arr        [STORE_RS_NUM_ELEM];
//     logic [            31:0] rs2_v_arr        [STORE_RS_NUM_ELEM];
//     logic [   ROB_DEPTH-1:0] rs1_rob_arr      [STORE_RS_NUM_ELEM];
//     logic [   ROB_DEPTH-1:0] rs2_rob_arr      [STORE_RS_NUM_ELEM];
//     logic [ROB_DEPTH-1:0]    target_rob_arr [STORE_RS_NUM_ELEM];

//     // 
//     logic [STORE_RS_DEPTH-1:0] head;
//     logic [STORE_RS_DEPTH-1:0] tail;
//     // avoid overflow
//     logic [STORE_RS_DEPTH:0] counter;


//     always_comb begin 
//         store_rs_full = '0;
//         if (valid_arr[head]) begin 
//             store_rs_full = '1;
//         end 

//         store_rs_valid = valid_arr[tail];
//         store_rs_ready = rs1_ready_arr[tail] && rs2_ready_arr[tail];

//         // for comparsion to ROB, and decide whether write to dmem or not
//         store_rs_rob = target_rob_arr[tail];

//         // assigning the snapshot of head and tail to load_rs
//         issue_store_rs_counter = counter;
//         issue_store_rs_tail = tail;
//     end 

//     always_ff @(posedge clk) begin 
//         if (rst) begin 
//             head <= '0;
//             tail <= '0;
//             counter <= '0;
//             for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin 
//                 valid_arr[i] <= '0;
//                 funct3_arr[i] <= '0;
//                 imm_arr[i] <= '0;
//                 rs1_ready_arr[i] <= '0;
//                 rs2_ready_arr[i] <= '0;
//                 rs1_v_arr[i] <= '0;
//                 rs2_v_arr[i] <= '0;
//                 rs1_rob_arr[i] <= '0;
//                 rs2_rob_arr[i] <= '0;
//                 target_rob_arr[i] <= '0;
//             end
//         end else begin 
//             if (store_rs_pop) begin 
//                 valid_arr[tail] <= '0;
//                 rs1_ready_arr[tail] <= '0;
//                 rs2_ready_arr[tail] <= '0;
//                 tail <= tail + 1'b1;
//                 counter <= counter - 1'b1;
//             end 

//             for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin 
//                 if (valid_arr[i]) begin 
//                     for (int j = 0; j < CDB_SIZE; j++) begin 
//                         if (cdb_valid[j] && (rs1_ready_arr[i] == '0) && (rs1_rob_arr[i] == cdb_rob[j])) begin
//                             rs1_ready_arr[i] <= '1;
//                             rs1_v_arr[i] <= cdb_rd_v[j];
//                         end 
//                         if (cdb_valid[j] && (rs2_ready_arr[i] == '0) && (rs2_rob_arr[i] == cdb_rob[j])) begin
//                             rs2_ready_arr[i] <= '1;
//                             rs2_v_arr[i] <= cdb_rd_v[j];
//                         end
//                     end 
//                 end 
//             end

//             if (store_rs_issue) begin 
//                 valid_arr[head] <= '1;
//                 funct3_arr[head] <= issue_funct3;
//                 imm_arr[head] <= issue_imm;
//                 rs1_ready_arr[head] <= '0;
//                 rs2_ready_arr[head] <= '0;
//                 rs1_v_arr[head] <= '0;
//                 rs2_v_arr[head] <= '0;
//                 rs1_rob_arr[head] <= issue_rs1_regfile_rob;
//                 rs2_rob_arr[head] <= issue_rs2_regfile_rob;
//                 target_rob_arr[head] <= issue_target_rob;
//                 counter <= counter + 1'b1;

//                 if (issue_rs1_regfile_ready) begin 
//                     rs1_ready_arr[head] <= '1;
//                     rs1_v_arr[head] <= issue_rs1_regfile_v;
//                 end else if (issue_rs1_rob_ready) begin 
//                     rs1_ready_arr[head] <= '1;
//                     rs1_v_arr[head] <= issue_rs1_rob_v;
//                 end else begin 
//                     rs1_ready_arr[head] <= '0;
//                 end 

//                 if (issue_rs2_regfile_ready) begin 
//                     rs2_ready_arr[head] <= '1;
//                     rs2_v_arr[head] <= issue_rs2_regfile_v;
//                 end else if (issue_rs2_rob_ready) begin 
//                     rs2_ready_arr[head] <= '1;
//                     rs2_v_arr[head] <= issue_rs2_rob_v;
//                 end else begin 
//                     rs2_ready_arr[head] <= '0;
//                 end

//                 head <= head + 1'b1;
//             end 
//         end 
//     end 

//     always_comb begin 
//         for (int i = 0; i < STORE_RS_NUM_ELEM; i ++) begin 
//             forward_w_valid[i] = valid_arr[i];
//             forward_w_ready[i] = rs1_ready_arr[i] && rs2_ready_arr[i];
//             forward_waddr[i] = rs1_v_arr[i] + imm_arr[i];
//             forward_wmask[i] = '0;
//             forward_wdata[i] = '0;
//             case (funct3_arr[i])
//                 sb_mem: begin 
//                     forward_wmask[i] = 4'b0001 << forward_waddr[i][1:0];
//                     forward_wdata[i][8 * forward_waddr[i][1:0] +: 8] = rs2_v_arr[i][7:0];
//                 end
//                 sh_mem: begin 
//                     forward_wmask[i] = 4'b0011 << forward_waddr[i][1:0];
//                     forward_wdata[i][16 * forward_waddr[i][1] +: 16] = rs2_v_arr[i][15:0];
//                 end 
//                 sw_mem: begin 
//                     forward_wmask[i] = 4'b1111;
//                     forward_wdata[i] = rs2_v_arr[i];
//                 end
//             endcase
//         end 
//     end 

// endmodule