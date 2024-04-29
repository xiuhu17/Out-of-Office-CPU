module store_rs
import rv32i_types::*;
#(
    parameter STORE_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 4,
    parameter STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH
) 
(
    input logic clk,
    input logic rst,
    input logic move_flush,

    // input signal
    input logic store_rs_issue,

    // output signal
    output logic store_rs_full,

    // with ready & valid to decide dmem_w_rqst
    input logic [ROB_DEPTH-1:0] rob_tail,

    // to fsm
    output logic dmem_w_rqst,

    // from fsm
    input logic store_rs_pop,

    // issue input data
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
    output logic [STORE_RS_DEPTH:0] issue_store_rs_count,
    // output logic [STORE_RS_DEPTH-1:0] issue_store_rs_head,

    // snoop cdb data
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // forward to load queue
    // output logic forward_wready[STORE_RS_NUM_ELEM],
    // output logic [31:0] forward_waddr[STORE_RS_NUM_ELEM],

    // to cdb
    output logic cdb_store_rs_valid,
    output logic [ROB_DEPTH-1:0] cdb_store_rs_rob,
    output logic [3:0] cdb_arbiter_store_rs_wmask,
    output logic [31:0] cdb_arbiter_store_rs_addr,
    output logic [31:0] cdb_arbiter_store_rs_wdata
);
    
    // valid and ready
    logic valid_arr[STORE_RS_NUM_ELEM];
    logic rs1_ready_arr    [STORE_RS_NUM_ELEM];
    logic rs2_ready_arr    [STORE_RS_NUM_ELEM];

    // issuing value
    logic [ 2:0] funct3_arr[STORE_RS_NUM_ELEM];
    logic [31:0] imm_arr[STORE_RS_NUM_ELEM];

    // operands
    logic [            31:0] rs1_v_arr        [STORE_RS_NUM_ELEM];
    logic [            31:0] rs2_v_arr        [STORE_RS_NUM_ELEM];
    logic [   ROB_DEPTH-1:0] rs1_rob_arr      [STORE_RS_NUM_ELEM];
    logic [   ROB_DEPTH-1:0] rs2_rob_arr      [STORE_RS_NUM_ELEM];
    logic [ROB_DEPTH-1:0]    target_rob_arr [STORE_RS_NUM_ELEM];

    // 
    logic [STORE_RS_DEPTH-1:0] head;
    logic [STORE_RS_DEPTH-1:0] tail;
    // avoid overflow
    logic [STORE_RS_DEPTH:0] count;


    always_comb begin 
        store_rs_full = '0;
        if (valid_arr[head]) begin 
            store_rs_full = '1;
        end 
    end 

    always_ff @(posedge clk) begin 
        if (rst || move_flush) begin 
            head <= '0;
            tail <= '0;
            count <= '0;
            for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin 
                valid_arr[i] <= '0;
                funct3_arr[i] <= '0;
                imm_arr[i] <= '0;
                rs1_ready_arr[i] <= '0;
                rs2_ready_arr[i] <= '0;
                rs1_v_arr[i] <= '0;
                rs2_v_arr[i] <= '0;
                rs1_rob_arr[i] <= '0;
                rs2_rob_arr[i] <= '0;
                target_rob_arr[i] <= '0;
            end
        end else begin 
            if (store_rs_issue) begin 
                valid_arr[head] <= '1;
                funct3_arr[head] <= issue_funct3;
                imm_arr[head] <= issue_imm;
                rs1_ready_arr[head] <= '0;
                rs2_ready_arr[head] <= '0;
                rs1_v_arr[head] <= '0;
                rs2_v_arr[head] <= '0;
                rs1_rob_arr[head] <= issue_rs1_regfile_rob;
                rs2_rob_arr[head] <= issue_rs2_regfile_rob;
                target_rob_arr[head] <= issue_target_rob;

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

            for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin 
                if (valid_arr[i]) begin 
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

            if (store_rs_pop) begin 
                valid_arr[tail] <= '0;
                rs1_ready_arr[tail] <= '0;
                rs2_ready_arr[tail] <= '0;
                tail <= tail + 1'b1;
            end 

            if (store_rs_issue && !store_rs_pop) begin
                count <= count + 1'b1;
            end else if (!store_rs_issue && store_rs_pop) begin
                count <= count - 1'b1;
            end 
        end 
    end 

    // to load_rs when issue and always connected
    always_comb begin
        issue_store_rs_count = count;
        // issue_store_rs_head = head;
        // for (int unsigned i = 0; i < STORE_RS_NUM_ELEM; i ++) begin 
        //     forward_wready[i] = rs1_ready_arr[i];
        //     forward_waddr[i] = rs1_v_arr[i] + imm_arr[i];
        // end
    end

    // to fsm
    always_comb begin
        dmem_w_rqst = '0;
        if (valid_arr[tail] && rs1_ready_arr[tail] && rs2_ready_arr[tail] && (target_rob_arr[tail] == rob_tail)) begin
            dmem_w_rqst = '1; 
        end
    end 

    // to cdb
    always_comb begin
        cdb_store_rs_valid = '0;
        cdb_store_rs_rob = '0;
        if (store_rs_pop) begin
            cdb_store_rs_valid = '1; 
            cdb_store_rs_rob = target_rob_arr[tail];
        end
    end

    // to arbiter and cdb
    always_comb begin
        cdb_arbiter_store_rs_addr = rs1_v_arr[tail] + imm_arr[tail];
        cdb_arbiter_store_rs_wmask = '0;
        cdb_arbiter_store_rs_wdata = '0;
        case (funct3_arr[tail])
            sb_mem: begin
                cdb_arbiter_store_rs_wmask = 4'b0001 << cdb_arbiter_store_rs_addr[1:0];
                cdb_arbiter_store_rs_wdata[8 * cdb_arbiter_store_rs_addr[1:0] +: 8] = rs2_v_arr[tail][7:0];
            end 
            sh_mem: begin
                cdb_arbiter_store_rs_wmask = 4'b0011 << cdb_arbiter_store_rs_addr[1:0];
                cdb_arbiter_store_rs_wdata[16 * cdb_arbiter_store_rs_addr[1] +: 16] = rs2_v_arr[tail][15:0];
            end
            sw_mem: begin
                cdb_arbiter_store_rs_wmask = 4'b1111;
                cdb_arbiter_store_rs_wdata = rs2_v_arr[tail];
            end
        endcase
    end

endmodule
