module load_rs
import rv32i_types::*;
#(
    parameter LOAD_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) 
(
    input logic clk,
    input logic rst,
    
    input logic load_rs_issue,
    input logic load_rs_pop,

    output logic load_rs_full,
    output logic load_rs_valid,
    output logic load_rs_ready,
    output logic [63:0] load_rs_order,
    // output logic dmem_resp,

    input logic [63:0] issue_order,
    input logic [ 2:0] issue_funct3,
    input logic [31:0] issue_imm,
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic                   issue_rs1_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic                   issue_rs1_rob_ready,
    input logic [           31:0] issue_rs1_rob_v,

    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    output logic [31:0] 

    // output result to CDB
    output logic load_rs_valid,
    output logic [31:0] load_rs_v,
    output logic [ROB_DEPTH-1:0] load_rs_rob
);

endmodule