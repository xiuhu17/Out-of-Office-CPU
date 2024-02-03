module IF_Stage
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    // for stall purpose
    input   logic           pc_en,
    output  if_id_stage_reg_t if_id_stage_reg
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


    // next_state update
    always_comb begin
        next_state = curr_state;
        imem_addr = 'x;
        imem_rmask = 4'b0;
        load_ir = 1'b0;
        case (curr_state) 
            s_reset: begin
                next_state = s_fetching;
            end
            s_fetching: begin
                imem_addr = pc;
                imem_rmask = 4'b1111;
                if (imem_resp) begin 
                    load_ir = 1'b1;
                end     
            end
        endcase
    end

    // next_pc update
    always_comb begin
        next_pc = pc + 4;
    end

    ir ir (
        .clk(clk),
        .rst(rst),
        .load_ir(load_ir),
        .in(imem_rdata), 
        .out(if_id_stage_reg.inst),
        .funct3(if_id_stage_reg.funct3),
        .funct7(if_id_stage_reg.funct7),
        .opcode(if_id_stage_reg.opcode),
        .i_imm(if_id_stage_reg.i_imm),
        .s_imm(if_id_stage_reg.s_imm),
        .b_imm(if_id_stage_reg.b_imm),
        .u_imm(if_id_stage_reg.u_imm),
        .j_imm(if_id_stage_reg.j_imm),
        .rs1_s(if_id_stage_reg.rs1_s),
        .rs2_s(if_id_stage_reg.rs2_s),
        .rd_s(if_id_stage_reg.rd_s)
    );

    assign if_id_stage_reg.order = order;
    assign if_id_stage_reg.pc = pc;
    assign if_id_stage_reg.valid = 1'b0;

endmodule