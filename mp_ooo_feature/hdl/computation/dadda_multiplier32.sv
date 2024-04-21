module dadda_multiplier32
(
    input logic clk,
    input logic rst,
    input logic start,

    input logic [1:0] mul_type,
    input logic move_flush,

    input logic[31:0] a,
    input logic[31:0] b,
    output logic[63:0] p,
    output logic done
);

 // Constants for multiplication case readability
  `define UNSIGNED_UNSIGNED_MUL 2'b00
  `define SIGNED_SIGNED_MUL 2'b01
  `define SIGNED_UNSIGNED_MUL 2'b10

logic [31:0] a_reg;
logic [31:0] b_reg;

enum bit [2:0] {IDLE, S0, S1, S2, S3, FINISH} stage;
logic multStart;
logic [4:0] multDone;
logic [31:0] p1;
logic [31:0] p2;
logic [31:0] p3;
logic [31:0] p4;

logic [31:0] s1_p1_reg;
logic [31:0] s1_p2_reg;
logic [31:0] s1_p3_reg;
logic [31:0] s1_p4_reg;


/* ------------ Stage 1 ------------ */
dadda_multiplier16 mult1(.*, .move_flush(move_flush), .start(multStart), .a(a_reg[15:0]),.b(b_reg[15:0]), .p(p1), .done(multDone[0]));
dadda_multiplier16 mult2(.*, .move_flush(move_flush), .start(multStart), .a(a_reg[15:0]),.b(b_reg[31:16]), .p(p2), .done(multDone[1]));
dadda_multiplier16 mult3(.*, .move_flush(move_flush), .start(multStart), .a(a_reg[31:16]),.b(b_reg[15:0]), .p(p3), .done(multDone[2]));
dadda_multiplier16 mult4(.*, .move_flush(move_flush), .start(multStart), .a(a_reg[31:16]),.b(b_reg[31:16]), .p(p4), .done(multDone[3]));


/* ------------ Stage 2 ------------ */
logic [31:0] s2_sum1;
logic [47:0] s2_sum2;


/* ------------ Stage 3 ------------ */

logic [63:0] product;
logic neg_result;


/* ------------ Stage 4 ------------ */
always_comb begin
    unique case (mul_type)
        `UNSIGNED_UNSIGNED_MUL: p = product;
        `SIGNED_SIGNED_MUL, `SIGNED_UNSIGNED_MUL:
        p = neg_result ? (~product[62:0]) + 1'b1 : product;
        default: p = 'x;
    endcase
end



assign done = stage == FINISH;

always_ff @ (posedge clk) begin
    if (rst || move_flush) begin
        stage <= IDLE;
        multStart <= '0;
        s1_p1_reg <= '0;
        s1_p2_reg <= '0;
        s1_p3_reg <= '0;
        s1_p4_reg <= '0;
        s2_sum1 <= '0;
        s2_sum2 <= '0;
        product <= '0;
    end else begin
        if (start && stage == IDLE) begin
            stage <= S0;
            multStart <= 1'b1;
            unique case (mul_type)
              `UNSIGNED_UNSIGNED_MUL: begin
                neg_result <= '0;  // Not used in case of unsigned mul, but just cuz . . .
                a_reg <= a;
                b_reg <= b;
              end
              `SIGNED_SIGNED_MUL: begin
                // A -*+ or +*- results in a negative number unless the "positive" number is 0
                neg_result <= (a[31] ^ b[31]) && ((a != '0) && (b != '0));
                // If operands negative, make positive
                a_reg <= (a[31]) ? {(~a + 1'b1)} : a;
                b_reg <= (b[31]) ? {(~b + 1'b1)} : b;
              end
              `SIGNED_UNSIGNED_MUL: begin
                neg_result <= a[31];
                a_reg <= (a[31]) ? {(~a + 1'b1)} : a;
                b_reg <= b;
              end
              default: ;
            endcase
        end 
        else if (stage == S0) begin
            stage <= S1;
            multStart <= 1'b0;
        end
        else if (stage == S1 && multDone[0]) begin
            stage <= S2;
            s1_p1_reg <= p1;
            s1_p2_reg <= p2;
            s1_p3_reg <= p3;
            s1_p4_reg <= p4;
        end
        else if (stage == S2) begin
            stage <= S3;
            s2_sum1 <= s1_p2_reg + {16'b0, s1_p1_reg[31:16]};
            s2_sum2 <= {16'b0, s1_p3_reg} + {s1_p4_reg, 16'b0};
        end
        else if (stage == S3) begin
            stage <= FINISH;
            product[63:16] <= {16'b0, s2_sum1} + s2_sum2;
            product[15:0] <= s1_p1_reg[15:0];
        end
        else if (stage == FINISH && ~start) begin
            stage <= IDLE;
        end
        
    end
end

endmodule : dadda_multiplier32