module store_rs
import rv32i_types::*;
#(
    parameter STORE_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) 
(
    input logic clk,
    input logic rst,
    
    input logic store_rs_issue,
    input logic store_rs_pop,

    output logic store_rs_full,
    output logic store_rs_valid,
    output logic store_rs_ready,

    input logic [63:0] issue_order,
    input logic [ 2:0] issue_funct3,
    input logic [31:0] issue_imm,
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,

    input logic                   issue_rs1_regfile_ready,
    input logic                   issue_rs2_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic [           31:0] issue_rs2_regfile_v,

    input logic                   issue_rs1_rob_ready,
    input logic                   issue_rs2_rob_ready,
    input logic [           31:0] issue_rs1_rob_v,
    input logic [           31:0] issue_rs2_rob_v,

    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    output logic [ROB_DEPTH-1:0] transfer_rob,
    output logic [31:0] transfer_waddr,
    output logic [3:0] transfer_wmask,
    output logic [31:0] transfer_wdata
);

    localparam STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH;

    // valid and ready
    logic store_rs_valid[STORE_RS_NUM_ELEM];
    logic rs1_ready_arr    [STORE_RS_NUM_ELEM];
    logic rs2_ready_arr    [STORE_RS_NUM_ELEM];

    // issuing value
    logic [ROB_DEPTH-1:0]    target_rob_arr [STORE_RS_NUM_ELEM];
    logic [63:0] order_arr[STORE_RS_NUM_ELEM];
    logic [ 2:0] funct3_arr[STORE_RS_NUM_ELEM];
    logic [31:0] imm_arr[STORE_RS_NUM_ELEM];

    // operands
    logic [            31:0] rs1_v_arr        [STORE_RS_NUM_ELEM];
    logic [            31:0] rs2_v_arr        [STORE_RS_NUM_ELEM];
    logic [   ROB_DEPTH-1:0] rs1_rob_arr      [STORE_RS_NUM_ELEM];
    logic [   ROB_DEPTH-1:0] rs2_rob_arr      [STORE_RS_NUM_ELEM];

    logic [STORE_RS_DEPTH-1:0] head;
    logic [STORE_RS_DEPTH-1:0] tail;


    always_comb begin 
        store_rs_full = '0;
        if (store_rs_valid[head]) begin 
            store_rs_full = '1;
        end 

        store_rs_valid = store_rs_valid[tail];
        store_rs_ready = rs1_ready_arr[tail] && rs2_ready_arr[tail];
    end 

    always_ff @(posedge clk) begin 
        if (rst) begin 
            head <= '0;
            tail <= '0;
            for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin 
                store_rs_valid[i] <= '0;
                rs1_ready_arr[i] <= '0;
                rs2_ready_arr[i] <= '0;
                target_rob_arr[i] <= '0;
                order_arr[i] <= '0;
                funct3_arr[i] <= '0;
                imm_arr[i] <= '0;
                rs1_v_arr[i] <= '0;
                rs2_v_arr[i] <= '0;
                rs1_rob_arr[i] <= '0;
                rs2_rob_arr[i] <= '0;
            end
        end else begin 
            if (store_rs_pop) begin 
                store_rs_valid[tail] <= '0;
                rs1_ready_arr[tail] <= '0;
                rs2_ready_arr[tail] <= '0;
                tail <= tail + 1'b1;
            end 

            for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin 
                if (store_rs_valid[i]) begin 
                    for (int j = 0; j < CDB_SIZE; j++) begin 
                        if (cdb_valid[j] && (rs1_ready_arr[i] == '0) && (rs1_rob_arr[i] == cdb_rob[j])) begin
                            rs1_ready_arr[i] <= '1;
                            rs1_v_arr[i] <= cdb_rd_v[j];
                        end 
                        if (cdb_valid[j] && (rs2_ready_arr[i] == '0) && (rs2_rob_arr[i] == cdb_rob[j])) begin
                            rs2_ready_arr[i] <= '1;
                            rs2_v_arr[i] <= cdb_rd_v[j];
                        end
                    end 
                end 
            end

            if (store_rs_issue) begin 
                store_rs_valid[head] <= '1;
                target_rob_arr[head] <= issue_target_rob;
                order_arr[head] <= issue_order;
                funct3_arr[head] <= issue_funct3;
                imm_arr[head] <= issue_imm;
                rs1_rob_arr[head] <= issue_rs1_regfile_rob;
                rs2_rob_arr[head] <= issue_rs2_regfile_rob;

                if (issue_rs1_regfile_ready) begin 
                    rs1_ready_arr[head] <= '1;
                    rs1_v_arr[head] <= issue_rs1_regfile_v;
                end else if (issue_rs1_rob_ready) begin 
                    rs1_ready_arr[head] <= '1;
                    rs1_v_arr[head] <= issue_rs1_rob_v;
                end else begin 
                    rs1_ready_arr[head] <= '0;
                end 

                if (issue_rs2_regfile_ready) begin 
                    rs2_ready_arr[head] <= '1;
                    rs2_v_arr[head] <= issue_rs2_regfile_v;
                end else if (issue_rs2_rob_ready) begin 
                    rs2_ready_arr[head] <= '1;
                    rs2_v_arr[head] <= issue_rs2_rob_v;
                end else begin 
                    rs2_ready_arr[head] <= '0;
                end

                head <= head + 1'b1;
            end 
        end 
    end 

    always_comb begin 
        transfer_rob = target_rob_arr[tail];
        transfer_waddr = rs1_v_arr[tail] + imm_arr[tail];
        case (funct3_arr[tail])
            sb_mem: begin 
                transfer_wmask = 4'b0001 << transfer_waddr[1:0];
                transfer_wdata[8 * transfer_waddr[1:0] +: 8] = rs2_v_arr[tail][7:0];
            end
            sh_mem: begin 
                transfer_wmask = 4'b0011 << transfer_waddr[1:0];
                transfer_wdata[16 * transfer_waddr[1] +: 16] = rs2_v_arr[tail][15:0];
            end 
            sw_mem: begin 
                transfer_wmask = 4'b1111;
                transfer_wdata = rs2_v_arr[tail];
            end 
        endcase
    end 

endmodule