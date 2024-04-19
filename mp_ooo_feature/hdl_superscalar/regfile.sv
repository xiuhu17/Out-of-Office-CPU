module RegFile_Scoreboard
#(
    parameter SUPERSCALAR = 1,
    parameter ROB_DEPTH = 4
) (
    input   logic           clk,
    input   logic           rst,

    // rob_to_regfile_t
    input   logic                       commit_regf_we[SUPERSCALAR], // each time we may not write SUPERSCALAR robs to regfile, e.g only one could commit, but superscalar = 2
    input   logic   [4:0]               commit_rd_s[SUPERSCALAR],
    input   logic   [31:0]              commit_rd_v[SUPERSCALAR],  
    input   logic   [ROB_DEPTH - 1:0]   commit_rob[SUPERSCALAR],

    // iq_to_regfile_t
    // overwrite the scoreboard when instruction is issued  
    input   logic                       issue_valid[SUPERSCALAR],
    input   logic   [4:0]               issue_rd_s[SUPERSCALAR],
    input   logic   [ROB_DEPTH - 1:0]   issue_rob[SUPERSCALAR],

    // read from registerfile when instruction is issued
    // regfile_to_iq_t
    input   logic   [4:0]               issue_rs_1[SUPERSCALAR],
    input   logic   [4:0]               issue_rs_2[SUPERSCALAR],
    output  logic   [31:0]              issue_rs1_v[SUPERSCALAR],
    output  logic   [31:0]              issue_rs2_v[SUPERSCALAR],
    output  logic                       issue_rs1_ready[SUPERSCALAR],
    output  logic                       issue_rs2_ready[SUPERSCALAR],
    output  logic   [ROB_DEPTH - 1:0]   issue_rs1_rob[SUPERSCALAR],
    output  logic   [ROB_DEPTH - 1:0]   issue_rs2_rob[SUPERSCALAR]
);

    // 0 is oldest
    // n is youngest
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
                if (commit_regf_we[i] && (commit_rd_s[i] != 5'd0)) begin
                    // value update
                    register_arr[commit_rd_s[i]] <= commit_rd_v[i];

                    // scoreboard update
                    //  update only when scoreboard exists and the commit is the rob which matches the scoreboard; stop looking up the rob
                    //  otherwise, scoreboard still exists
                    if (scoreboard_valid_arr[commit_rd_s[i]] && (scoreboard_arr[commit_rd_s[i]] == commit_rob[i])) begin 
                        scoreboard_valid_arr[commit_rd_s[i]] <= '0;
                    end 
                end
            end

            // after update the scoreboard, we need to update since the newly issued instruction
            for (int i = 0; i < SUPERSCALAR; i++) begin
                if (issue_valid[i] && (issue_rd_s[i] != 5'd0)) begin
                    scoreboard_arr[issue_rd_s[i]] <= issue_rob[i];
                    scoreboard_valid_arr[issue_rd_s[i]] <= '1;
                end
            end
        end
    end 

    // read from register file
    // if we want to solve the dependencies, we also have to know whether the 
    always_comb begin 
        


    end 

endmodule


