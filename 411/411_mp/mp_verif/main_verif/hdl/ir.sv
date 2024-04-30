module ir
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    input   logic           load_ir,
    input   logic   [31:0]  in,
    output  logic   [31:0]  out,
    output  logic   [2:0]   funct3,
    output  logic   [6:0]   funct7,
    output  logic   [6:0]   opcode,
    output  logic   [31:0]  i_imm,
    output  logic   [31:0]  s_imm,
    output  logic   [31:0]  b_imm,
    output  logic   [31:0]  u_imm,
    output  logic   [31:0]  j_imm,
    output  logic   [4:0]   rs1_s,
    output  logic   [4:0]   rs2_s,
    output  logic   [4:0]   rd_s
);

            logic   [31:0]  data;

    assign funct3 = data[14:12];
    assign funct7 = data[31:25];
    assign opcode = data[6:0];
    assign i_imm  = {{21{data[31]}}, data[30:20]};
    assign s_imm  = {{21{data[31]}}, data[30:25], data[11:7]};
    assign b_imm  = {{20{data[31]}}, data[7], data[30:25], data[11:8], 1'b0};
    assign u_imm  = {data[31:12], 12'h000};
    assign j_imm  = {{12{data[31]}}, data[19:12], data[20], data[30:21], 1'b0};
    assign rs1_s  = data[19:15];
    assign rs2_s  = data[24:20];
    assign rd_s   = data[11:7];

    always_ff @(posedge clk) begin
        if (rst) begin
            data <= '0;
        end else if (load_ir) begin
            data <= in;
        end else begin
            data <= data;
        end
    end

    assign out = data;

endmodule : ir
