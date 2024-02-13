module MEM_Stage
import rv32i_types::*;
(

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    output  logic   [31:0]  dmem_wdata,
 
    input   ex_mem_stage_reg_t ex_mem_stage_reg,
    output  mem_wb_stage_reg_t mem_wb_stage_reg
);

    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [31:0]      pc_next;
    logic   [63:0]      order;
    logic               valid;
    mem_signal_t        mem_signal;
    wb_signal_t         wb_signal;
    // value
    logic   [31:0]      alu_out;
    logic   [31:0]      br_en;
    logic   [31:0]      u_imm;
    logic   [31:0]      rs1_v;
    logic   [31:0]      rs2_v;
    logic   [4:0]       rs1_s;
    logic   [4:0]       rs2_s;
    logic   [4:0]       rd_s;

    logic   [31:0]      lw;
    logic   [31:0]      lb;
    logic   [31:0]      lbu;
    logic   [31:0]      lh;
    logic   [31:0]      lhu;

    
    always_comb begin 
        inst = ex_mem_stage_reg.inst;
        pc = ex_mem_stage_reg.pc;
        pc_next = ex_mem_stage_reg.pc_next;
        order = ex_mem_stage_reg.order;
        valid = ex_mem_stage_reg.valid;
        mem_signal = ex_mem_stage_reg.mem_signal;
        wb_signal = ex_mem_stage_reg.wb_signal;
        alu_out = ex_mem_stage_reg.alu_out;
        br_en = ex_mem_stage_reg.br_en;
        u_imm = ex_mem_stage_reg.u_imm;
        rs1_v = ex_mem_stage_reg.rs1_v;
        rs2_v = ex_mem_stage_reg.rs2_v;
        rs1_s = ex_mem_stage_reg.rs1_s;
        rs2_s = ex_mem_stage_reg.rs2_s;
        rd_s = ex_mem_stage_reg.rd_s;
        dmem_addr = ex_mem_stage_reg.mem_addr & 32'hfffffffc;
        dmem_rmask = ex_mem_stage_reg.mem_rmask;
        dmem_wmask = ex_mem_stage_reg.mem_wmask;
        dmem_wdata =  ex_mem_stage_reg.mem_wdata;
    end 

    always_comb begin 
        mem_wb_stage_reg.inst = inst;
        mem_wb_stage_reg.pc = pc;
        mem_wb_stage_reg.pc_next = pc_next;
        mem_wb_stage_reg.order = order;
        mem_wb_stage_reg.valid = valid;
        mem_wb_stage_reg.mem_signal = mem_signal;
        mem_wb_stage_reg.wb_signal = wb_signal;
        mem_wb_stage_reg.alu_out = alu_out;
        mem_wb_stage_reg.br_en = br_en;
        mem_wb_stage_reg.u_imm = u_imm;
        mem_wb_stage_reg.rs1_v = rs1_v;
        mem_wb_stage_reg.rs2_v = rs2_v; 
        mem_wb_stage_reg.rs1_s = rs1_s;
        mem_wb_stage_reg.rs2_s = rs2_s;
        mem_wb_stage_reg.rd_s = rd_s;
        mem_wb_stage_reg.mem_addr = ex_mem_stage_reg.mem_addr;
        mem_wb_stage_reg.mem_rmask = ex_mem_stage_reg.mem_rmask;
        mem_wb_stage_reg.mem_wmask = ex_mem_stage_reg.mem_wmask;
        mem_wb_stage_reg.mem_wdata = ex_mem_stage_reg.mem_wdata;
    end 

endmodule