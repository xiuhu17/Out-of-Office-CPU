// module branch_rs #(
//     parameter ALU_RS_DEPTH = 3,
//     parameter ROB_DEPTH = 3
// ) (
//     input  logic clk,
//     input  logic rst,
//     output logic alu_rs_full,

//     input logic [31:0] rs1_v[ALU_RS_NUM_ELEMS],
//     input logic [31:0] rs2_v[ALU_RS_NUM_ELEMS],

//     // read from cdb for waking up; pop from alu_rs if match
//     input logic cdb_valid,
//     input logic [ROB_DEPTH-1:0] cdb_rob,
//     input logic [31:0] cdb_rd_v
// );

//   localparam ALU_RS_MAX_NUM_ELEM = 2 ** ALU_RS_DEPTH;
//   // internal registers



//   always_ff @(posedge clk) begin

//   end

// endmodule
