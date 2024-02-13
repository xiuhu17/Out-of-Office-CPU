module IF_Stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,

    // for stall purpose
    input   logic             not_stall,
    output  if_id_stage_reg_t if_id_stage_reg,

    input   logic             need_flush,
    input   logic [31:0]      target_pc
);      

    logic   [63:0]  order;
    logic   [63:0]  order_next;

    logic   [31:0]  pc;
    logic   [31:0]  pc_next;
    logic   [31:0]  data;

    always_ff @( posedge clk ) begin
        if (rst) begin 
            pc <= 32'h60000000;
            order <= '0;
        end else begin 
            if (not_stall) begin 
                pc <= pc_next;
                order <= order_next;
            end
        end 
    end

    // next_state update
    always_comb begin
        imem_addr = pc;
        imem_rmask = 4'b1111;
    end

    always_comb begin
        if (need_flush) begin 
            pc_next = (target_pc) & 32'hfffffffc;
            order_next = order - 'd1;
        end else begin 
            pc_next = (pc + 'd4) & 32'hfffffffc;
            order_next = order + 'd1;
        end 
    end 

    always_comb begin 
        if_id_stage_reg.pc = pc;
        if_id_stage_reg.pc_next = pc_next;
        if_id_stage_reg.order = order;
        if_id_stage_reg.valid = 1'b1;
        if (need_flush) begin 
            if_id_stage_reg = '0;
        end
    end 

endmodule