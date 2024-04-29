module ROB #(
    parameter ROB_DEPTH = 4,  // number of bits to use for depth
    parameter SUPERSCALAR = 1,
    parameter EXECUTATION_COUNT = 4
) (
    input logic clk,
    input logic rst,

    // status signal
    output logic rob_full,
    output logic rob_valid_out[SUPERSCALAR],
    output logic rob_ready_out[SUPERSCALAR],

    // for cdb write into rob
    input logic cdb_valid_out[EXECUTATION_COUNT],
    input logic [ROB_DEPTH-1:0] cdb_rob[EXECUTATION_COUNT],
    input logic [31:0] cdb_rd_v[EXECUTATION_COUNT]

    // for instruction issue write into rob
    input  logic rob_push[SUPERSCALAR],
    input  logic [4:0] rob_rd_s[SUPERSCALAR],

    // for rob to commit out
    input logic rob_pop[SUPERSCALAR],

    // for reading from rob
    // when the instr is issued
);

    
    localparam MAX_NUM_ELEMS = 2 ** ROB_DEPTH;  
    logic [ROB_DEPTH-1:0] head;
    logic [ROB_DEPTH-1:0] tail;
    logic [31:0] rob_arr[MAX_NUM_ELEMS][SUPERSCALAR];
    logic valid_arr[MAX_NUM_ELEMS][SUPERSCALAR]; // valid means occupy
    logic ready_arr[MAX_NUM_ELEMS][SUPERSCALAR]; // ready means calculated/ready to commit

    always_comb begin
        // check if current line is empty (no instruction in the line)
        rob_full = '0;
        for (int i = 0; i < SUPERSCALAR; ++i) begin
            if (valid_arr[head][i]) begin
                rob_full = '1;
            end
        end
        rob_valid_out = valid_arr[tail];
    end 

    always_ff @(posedge clk) begin 
        if (rst) begin 
            head <= '0;
            tail <= '0;
            for (int i = 0; i < MAX_NUM_ELEMS; i++) begin
                for (int j = 0; j < SUPERSCALAR; j++) begin
                    valid_arr[i][j] <= '0;
                    ready_arr[i][j] <= '0;
                end
            end
        end else begin 
            if (rob_push) begin 


            end 


        end 
    end 


 

 
endmodule
