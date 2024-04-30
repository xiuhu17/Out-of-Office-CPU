module alu
(
    input   logic   [2:0]   aluop,
    input   logic   [31:0]  a, b,
    output  logic   [31:0]  f
);

    logic signed   [31:0] as;
    logic signed   [31:0] bs;
    logic unsigned [31:0] au;
    logic unsigned [31:0] bu;

    assign as =   signed'(a);
    assign bs =   signed'(b);
    assign au = unsigned'(a);
    assign bu = unsigned'(b);

    always_comb begin
        unique case (aluop)
            3'b000 : f = au +   bu;
            3'b001 : f = au <<  bu[4:0];
            3'b010 : f = unsigned'(as >>> bu[4:0]);
            3'b011 : f = au -   bu;
            3'b100 : f = au ^   bu;
            3'b101 : f = au >>  bu[4:0];
            3'b110 : f = au |   bu;
            3'b111 : f = au &   bu;
            default: f = 'x;
        endcase
    end

endmodule : alu
