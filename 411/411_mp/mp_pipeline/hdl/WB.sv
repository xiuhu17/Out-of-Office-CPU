module WB_Stage
import rv32i_types::*;
(   
    input logic clk,
    input logic rst,

    input       mem_wb_stage_reg_t mem_wb_stage_reg,

    input   logic           dmem_resp,
    input   logic   [31:0]  dmem_rdata,

    output      logic [4:0]     wb_rd_s,
    output      logic [31:0]    wb_rd_v,
    output      logic           wb_regf_we,

    input logic move_pipeline
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
    logic   [31:0]      lw;
    logic   [31:0]      lb;
    logic   [31:0]      lbu;
    logic   [31:0]      lh;
    logic   [31:0]      lhu; 
    logic   [31:0]      rs1_v;
    logic   [31:0]      rs2_v;
    logic   [4:0]       rs1_s;
    logic   [4:0]       rs2_s;
    logic   [4:0]       rd_s;
    logic   [31:0]      mem_addr;
    logic   [3:0]       mem_rmask;
    logic   [3:0]       mem_wmask;
    logic   [31:0]       mem_rdata;
    logic   [31:0]       mem_wdata;

    logic   [31:0]      wb_rd_v_grab;
    logic   [31:0]     dmem_rdata_store;

    always_ff @ (posedge clk) begin 
        if (rst) begin 
            dmem_rdata_store <= '0;
        end else if (dmem_resp) begin 
            dmem_rdata_store <= dmem_rdata;
        end 
    end 

    always_comb begin
        inst = mem_wb_stage_reg.inst;
        pc = mem_wb_stage_reg.pc;
        pc_next = mem_wb_stage_reg.pc_next;
        order = mem_wb_stage_reg.order;
        mem_signal = mem_wb_stage_reg.mem_signal;
        wb_signal = mem_wb_stage_reg.wb_signal;
        alu_out = mem_wb_stage_reg.alu_out;
        br_en = mem_wb_stage_reg.br_en;
        u_imm = mem_wb_stage_reg.u_imm;
        rd_s = mem_wb_stage_reg.rd_s;
        if (mem_signal.MemWrite) begin 
            rd_s = '0;
        end 
        if (inst[6:0] == br_opcode) begin
            rd_s = '0;
        end 
        rs1_v = mem_wb_stage_reg.rs1_v;
        rs2_v = mem_wb_stage_reg.rs2_v;
        rs1_s = mem_wb_stage_reg.rs1_s;
        rs2_s = mem_wb_stage_reg.rs2_s;
        if (mem_signal.MemRead) begin
            rs2_s = '0;
        end 
        mem_addr = mem_wb_stage_reg.mem_addr;
        mem_rmask = mem_wb_stage_reg.mem_rmask;
        mem_wmask = mem_wb_stage_reg.mem_wmask;
        mem_wdata = mem_wb_stage_reg.mem_wdata;
    end 

    // dmem
    always_comb begin 
        mem_rdata = 'x;
        lb = 'x;
        lbu = 'x;
        lh = 'x;
        lhu = 'x;
        lw = 'x;

        if (mem_signal.MemRead == '1 && move_pipeline == '1 && dmem_resp == '1) begin
            case (mem_signal.load_ops)
                lb_mem: begin 
                    lb = {{24{dmem_rdata[7 +8 * mem_addr[1:0]]}}, dmem_rdata[8 * mem_addr[1:0] +: 8 ]};
                    mem_rdata = dmem_rdata;
                end
                lbu_mem: begin 
                    lbu = {{24{1'b0}}                          , dmem_rdata[8 * mem_addr[1:0] +: 8 ]};
                    mem_rdata = dmem_rdata;
                end
                lh_mem: begin 
                    lh = {{16{dmem_rdata[15+16*mem_addr[1]  ]}}, dmem_rdata[16 * mem_addr[1]   +: 16]};
                    mem_rdata = dmem_rdata;
                end 
                lhu_mem: begin 
                    lhu = {{16{1'b0}}                          , dmem_rdata[16*mem_addr[1]   +: 16]};
                    mem_rdata = dmem_rdata;
                end
                lw_mem: begin 
                    lw = dmem_rdata;
                    mem_rdata = dmem_rdata;
                end
            endcase
        end else if (mem_signal.MemRead == '1 && move_pipeline == '1) begin 
            case (mem_signal.load_ops)
                lb_mem: begin 
                    lb = {{24{dmem_rdata_store[7 +8 * mem_addr[1:0]]}}, dmem_rdata_store[8 * mem_addr[1:0] +: 8 ]};
                    mem_rdata = dmem_rdata_store;
                end
                lbu_mem: begin 
                    lbu = {{24{1'b0}}                          , dmem_rdata_store[8 * mem_addr[1:0] +: 8 ]};
                    mem_rdata = dmem_rdata_store;
                end
                lh_mem: begin 
                    lh = {{16{dmem_rdata_store[15+16*mem_addr[1]  ]}}, dmem_rdata_store[16 * mem_addr[1]   +: 16]};
                    mem_rdata = dmem_rdata_store;
                end 
                lhu_mem: begin 
                    lhu = {{16{1'b0}}                          , dmem_rdata_store[16*mem_addr[1]   +: 16]};
                    mem_rdata = dmem_rdata_store;
                end
                lw_mem: begin 
                    lw = dmem_rdata_store;
                    mem_rdata = dmem_rdata_store;
                end
            endcase
        end 
    end

    // write back
    always_comb begin 
        wb_rd_v_grab = '0;
        if (mem_wb_stage_reg.valid) begin
            case (wb_signal.regf_m_sel)
                alu_out_wb: begin
                    wb_rd_v_grab = alu_out;
                end 
                br_en_wb:   begin 
                    wb_rd_v_grab = br_en;
                end 
                u_imm_wb:   begin       
                    wb_rd_v_grab = u_imm;
                end 
                lw_wb:  begin             
                    wb_rd_v_grab = lw;
                end
                lb_wb:  begin            
                    wb_rd_v_grab = lb;
                end
                lbu_wb: begin            
                    wb_rd_v_grab = lbu;
                end
                lh_wb:  begin            
                    wb_rd_v_grab = lh;
                end
                lhu_wb: begin             
                    wb_rd_v_grab = lhu;
                end
                pc_plus4_wb:        wb_rd_v_grab = pc + 4;
            endcase
        end 
    end 

    always_comb begin
        wb_rd_s = rd_s;
        wb_rd_v = wb_rd_v_grab;
        wb_regf_we = wb_signal.regf_we;
        valid = '0;
        if (mem_wb_stage_reg.valid && move_pipeline) begin
            valid = '1;
        end
    end 
endmodule
