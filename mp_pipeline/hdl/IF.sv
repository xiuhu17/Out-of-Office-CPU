module IF_Stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,


    input   logic           pc_en,
    input   logic           pc_sel,
    input   logic [31:0]    pc_br_jp,
);      

    logic   [63:0]  order;
    logic   [31:0]  pc, next_pc;
    logic   [31:0]  inst;
    logic           load_ir;

    enum int unsigned {
        s_reset, s_fetching
    } curr_state, next_state;

    always_ff @( posedge clk ) begin
        if (rst) begin 
            curr_state <= s_reset;
            pc <= 32'h60000000;
            order <= 0;
        end else begin 
            if (pc_en) begin 
                pc <= next_pc;
                order <= order + 'd1;
            end
        end 
    end

    always_comb begin
        next_state = curr_state;
        case (curr_state) 
            s_reset: begin
                next_state = s_fetching;
            end
            s_fetching: begin
                imem_addr = pc;
                imem_rmask = 4'b1111;
                if (mem_resp) begin 
                    load_ir = 1'b1;
                end     
            end
        endcase
    end

    always_comb begin
        case (pc_sel)
            0: next_pc = pc + 4;
            1: next_pc = pc_br_jp;
        endcase
    end

    ir ir ();

    
endmodule;