module Forwarding
import rv32i_types::*;    
(
    input logic [4:0]                   id_rs1_s,
    input logic [4:0]                   id_rs2_s,
    input id_ex_stage_reg_t             id_ex_stage_reg,
    input ex_mem_stage_reg_t            ex_mem_stage_reg,
    input mem_wb_stage_reg_t            mem_wb_stage_reg,

    output logic                        forwarding_stall,
    output id_rs1_forward_sel_t         id_rs1_forward_sel,
    output id_rs2_forward_sel_t         id_rs2_forward_sel,
    output ex_rs1_forward_sel_t         ex_rs1_forward_sel,
    output ex_rs2_forward_sel_t         ex_rs2_forward_sel
);

    always_comb begin
        forwarding_stall = '0;
        id_rs1_forward_sel = rs1_s_id_id;
        id_rs2_forward_sel = rs2_s_id_id;
        ex_rs1_forward_sel = rs1_s_ex_ex;
        ex_rs2_forward_sel = rs2_s_ex_ex;

        // decode 
        if (mem_wb_stage_reg.rd_s != '0 && mem_wb_stage_reg.wb_signal.regf_we && mem_wb_stage_reg.rd_s == id_rs1_s) begin 
            id_rs1_forward_sel = rs1_s_wb_id;
        end 
        if (mem_wb_stage_reg.rd_s != '0 && mem_wb_stage_reg.wb_signal.regf_we && mem_wb_stage_reg.rd_s == id_rs2_s) begin 
            id_rs2_forward_sel = rs2_s_wb_id;
        end 

        // forwarding_stall
        if (id_ex_stage_reg.rd_s != '0 && id_ex_stage_reg.wb_signal.regf_we && id_ex_stage_reg.mem_signal.MemRead && 
            (id_ex_stage_reg.rd_s == id_rs1_s || id_ex_stage_reg.rd_s == id_rs2_s)) begin 
            forwarding_stall = '1;
        end 

        // normal 
        if (ex_mem_stage_reg.rd_s != '0 && ex_mem_stage_reg.wb_signal.regf_we && ex_mem_stage_reg.rd_s == id_ex_stage_reg.rs1_s) begin 
            ex_rs1_forward_sel = rs1_s_mem_ex;
        end
        if (ex_mem_stage_reg.rd_s != '0 && ex_mem_stage_reg.wb_signal.regf_we && ex_mem_stage_reg.rd_s == id_ex_stage_reg.rs2_s) begin 
            ex_rs2_forward_sel = rs2_s_mem_ex;
        end
        if (!(ex_mem_stage_reg.rd_s != '0 && ex_mem_stage_reg.wb_signal.regf_we && ex_mem_stage_reg.rd_s == id_ex_stage_reg.rs1_s) &&
             mem_wb_stage_reg.rd_s != '0 && mem_wb_stage_reg.wb_signal.regf_we && mem_wb_stage_reg.rd_s == id_ex_stage_reg.rs1_s) begin 
            ex_rs1_forward_sel = rs1_s_wb_ex;
        end  
        if (!(ex_mem_stage_reg.rd_s != '0 && ex_mem_stage_reg.wb_signal.regf_we && ex_mem_stage_reg.rd_s == id_ex_stage_reg.rs2_s) &&
             mem_wb_stage_reg.rd_s != '0 && mem_wb_stage_reg.wb_signal.regf_we && mem_wb_stage_reg.rd_s == id_ex_stage_reg.rs2_s) begin 
            ex_rs2_forward_sel = rs2_s_wb_ex;
        end 
        
    end
endmodule