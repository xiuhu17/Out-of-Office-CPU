module full_adder
(
    input logic A,
    input logic B,
    input logic Cin,
    output logic Y,
    output logic Cout
);

assign Y = A ^ B ^ Cin;
assign Cout = (A & B) | (Cin & (A ^ B));

endmodule : full_adder