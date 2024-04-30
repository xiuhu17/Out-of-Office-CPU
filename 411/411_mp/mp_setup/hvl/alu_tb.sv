module alu_tb;

    timeunit 1ns;
    timeprecision 1ns;

    logic   [2:0]   aluop;
    logic   [31:0]  a;
    logic   [31:0]  b;
    logic   [31:0]  f;

    alu dut(.*);

    initial begin
        $fsdbDumpfile("dump.fsdb");
        $fsdbDumpvars(0, "+all");
        
        a = 32'h800055AA;
        b = 32'h00000004;

        for (int i = 0; i < 8; i++) begin
            aluop = i;
            #1;
        end

        $finish;
    end

endmodule
