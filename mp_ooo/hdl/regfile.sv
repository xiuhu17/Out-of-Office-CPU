module RegFile_Scoreboard
#(
    parameter SUPERSCALAR = 1,
    parameter ROB_DEPTH = 4
) (
    input   logic           clk,
    input   logic           rst,

    // commit part
    input   logic                       regf_we[SUPERSCALAR], // each time we may not write SUPERSCALAR robs to regfile, e.g only one could commit, but superscalar = 2
    input   logic   [4:0]               rd_s[SUPERSCALAR],
    input   logic   [31:0]              rd_v[SUPERSCALAR],  
    input   logic   [ROB_DEPTH - 1:0]   rd_rob[SUPERSCALAR],

    // overwrite the scoreboard when instruction is issued  
    input   logic                       instr_valid_out[SUPERSCALAR],
    input   logic   [4:0]               instr_rd_s[SUPERSCALAR],
    input   logic   [ROB_DEPTH - 1:0]   instr_rd_rob[SUPERSCALAR],

    // read from registerfile when instruction is issued
    input   logic   [4:0]   instr_rs_1[SUPERSCALAR],
    input   logic   [4:0]   instr_rs_2[SUPERSCALAR],

    output  logic   [31:0]  instr_rs1_v[SUPERSCALAR],
    output  logic   [31:0]  instr_rs2_v[SUPERSCALAR],
    output  logic   [ROB_DEPTH - 1:0] instr_rs1_rob[SUPERSCALAR],
    output  logic   [ROB_DEPTH - 1:0] instr_rs2_rob[SUPERSCALAR]
);


    logic [31:0]register_arr[32];
    logic [ROB_DEPTH - 1:0]scoreboard_arr[32];
    logic scoreboard_valid_arr[32];

    always_ff @ (posedge clk) begin 
        if (rst) begin
            for (int i = 0; i < 32; i++) begin
                register_arr[i] <= '0;
                scoreboard_arr[i] <= '0;
                scoreboard_valid_arr[i] <= '0;
            end
        end else begin
            for (int i = 0; i < SUPERSCALAR; i++) begin
                if (regf_we[i] && (rd_s[i] != 5'd0)) begin
                    // value update
                    register_arr[rd_s[i]] <= rd_v[i];

                    // scoreboard update
                    if (scoreboard_valid_arr[rd_s[i]] && (rd_rob[i] == scoreboard_arr[rd_s[i]])) begin 
                        scoreboard_valid_arr[rd_s[i]] <= '0;
                    end 
                end
            end

            for (int i = 0; i < SUPERSCALAR; i++) begin
                if (regf_we[i] && (rd_s[i] != 5'd0)) begin

                end
            end
        end
    end 

endmodule


module ROB_DEPTH
endmodule

