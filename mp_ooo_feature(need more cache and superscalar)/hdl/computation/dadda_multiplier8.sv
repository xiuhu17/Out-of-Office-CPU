module dadda_multiplier8
(
    input logic clk,
    input logic rst,
    input logic start,
    input logic move_flush,

    input logic[7:0] a,
    input logic[7:0] b,
    output logic[15:0] p,
    output logic done
);

logic [2:0] stage;
logic idle;

logic [7:0][7:0] partial;
generate for (genvar i = 0; i < 8; i++) begin
    for (genvar j = 0; j < 8; j++) begin
        assign partial[i][j] = a[i] & b[j];
    end
end endgenerate

logic [5:0] s1_sum;
logic [5:0] s1_carry;
logic [13:0] s2_sum;
logic [13:0] s2_carry;
logic [9:0] s3_sum;
logic [9:0] s3_carry;
logic [11:0] s4_sum;
logic [11:0] s4_carry;
logic [13:0] s5_sum1;
logic [13:0] s5_sum2;

logic [5:0] s1_sum_reg;
logic [5:0] s1_carry_reg;
logic [13:0] s2_sum_reg;
logic [13:0] s2_carry_reg;
logic [9:0] s3_sum_reg;
logic [9:0] s3_carry_reg;
logic [4:0] s3_s2_reg; // s4 needs 4 bits from s2_sum
logic [11:0] s4_sum_reg;
logic [11:0] s4_carry_reg;

/* ------------ Stage 1 ------------ */
half_adder s1h1(.A(partial[6][0]), .B(partial[5][1]), .Y(s1_sum[0]), .Cout(s1_carry[0]));

full_adder s1f1(.A(partial[7][0]), .B(partial[6][1]), .Cin(partial[5][2]), .Y(s1_sum[1]), .Cout(s1_carry[1]));
half_adder s1h2(.A(partial[4][3]), .B(partial[3][4]), .Y(s1_sum[2]), .Cout(s1_carry[2]));

full_adder s1f2(.A(partial[7][1]), .B(partial[6][2]), .Cin(partial[5][3]), .Y(s1_sum[3]), .Cout(s1_carry[3]));
half_adder s1h3(.A(partial[4][4]), .B(partial[3][5]), .Y(s1_sum[4]), .Cout(s1_carry[4]));

full_adder s1f3(.A(partial[7][2]), .B(partial[6][3]), .Cin(partial[5][4]), .Y(s1_sum[5]), .Cout(s1_carry[5]));
//assign s1_sum_reg = s1_sum;
//assign s1_carry_reg = s1_carry;

/* ------------ Stage 2 ------------ */
half_adder s2h1(.A(partial[4][0]), .B(partial[3][1]), .Y(s2_sum[0]), .Cout(s2_carry[0]));

full_adder s2f1(.A(partial[5][0]), .B(partial[4][1]), .Cin(partial[3][2]), .Y(s2_sum[1]), .Cout(s2_carry[1]));
half_adder s2h2(.A(partial[2][3]), .B(partial[1][4]), .Y(s2_sum[2]), .Cout(s2_carry[2]));

full_adder s2f2(.A(s1_sum_reg[0]), .B(partial[4][2]), .Cin(partial[3][3]), .Y(s2_sum[3]), .Cout(s2_carry[3]));
full_adder s2f3(.A(partial[2][4]), .B(partial[1][5]), .Cin(partial[0][6]), .Y(s2_sum[4]), .Cout(s2_carry[4]));

full_adder s2f4(.A(s1_carry_reg[0]), .B(s1_sum_reg[1]), .Cin(s1_sum_reg[2]), .Y(s2_sum[5]), .Cout(s2_carry[5]));
full_adder s2f5(.A(partial[2][5]), .B(partial[1][6]), .Cin(partial[0][7]), .Y(s2_sum[6]), .Cout(s2_carry[6]));

full_adder s2f6(.A(s1_carry_reg[2]), .B(s1_carry_reg[1]), .Cin(s1_sum_reg[3]), .Y(s2_sum[7]), .Cout(s2_carry[7]));
full_adder s2f7(.A(s1_sum_reg[4]), .B(partial[2][6]), .Cin(partial[1][7]), .Y(s2_sum[8]), .Cout(s2_carry[8]));

full_adder s2f8(.A(s1_carry_reg[4]), .B(s1_carry_reg[3]), .Cin(s1_sum_reg[5]), .Y(s2_sum[9]), .Cout(s2_carry[9]));
full_adder s2f9(.A(partial[4][5]), .B(partial[3][6]), .Cin(partial[2][7]), .Y(s2_sum[10]), .Cout(s2_carry[10]));

full_adder s2f10(.A(s1_carry_reg[5]), .B(partial[7][3]), .Cin(partial[6][4]), .Y(s2_sum[11]), .Cout(s2_carry[11]));
full_adder s2f11(.A(partial[5][5]), .B(partial[4][6]), .Cin(partial[3][7]), .Y(s2_sum[12]), .Cout(s2_carry[12]));

full_adder s2f12(.A(partial[7][4]), .B(partial[6][5]), .Cin(partial[5][6]), .Y(s2_sum[13]), .Cout(s2_carry[13]));

