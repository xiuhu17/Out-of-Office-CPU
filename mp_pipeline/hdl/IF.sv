module IF_Stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp
);      

    logic   [63:0]  order;
    logic           commit;
    logic   [31:0]  pc;
    logic   [31:0]  inst;
    logic           load_ir;
    


    enum int unsigned {
        s_halt, s_reset, s_lui, s_aupic, s_jal, s_jalr, s_br,
        s_load, s_store, s_ri, s_rr, s_csr
    } curr_state, next_state;


    always_ff @( posedge clk ) begin
        if (rst) begin 
            curr_state <= s_reset;
        end 
    end


endmodule;