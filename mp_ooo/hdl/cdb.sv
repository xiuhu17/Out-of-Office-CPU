module CDB
#
(
  parameter ALU_SIZE = 2,
  parameter ROB_DEPTH = 4   
)
(
    input logic clk,
    input logic rst,

    // alu control signal
    input logic                 w_en[ALU_SIZE],
    input logic                 start[ALU_SIZE],
    input logic                 done[ALU_SIZE],

    // read rob from reservation station; read calculated value from alu
    input logic [31:0]                  exe_alu[ALU_SIZE],
    input logic [ROB_DEPTH-1:0]         exe_rob[ALU_SIZE],

    output logic                         cdb_valid[ALU_SIZE],
    output logic [ROB_DEPTH-1:0]         cdb_rob[ALU_SIZE],
    output logic [31:0]                  cdb_rd_v[ALU_SIZE]
);

    logic 

endmodule