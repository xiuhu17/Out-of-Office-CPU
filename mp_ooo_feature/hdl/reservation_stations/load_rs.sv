// module load_rs
// import rv32i_types::*;
// #(
//     parameter LOAD_RS_DEPTH = 3,
//     parameter STORE_RS_DEPTH = 3,
//     parameter ROB_DEPTH = 3,
//     parameter CDB_SIZE = 3,
//     parameter STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH,
//     parameter LOAD_RS_NUM_ELEM = 2 ** LOAD_RS_DEPTH
// ) 
// (
//     input logic clk,
//     input logic rst,

//     // control signal
//     input logic load_rs_issue,
//     input logic load_rs_pop,

//     // output signal
//     output logic load_rs_full,
//     output logic load_rs_valid,
//     output logic load_rs_ready,

//     // issue input data
//     input logic [ 2:0] issue_funct3,
//     input logic [31:0] issue_imm,
//     input logic [ROB_DEPTH-1:0] issue_target_rob,
//     input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
//     input logic                   issue_rs1_regfile_ready,
//     input logic [           31:0] issue_rs1_regfile_v,
//     input logic                   issue_rs1_rob_ready,
//     input logic [           31:0] issue_rs1_rob_v,
//     // we store the head, tail when we are issuing the load 
//     input logic [STORE_RS_DEPTH-1:0] issue_store_rs_head,
//     input logic [STORE_RS_DEPTH-1:0] issue_store_rs_tail,

//     // snoop from cdb
//     input logic                 cdb_valid[CDB_SIZE],
//     input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
//     input logic [         31:0] cdb_rd_v [CDB_SIZE],

//     // read from store_queue
//     input logic forward_w_valid[STORE_RS_NUM_ELEM],
//     input logic forward_w_ready[STORE_RS_NUM_ELEM],
//     input logic [31:0] forward_waddr[STORE_RS_NUM_ELEM],
//     input logic [3:0] forward_wmask[STORE_RS_NUM_ELEM],
//     input logic [31:0] forward_wdata[STORE_RS_NUM_ELEM]
// );

//     // valid and ready
//     logic valid_arr[LOAD_RS_NUM_ELEM];
//     logic rs1_ready_arr[LOAD_RS_NUM_ELEM];
//     logic [1:0] rs2_status_arr[LOAD_RS_NUM_ELEM];

//     //
//     logic [ 2:0] funct3_arr[LOAD_RS_NUM_ELEM];
//     logic [31:0] imm_arr[LOAD_RS_NUM_ELEM];

//     //
//     logic [31:0] rs1_v_arr[LOAD_RS_NUM_ELEM];
//     logic [ROB_DEPTH-1:0] rs1_rob_arr[LOAD_RS_NUM_ELEM];
//     logic [ROB_DEPTH-1:0] target_rob_arr[LOAD_RS_NUM_ELEM];
//     logic [31:0] rs2_v_arr[LOAD_RS_NUM_ELEM];

//     //
//     logic [LOAD_RS_DEPTH-1:0] head;
//     logic [LOAD_RS_DEPTH-1:0] tail;

//     always_comb begin
//         load_rs_full = '0;
//         if (valid_arr[head]) begin 
//             load_rs_full = '1;
//         end 

//         load_rs_valid = valid_arr[tail];
//         load_rs_ready = rs1_ready_arr[tail];

//         // for comparsion
//     end 

//     always_ff @ (posedge clk) begin 
//         if (rst) begin
//             head <= '0;
//             tail <= '0;
//             for (int i = 0; i < LOAD_RS_NUM_ELEM; i ++) begin 
//                 valid_arr[i] <= '0;
//                 funct3_arr[i] <= '0;
//                 imm_arr[i] <= '0;
//                 rs1_ready_arr[i] <= '0;
//                 rs1_v_arr[i] <= '0;
//                 rs1_rob_arr[i] <= '0;
//                 target_rob_arr[i] <= '0;
//             end 
//         end else begin 
//             if (load_rs_pop) begin 
//                 valid_arr[tail] <= '0;
//                 rs1_ready_arr[tail] <= '0;
//                 tail <= tail + 1'b1;
//             end 

//             for (int i = 0; i < LOAD_RS_NUM_ELEM; i++) begin 
//                 if (valid_arr[i]) begin
//                     for (int j = 0; j < CDB_SIZE; j++) begin 
//                         if (cdb_valid[j] && (rs1_ready_arr[i] == '0) && (rs1_rob_arr[i] == cdb_rob[j])) begin 
//                             rs1_ready_arr[i] <= '1;
//                             rs1_v_arr[i] <= cdb_rd_v[j];
//                         end
//                     end 
//                 end
//             end

//             if (load_rs_issue) begin 
//                 valid_arr[head] <= '1;
//                 funct3_arr[head] <= issue_funct3;
//                 imm_arr[head] <= issue_imm;
//                 rs1_ready_arr[head] <= '0;
//                 rs1_v_arr[head] <= '0;
//                 rs1_rob_arr[head] <= issue_rs1_regfile_rob;
//                 target_rob_arr[head] <= issue_target_rob;

//                 if (issue_rs1_regfile_ready) begin 
//                     rs1_ready_arr[head] <= '1;
//                     rs1_v_arr[head] <= issue_rs1_regfile_v;
//                 end else if (issue_rs1_rob_ready) begin 
//                     rs1_ready_arr[head] <= '1;
//                     rs1_v_arr[head] <= issue_rs1_rob_v;
//                 end else begin 
//                     rs1_ready_arr[head] <= '0;
//                 end

//                 head <= head + 1'b1;
//             end 
//         end 
//     end 

//     always_comb begin 
//         transfer_r_rob = rs1_rob_arr[tail];
//         transfer_raddr = rs1_v_arr[tail] + imm_arr[tail];
//         transfer_rmask = '0;

//         case (funct3_arr[tail])
//             lb_mem, lbu_mem: begin 
//                 transfer_rmask = 4'b0001 << transfer_raddr[1:0];
//             end 
//             lh_mem, lhu_mem: begin 
//                 transfer_rmask = 4'b0011 << transfer_raddr[1:0];
//             end 
//             lw_mem: begin 
//                 transfer_rmask = 4'b1111;
//             end 
//         endcase
//     end 

// endmodule
