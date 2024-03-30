module alu_rs 
#
(
  parameter ALU_RS_DEPTH = 3,
  parameter ROB_DEPTH = 3,
  parameter ALU_SIZE = 2
) 
(
    input logic clk,
    input logic rst,
    output logic alu_rs_full,

    input logic [31:0] rs1_v[ALU_RS_NUM_ELEMS],
    input logic [31:0] rs2_v[ALU_RS_NUM_ELEMS],


    // also need to input the immediate value
    // input  logic  

    // read from rob(contains trasnparent read from cdb in the same cycle) & regfile 

    // read from cdb for waking up; pop from alu_rs if match
    input logic cdb_valid[ALU_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob[ALU_SIZE],
    input logic [31:0] cdb_rd_v[ALU_SIZE],

    // know whether the executation unit is available
    
);

  localparam ALU_RS_NUM_ELEMS = 2 ** ALU_RS_DEPTH;
  localparam ROB_NUM_ELEMS = 2 ** ROB_DEPTH;
  // operation type
  logic valid[ALU_RS_NUM_ELEMS];
  logic [2:0] funct3[ALU_RS_NUM_ELEMS];
  logic [6:0] funct7[ALU_RS_NUM_ELEMS];
  logic [6:0] opcode[ALU_RS_NUM_ELEMS];
  // input values
  logic [31:0] rs1_v[ALU_RS_NUM_ELEMS];
  logic [31:0] rs2_v[ALU_RS_NUM_ELEMS];
  logic [ROB_NUM_ELEMS - 1:0] rs1_rob[ALU_RS_NUM_ELEMS];
  logic [ROB_NUM_ELEMS - 1:0] rs2_rob[ALU_RS_NUM_ELEMS];
  logic rs1_ready[ALU_RS_NUM_ELEMS];
  logic rs2_ready[ALU_RS_NUM_ELEMS];
  // output values
  logic [4:0] rd_s[ALU_RS_NUM_ELEMS];
  logic [4:0] rob[ALU_RS_NUM_ELEMS];

  logic alu_rs_full;

  // control pop by itself
  // push is controlled by outside

endmodule
