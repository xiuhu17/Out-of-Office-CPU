module PLRU(
    input logic [2:0] curr_plru,
    output logic [1:0] curr_idx,
    output logic [2:0] next_plru
);

    assign curr_idx = {curr_plru[0], curr_plru[curr_plru[0] + '1]};
    assign next_plru[0] = ~curr_plru[0];
    assign next_plru[curr_plru[0] + '1] = ~curr_plru[curr_plru[0] + '1];
endmodule