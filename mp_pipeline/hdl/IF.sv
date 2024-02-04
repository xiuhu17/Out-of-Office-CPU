module IF_Stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,

    // for stall purpose
    input   logic           pc_en,
    output  if_id_stage_reg_t if_id_stage_reg
);      

    logic   [63:0]  order;
    logic   [31:0]  pc;
    logic   [31:0]  data;

    always_ff @( posedge clk ) begin
        if (rst) begin 
            pc <= 32'h60000000;
            order <= '0;
        end else begin 
            if (pc_en) begin 
                pc <= pc + 'd4;
                order <= order + 'd1;
            end
        end 
    end

    // next_state update
    always_comb begin
        imem_addr = pc;
        imem_rmask = 4'b1111;
    end

    always_comb begin 
        if_id_stage_reg.pc = pc;
        if_id_stage_reg.order = order;
    end 

endmodule