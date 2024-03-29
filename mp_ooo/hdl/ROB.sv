module ROB #(
    parameter ROB_DEPTH = 4,  
    parameter EXECUTATION_DEPTH = 2
) (
    input logic clk,
    input logic rst,

    // for instruction issue write into rob
    input  logic rob_push[SUPERSCALAR],
    input  logic [4:0] rob_rd_s[SUPERSCALAR],
    output logic rob_valid_out[SUPERSCALAR], 

    // 
    output logic [ROB_DEPTH-1:0] available_slot_count,

    // for cdb write into rob
    input logic [ROB_DEPTH-1:0] cdb_rob[EXECUTATION_DEPTH],
    input logic [31:0] cdb_rd_v[EXECUTATION_DEPTH]

    // for rob to commit out
);


 
endmodule
