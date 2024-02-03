module WB_Stage
import rv32i_types::*;
(
    input       mem_wb_stage_reg_t mem_wb_stage_reg,
    output      logic [4:0]     wb_rd_s,
    output      logic [31:0]    wb_rd_v,
    output      logic           wb_regf_we
);

    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [63:0]      order;
    logic               is_stall;

    wb_signal_t         wb_signal;
    
    // value
    logic   [31:0]      alu_out;
    logic   [31:0]      br_en;
    logic   [31:0]      u_imm;
    logic   [31:0]      lw;
    logic   [31:0]      lb;
    logic   [31:0]      lbu;
    logic   [31:0]      lh;
    logic   [31:0]      lhu;
    logic   [4:0]       rd_s; 
    logic   [31:0]      wb_rd_v_grab;

    always_comb begin
        inst = mem_wb_stage_reg.inst;
        pc = mem_wb_stage_reg.pc;
        order = mem_wb_stage_reg.order;
        is_stall = mem_wb_stage_reg.is_stall;
        wb_signal = mem_wb_stage_reg.wb_signal;
        alu_out = mem_wb_stage_reg.alu_out;
        br_en = mem_wb_stage_reg.br_en;
        u_imm = mem_wb_stage_reg.u_imm;
        lw = mem_wb_stage_reg.lw;
        lb = mem_wb_stage_reg.lb;
        lbu = mem_wb_stage_reg.lbu;
        lh = mem_wb_stage_reg.lh;
        lhu = mem_wb_stage_reg.lhu;
        rd_s = mem_wb_stage_reg.rd_s;
    end 

    always_comb begin 
        wb_rd_v_grab = 'x;
        case (wb_signal.regf_m_sel)
            alu_out_wb:         wb_rd_v_grab = alu_out;
            br_en_wb:           wb_rd_v_grab = br_en;
            u_imm_wb:           wb_rd_v_grab = u_imm;
            lw_wb:              wb_rd_v_grab = lw;
            pc_plus4_wb:        wb_rd_v_grab = pc + 4;
            lb_wb:              wb_rd_v_grab = lb;
            lbu_wb:             wb_rd_v_grab = lbu;
            lh_wb:              wb_rd_v_grab = lh;
            lhu_wb:             wb_rd_v_grab = lhu;
        endcase
    end 

    always_comb begin
        wb_rd_s = rd_s;
        wb_rd_v = wb_rd_v_grab;
        wb_regf_we = wb_signal.regf_we;
    end 

endmodule