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
    input logic [31:0] cdb_store_rs_wdata,

    // forward to load_rs
    output logic store_buffer_valid[STORE_BUFFER_NUM_ELEM],
    output logic [31:0] store_buffer_addr[STORE_BUFFER_NUM_ELEM],
    output logic [3:0] store_buffer_wmask[STORE_BUFFER_NUM_ELEM],
    output logic [31:0] store_buffer_wdata[STORE_BUFFER_NUM_ELEM],

    // to arbiter
    output logic [3:0] arbiter_store_buffer_wmask,
    output logic [31:0] arbiter_store_buffer_addr,
    output logic [31:0] arbiter_store_buffer_wdata
);  

    // store the value from store_rs 
    logic valid_arr[STORE_BUFFER_NUM_ELEM];
    logic [31:0] addr_arr[STORE_BUFFER_NUM_ELEM];
    logic [3:0] wmask_arr[STORE_BUFFER_NUM_ELEM];
    logic [31:0] wdata_arr[STORE_BUFFER_NUM_ELEM];

    // head tail
    logic [STORE_BUFFER_DEPTH-1:0] head;
    logic [STORE_BUFFER_DEPTH-1:0] tail;

    always_ff @(posedge clk) begin
        if (rst) begin
            head <= '0;
            tail <= '0;
            for (int unsigned i = 0; i < STORE_BUFFER_NUM_ELEM; i ++) begin 
                valid_arr[i] <= '0;
                addr_arr[i] <= '0;
                wmask_arr[i] <= '0;
                wdata_arr[i] <= '0;
            end
        end else begin
            if (cdb_store_rs_valid) begin
                valid_arr[head] <= '1;
                addr_arr[head] <= cdb_store_rs_addr;
                wmask_arr[head] <= cdb_store_rs_wmask;  
                wdata_arr[head] <= cdb_store_rs_wdata;
                head <= head + 1'b1;
            end

            if (store_buffer_pop) begin
                valid_arr[tail] <= '0;
                wmask_arr[tail] <= '0;
                tail <= tail + 1'b1;
            end
        end
    end

    // whether the store_buffer is full or not
    always_comb begin
        store_buffer_full = valid_arr[head];
    end

    // output to arbiter
    always_comb begin
        dmem_w_rqst = '0;
        arbiter_store_buffer_wmask = '0;
        arbiter_store_buffer_addr = '0;
        arbiter_store_buffer_wdata = '0;
        if (valid_arr[tail]) begin
            dmem_w_rqst = '1;
            arbiter_store_buffer_wmask = wmask_arr[tail];
            arbiter_store_buffer_addr = addr_arr[tail];
            arbiter_store_buffer_wdata = wdata_arr[tail];
        end
    end

    // forward to load_rs
    // [0/head, .... STORE_BUFFER_NUM_ELEM-1/tail] [closet, ... furthest]
    always_comb begin
        for (int unsigned i = 0; i < STORE_BUFFER_NUM_ELEM; i ++) begin
            store_buffer_valid[i] = valid_arr[(STORE_BUFFER_DEPTH)'(head - i)];
            store_buffer_addr[i] = addr_arr[(STORE_BUFFER_DEPTH)'(head - i)];
            store_buffer_wmask[i] = wmask_arr[(STORE_BUFFER_DEPTH)'(head - i)];
            store_buffer_wdata[i] = wdata_arr[(STORE_BUFFER_DEPTH)'(head - i)];
        end
    end
endmodule