module dadda_multiplier16
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic move_flush,

    input logic[15:0] a,
    input logic[15:0] b,
    output logic[31:0] p,
    output logic done
);

enum bit [1:0] {IDLE, S1, S2, FINISH} stage;
logic multStart;
logic [4:0] multDone;
logic [15:0] p1;
logic [15:0] p2;
logic [15:0] p3;
logic [15:0] p4;

logic [15:0] s1_p1_reg;
logic [15:0] s1_p2_reg;
logic [15:0] s1_p3_reg;
logic [15:0] s1_p4_reg;

/*
    Combining dadda 8-bit with vedic multiplication to create 16 bit multiplier because it is so much easier
*/

/* ------------ Stage 1 ------------ */
assign multStart = start;
dadda_multiplier8 mult1(.*, .move_flush(move_flush), .start(multStart), .a(a[7:0]),.b(b[7:0]), .p(p1), .done(multDone[0]));
dadda_multiplier8 mult2(.*, .move_flush(move_flush), .start(multStart), .a(a[7:0]),.b(b[15:8]), .p(p2), .done(multDone[1]));
dadda_multiplier8 mult3(.*, .move_flush(move_flush), .start(multStart), .a(a[15:8]),.b(b[7:0]), .p(p3), .done(multDone[2]));
dadda_multiplier8 mult4(.*, .move_flush(move_flush), .start(multStart), .a(a[15:8]),.b(b[15:8]), .p(p4), .done(multDone[3]));


/* ------------ Stage 2 ------------ */
logic [15:0] s2_sum1;
logic [23:0] s2_sum2;

/* ------------ Stage 3 ------------ */


assign p[31:8] = {8'b0, s2_sum1} + s2_sum2;
assign p[7:0] = s1_p1_reg[7:0];
assign done = stage == FINISH;

always_ff @ (posedge clk) begin
    if (rst || move_flush) begin
        stage <= IDLE;
        s1_p1_reg <= '0;
        s1_p2_reg <= '0;
        s1_p3_reg <= '0;
        s1_p4_reg <= '0;
        s2_sum1 <= '0;
        s2_sum2 <= '0;
    end else begin
        if (start && stage == IDLE) begin
            stage <= S1;
        end 
        else if (stage == S1 && multDone[0]) begin
            stage <= S2;
            s1_p1_reg <= p1;
            s1_p2_reg <= p2;
            s1_p3_reg <= p3;
            s1_p4_reg <= p4;
        end
        else if (stage == S2) begin
            stage <= FINISH;
            s2_sum1 <= s1_p2_reg + {8'b0, s1_p1_reg[15:8]};
            s2_sum2 <= {8'b0, s1_p3_reg} + {s1_p4_reg, 8'b0};
        end
        else if (stage == FINISH && ~start) begin
            stage <= IDLE;
        end
        
    end
end

endmodule : dadda_multiplier16