/* ------------ Stage 3 ------------ */
half_adder s3h1(.A(partial[3][0]), .B(partial[2][1]), .Y(s3_sum[0]), .Cout(s3_carry[0]));
full_adder s3f1(.A(s2_sum_reg[0]), .B(partial[2][2]), .Cin(partial[1][3]), .Y(s3_sum[1]), .Cout(s3_carry[1]));
full_adder s3f2(.A(s2_carry_reg[0]), .B(s2_sum_reg[1]), .Cin(s2_sum_reg[2]), .Y(s3_sum[2]), .Cout(s3_carry[2]));
full_adder s3f3(.A(s2_carry_reg[2]), .B(s2_carry_reg[1]), .Cin(s2_sum_reg[3]), .Y(s3_sum[3]), .Cout(s3_carry[3]));
full_adder s3f4(.A(s2_carry_reg[4]), .B(s2_carry_reg[3]), .Cin(s2_sum_reg[5]), .Y(s3_sum[4]), .Cout(s3_carry[4]));
full_adder s3f5(.A(s2_carry_reg[6]), .B(s2_carry_reg[5]), .Cin(s2_sum_reg[7]), .Y(s3_sum[5]), .Cout(s3_carry[5]));
full_adder s3f6(.A(s2_carry_reg[8]), .B(s2_carry_reg[7]), .Cin(s2_sum_reg[9]), .Y(s3_sum[6]), .Cout(s3_carry[6]));
full_adder s3f7(.A(s2_carry_reg[10]), .B(s2_carry_reg[9]), .Cin(s2_sum_reg[11]), .Y(s3_sum[7]), .Cout(s3_carry[7]));
full_adder s3f8(.A(s2_carry_reg[12]), .B(s2_carry_reg[11]), .Cin(s2_sum_reg[13]), .Y(s3_sum[8]), .Cout(s3_carry[8]));
full_adder s3f9(.A(s2_carry_reg[13]), .B(partial[7][5]), .Cin(partial[6][6]), .Y(s3_sum[9]), .Cout(s3_carry[9]));
//assign s3_sum_reg = s3_sum;
//assign s3_carry_reg = s3_carry;

/* ------------ Stage 4 ------------ */
half_adder s4h1(.A(partial[2][0]), .B(partial[1][1]), .Y(s4_sum[0]), .Cout(s4_carry[0]));

full_adder s4f1(.A(s3_sum_reg[0]), .B(partial[1][2]), .Cin(partial[0][3]), .Y(s4_sum[1]), .Cout(s4_carry[1]));
full_adder s4f2(.A(s3_carry_reg[0]), .B(s3_sum_reg[1]), .Cin(partial[0][4]), .Y(s4_sum[2]), .Cout(s4_carry[2]));
full_adder s4f3(.A(s3_carry_reg[1]), .B(s3_sum_reg[2]), .Cin(partial[0][5]), .Y(s4_sum[3]), .Cout(s4_carry[3]));
full_adder s4f4(.A(s3_carry_reg[2]), .B(s3_sum_reg[3]), .Cin(s3_s2_reg[4]), .Y(s4_sum[4]), .Cout(s4_carry[4]));
full_adder s4f5(.A(s3_carry_reg[3]), .B(s3_sum_reg[4]), .Cin(s3_s2_reg[3]), .Y(s4_sum[5]), .Cout(s4_carry[5]));
full_adder s4f6(.A(s3_carry_reg[4]), .B(s3_sum_reg[5]), .Cin(s3_s2_reg[2]), .Y(s4_sum[6]), .Cout(s4_carry[6]));
full_adder s4f7(.A(s3_carry_reg[5]), .B(s3_sum_reg[6]), .Cin(s3_s2_reg[1]), .Y(s4_sum[7]), .Cout(s4_carry[7]));
full_adder s4f8(.A(s3_carry_reg[6]), .B(s3_sum_reg[7]), .Cin(s3_s2_reg[0]), .Y(s4_sum[8]), .Cout(s4_carry[8]));
full_adder s4f9(.A(s3_carry_reg[7]), .B(s3_sum_reg[8]), .Cin(partial[4][7]), .Y(s4_sum[9]), .Cout(s4_carry[9]));
full_adder s4f10(.A(s3_carry_reg[8]), .B(s3_sum_reg[9]), .Cin(partial[5][7]), .Y(s4_sum[10]), .Cout(s4_carry[10]));
full_adder s4f11(.A(s3_carry_reg[9]), .B(partial[7][6]), .Cin(partial[6][7]), .Y(s4_sum[11]), .Cout(s4_carry[11]));


/* ------------ Stage 5 ------------ */
assign p[0] = partial[0][0];
assign s5_sum1 = { s4_carry_reg[11:0], s4_sum_reg[0], partial[1][0]};
assign s5_sum2 = { partial[7][7], s4_sum_reg[11:1], partial[0][2], partial[0][1]};
assign p[15:1] = s5_sum1 + s5_sum2;


assign done = stage == 3'd5; // Takes 5 cycles to finish mult
assign idle = stage == 3'd0;// 0 == idle


always_ff @ (posedge clk) begin
    if (rst || move_flush) begin
        s1_sum_reg <= '0;
        s2_sum_reg <= '0;
        s3_sum_reg <= '0;
        s4_sum_reg <= '0;
        s1_carry_reg <= '0;
        s2_carry_reg <= '0;
        s3_carry_reg <= '0;
        s4_carry_reg <= '0;
        s3_s2_reg <= '0;
        stage <= '0;
    end else begin
        if ((~done && ~idle) || (idle && start)) begin
            stage <= stage + 1'b1;
        end
        else if (done && ~start) begin
            stage <= '0;
        end

        s1_sum_reg <= s1_sum;
        s1_carry_reg <= s1_carry;
        s2_sum_reg <= s2_sum;
        s2_carry_reg <= s2_carry;
        s3_sum_reg <= s3_sum;
        s3_carry_reg <= s3_carry;
        s3_s2_reg <= {s2_sum[4], s2_sum[6], s2_sum[8], s2_sum[10], s2_sum[12]};
        s4_sum_reg <= s4_sum;
        s4_carry_reg <= s4_carry;

    end 
end

endmodule : dadda_multiplier8