module store_buffer
import rv32i_types::*;
#(
    parameter STORE_BUFFER_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 4,
    parameter STORE_BUFFER_NUM_ELEM = 2 ** STORE_BUFFER_DEPTH
) 
(
    input logic clk,
    input logic rst,
    input logic move_flush,

    // output signal
    output logic store_buffer_full,

    // to fsm
    output logic dmem_w_rqst,

    // from fsm
    input logic store_buffer_pop,

    // from store_rs
    input logic cdb_store_rs_valid,
    input logic [3:0] cdb_store_rs_wmask,
    input logic [31:0] cdb_store_rs_addr,
    input logic [31:0] cdb_store_rs_wdata

    // forward to load_rs
    output logic store_buffer_valid[STORE_BUFFER_NUM_ELEM],
    output logic [31:0] store_buffer_waddr[STORE_BUFFER_NUM_ELEM],
    output logic [3:0] store_buffer_wmask[STORE_BUFFER_NUM_ELEM],
    output logic [31:0] store_buffer_wdata[STORE_BUFFER_NUM_ELEM],

    // to arbiter
    output logic [31:0] arbiter_store_buffer_wdata,
    output logic [3:0] arbiter_store_buffer_wmask,
    output logic [31:0] arbiter_store_buffer_addr
);  

    // store the value from store_rs 
    logic valid_arr[STORE_BUFFER_NUM_ELEM];
    logic [31:0] waddr_arr[STORE_BUFFER_NUM_ELEM];
    logic [3:0] wmask_arr[STORE_BUFFER_NUM_ELEM];
    logic [31:0] wdata_arr[STORE_BUFFER_NUM_ELEM];

    // head tail
    logic [STORE_BUFFER_DEPTH-1:0] head;
    logic [STORE_BUFFER_DEPTH-1:0] tail;

    always_ff @(posedge clk) begin
        if (rst || move_flush) begin

        end else begin
            


        end
    end


endmodule