module MEM_Stage(
    input clk,
    input rst,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp,

    input   ex_mem_stage_reg_t ex_mem_stage_reg,
    output  mem_wb_stage_reg_t mem_wb_stage_reg
);

    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [63:0]      order;

    mem_signal_t        mem_signal;
    wb_signal_t         wb_signal;
    
    // value
    logic   [31:0]      alu_out;
    logic   [31:0]      br_en;
    logic   [31:0]      u_imm;
    logic   [31:0]      rs2_v;
    logic   [4:0]       rd_s;

    logic   [31:0]      lw;
    logic   [31:0]      lb;
    logic   [31:0]      lbu;
    logic   [31:0]      lh;
    logic   [31:0]      lhu;

    
    always_comb begin 
        inst = ex_mem_stage_reg.inst;
        pc = ex_mem_stage_reg.pc;
        order = ex_mem_stage_reg.order;
        mem_signal = ex_mem_stage_reg.mem_signal;
        wb_signal = ex_mem_stage_reg.wb_signal;
        alu_out = ex_mem_stage_reg.alu_out;
        br_en = ex_mem_stage_reg.br_en;
        u_imm = ex_mem_stage_reg.u_imm;
        rs2_v = ex_mem_stage_reg.rs2_v;
        rd_s = ex_mem_stage_reg.rd_s;
        lw = '0;
        lb = '0;
        lbu = '0;
        lh = '0;
        lhu = '0;
    end 

    always_comb begin 
        mem_wb_stage_reg.inst = inst;
        mem_wb_stage_reg.pc = pc;
        mem_wb_stage_reg.order = order;
        mem_wb_stage_reg.is_stall = 1'b0; // default value
        mem_wb_stage_reg.wb_signal = wb_signal;
        mem_wb_stage_reg.alu_out = alu_out;
        mem_wb_stage_reg.br_en = br_en;
        mem_wb_stage_reg.u_imm = u_imm;
        mem_wb_stage_reg.lw = lw;
        mem_wb_stage_reg.lb = lb;
        mem_wb_stage_reg.lbu = lbu;
        mem_wb_stage_reg.lh = lh;
        mem_wb_stage_reg.lhu = lhu;
        mem_wb_stage_reg.rd_s = rd_s;
    end 

endmodule