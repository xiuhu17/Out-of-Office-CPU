module half_adder 
(
    input logic A,
    input logic B,
    output logic Y,
    output logic Cout

);

assign Y = A ^ B;
assign Cout = A & B;

endmodule : half_adder