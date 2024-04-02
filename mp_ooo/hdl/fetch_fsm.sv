module fetch_fsm(
    input logic instr_full,
    output logic move_fetch
);
    always_comb begin
        move_fetch = ~instr_full;
    end
endmodule