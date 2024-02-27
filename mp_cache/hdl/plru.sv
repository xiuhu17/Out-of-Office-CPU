module PLRU(
    input logic clk,
    input logic rst,
    input logic ufp_resp,
    input logic [3:0] curr_set,
    output logic [1:0] curr_way_replace
);

    logic [2:0] curr_plru;
    logic [2:0] next_plru;
    logic [2:0] Plru_Arr[16];

    always_comb begin 
        curr_plru = Plru_Arr[curr_set];
        curr_way_replace = {curr_plru[0], curr_plru[curr_plru[0] + '1]};
        next_plru[0] = ~curr_plru[0];
        next_plru[curr_plru[0] + '1] = ~curr_plru[curr_plru[0] + '1];
    end 

    always_ff @ (posedge clk) begin
        if (rst) begin
            for (int i = 0; i < 16; i++) begin
                Plru_Arr[i] <= 3'b0;
            end
        end else if (ufp_resp) begin
           Plru_Arr[curr_set] <= next_plru;
        end
    end

endmodule