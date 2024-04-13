interface mon_itf(
    input   bit             clk,
    input   bit             rst
);

            logic           valid [8];
            logic   [63:0]  order [8];
            logic   [31:0]  inst [8];
            logic           halt [8];
            logic   [4:0]   rs1_addr [8];
            logic   [4:0]   rs2_addr [8];
            logic   [31:0]  rs1_rdata [8];
            logic   [31:0]  rs2_rdata [8];
            logic   [4:0]   rd_addr [8];
            logic   [31:0]  rd_wdata [8];
            logic   [31:0]  pc_rdata [8];
            logic   [31:0]  pc_wdata [8];
            logic   [31:0]  mem_addr [8];
            logic   [3:0]   mem_rmask [8];
            logic   [3:0]   mem_wmask [8];
            logic   [31:0]  mem_rdata [8];
            logic   [31:0]  mem_wdata [8];

            bit             error = 1'b0;

endinterface
