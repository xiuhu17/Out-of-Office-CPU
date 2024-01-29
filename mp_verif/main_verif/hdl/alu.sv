module alu
import rv32i_types::*;
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
            alu_add: f = au +   bu;
            alu_sll: f = au <<  bu[4:0];
            alu_sra: f = unsigned'(as >>> bu[4:0]);
            alu_sub: f = au -   bu;
            alu_xor: f = au ^   bu;
            alu_srl: f = au >>  bu[4:0];
            alu_or:  f = au |   bu;
            alu_and: f = au &   bu;
            default: f = 'x;
        endcase
    end

endmodule : alu
