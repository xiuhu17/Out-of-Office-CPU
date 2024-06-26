module EX_Stage
import rv32i_types::*;
(
    input   id_ex_stage_reg_t id_ex_stage_reg,
    output  ex_mem_stage_reg_t ex_mem_stage_reg,

    input   ex_mem_stage_reg_t ex_mem_stage_reg_curr,
    input   logic[31:0]         wb_rd_v,

    input ex_rs1_forward_sel_t         ex_rs1_forward_sel,
    input ex_rs2_forward_sel_t         ex_rs2_forward_sel,

    output   logic          branch_flush,
    output   logic [31:0]   target_pc
);  

    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [31:0]      pc_next;
    logic   [63:0]      order;
    logic               valid;
    // control signal
    ex_signal_t     ex_signal;
    mem_signal_t    mem_signal;
    wb_signal_t     wb_signal;
    // value
    logic   [31:0]      i_imm;
    logic   [31:0]      s_imm;
    logic   [31:0]      b_imm;
    logic   [31:0]      u_imm;
    logic   [31:0]      j_imm;
    logic   [31:0]      rs1_v;
    logic   [31:0]      rs1_v_ex;
    logic   [31:0]      rs1_v_mem;
    logic   [31:0]      rs1_v_wb;
    logic   [31:0]      rs2_v;
    logic   [31:0]      rs2_v_ex;
    logic   [31:0]      rs2_v_mem;
    logic   [31:0]      rs2_v_wb;
    logic   [4:0]       rs1_s;
    logic   [4:0]       rs2_s;
    logic   [4:0]       rd_s;
    logic   [31:0]      mem_addr;
    logic   [3:0]       mem_rmask;
    logic   [3:0]       mem_wmask;
    logic   [31:0]       mem_wdata;
    logic   [6:0]       opcode;
    assign opcode =  inst[6:0];

    // value
    logic   [31:0]      alu_out_grab;
    logic               br_en_grab;

    always_comb begin 
        inst = id_ex_stage_reg.inst;
        pc = id_ex_stage_reg.pc;
        order = id_ex_stage_reg.order;
        valid = id_ex_stage_reg.valid;
        ex_signal = id_ex_stage_reg.ex_signal;
        mem_signal = id_ex_stage_reg.mem_signal;
        wb_signal = id_ex_stage_reg.wb_signal;
        i_imm = id_ex_stage_reg.i_imm;
        s_imm = id_ex_stage_reg.s_imm;
        b_imm = id_ex_stage_reg.b_imm;
        u_imm = id_ex_stage_reg.u_imm;
        j_imm = id_ex_stage_reg.j_imm;
        rs1_v_ex = id_ex_stage_reg.rs1_v;
        rs2_v_ex = id_ex_stage_reg.rs2_v;
        rs1_s = id_ex_stage_reg.rs1_s;
        rs2_s = id_ex_stage_reg.rs2_s;
        rd_s = id_ex_stage_reg.rd_s;
    end 

    // forwarding
    always_comb begin 
        rs1_v_mem = 'x;
        rs2_v_mem = 'x;
        case(ex_mem_stage_reg_curr.wb_signal.regf_m_sel) 
            alu_out_wb: begin
                rs1_v_mem = ex_mem_stage_reg_curr.alu_out;
                rs2_v_mem = ex_mem_stage_reg_curr.alu_out;
            end 
            br_en_wb:   begin 
                rs1_v_mem = ex_mem_stage_reg_curr.br_en;
                rs2_v_mem = ex_mem_stage_reg_curr.br_en;
            end 
            u_imm_wb:   begin       
                rs1_v_mem = ex_mem_stage_reg_curr.u_imm;
                rs2_v_mem = ex_mem_stage_reg_curr.u_imm;
            end 
            pc_plus4_wb: begin 
                rs1_v_mem = ex_mem_stage_reg_curr.pc + 4;
                rs2_v_mem = ex_mem_stage_reg_curr.pc + 4;
            end 
        endcase 
    end 

    always_comb begin 
        rs1_v_wb = wb_rd_v;
        rs2_v_wb = wb_rd_v;
    end 

    always_comb begin 
        rs1_v = 'x;
        rs2_v = 'x;
        case (ex_rs1_forward_sel)  
            rs1_s_ex_ex: rs1_v = rs1_v_ex;
            rs1_s_mem_ex: rs1_v = rs1_v_mem;
            rs1_s_wb_ex:  rs1_v = rs1_v_wb;
        endcase 
        case (ex_rs2_forward_sel)  
            rs2_s_ex_ex: rs2_v = rs2_v_ex;
            rs2_s_mem_ex: rs2_v = rs2_v_mem;
            rs2_s_wb_ex:  rs2_v = rs2_v_wb;
        endcase
    end

    // branch
    always_comb begin
        pc_next = id_ex_stage_reg.pc_next;
        branch_flush = '0;
        target_pc = '0;
        case (opcode)
            jal_opcode: begin 
                if (pc_next != ((pc + j_imm))) begin 
                    branch_flush = '1;
                    target_pc = pc + j_imm;
                    pc_next = pc + j_imm;
                end 
            end 
            jalr_opcode: begin 
                if (pc_next != ((rs1_v + i_imm) & 32'hfffffffe)) begin 
                    branch_flush = '1;
                    target_pc = (rs1_v + i_imm) & 32'hfffffffe;
                    pc_next = (rs1_v + i_imm) & 32'hfffffffe;
                end
            end 
            br_opcode: begin
                if (br_en_grab) begin 
                    if (pc_next != ((pc + b_imm))) begin 
                        branch_flush = '1;
                        target_pc = pc + b_imm;
                        pc_next = pc + b_imm;
                    end
                end
            end 
        endcase
    end 

    // alu_m1
    logic [31:0]    alu_m1_sel_grab;
    always_comb begin 
        alu_m1_sel_grab = 'x;
        case (ex_signal.alu_m1_sel)
            rs1_v_alu_ex: alu_m1_sel_grab = rs1_v;
            pc_out_alu_ex: alu_m1_sel_grab = pc;
        endcase
    end 

    // alu_m2
    logic [31:0]    alu_m2_sel_grab;
    always_comb begin 
        alu_m2_sel_grab = 'x;
        case (ex_signal.alu_m2_sel)
            i_imm_alu_ex: alu_m2_sel_grab = i_imm;
            u_imm_alu_ex: alu_m2_sel_grab = u_imm;  
            b_imm_alu_ex: alu_m2_sel_grab = b_imm;  
            s_imm_alu_ex: alu_m2_sel_grab = s_imm;  
            j_imm_alu_ex: alu_m2_sel_grab = j_imm;
            rs2_v_alu_ex: alu_m2_sel_grab = rs2_v;
        endcase
    end 

    // cmp_m
    logic [31:0]   cmp_m_sel_grab;
    always_comb begin
        cmp_m_sel_grab = 'x;
        case (ex_signal.cmp_m_sel) 
            rs2_v_cmp_ex: cmp_m_sel_grab = rs2_v;
            i_imm_cmp_ex: cmp_m_sel_grab = i_imm;
        endcase
    end 

    // alu
    alu alu(
        .aluop(ex_signal.alu_ops),
        .a(alu_m1_sel_grab),
        .b(alu_m2_sel_grab),
        .f(alu_out_grab)
    );

    // cmp
    cmp cmp(
        .cmpop(ex_signal.cmp_ops),
        .a(rs1_v),
        .b(cmp_m_sel_grab),
        .br_en(br_en_grab)
    );


    // dmem
    always_comb begin
        mem_addr = '0;
        mem_wdata = '0;
        mem_rmask = '0;
        mem_wmask = '0;

        if (mem_signal.MemRead) begin
            case (mem_signal.load_ops) 
                lb_mem, lbu_mem: begin 
                    mem_addr = alu_out_grab;
                    mem_rmask = 4'b0001 << mem_addr[1:0];
                end
                lh_mem, lhu_mem: begin 
                    mem_addr = alu_out_grab;
                    mem_rmask = 4'b0011 << mem_addr[1:0];
                end 
                lw_mem: begin
                    mem_addr = alu_out_grab;
                    mem_rmask = 4'b1111;
                end 
            endcase
        end else if (mem_signal.MemWrite) begin 
            case (mem_signal.store_ops)
                sb_mem: begin 
                    mem_addr = alu_out_grab;
                    mem_wmask = 4'b0001 << mem_addr[1:0];
                    mem_wdata[8 * mem_addr[1:0] +: 8] = rs2_v[7:0];
                end
                sh_mem: begin  
                    mem_addr = alu_out_grab;
                    mem_wmask = 4'b0011 << mem_addr[1:0];
                    mem_wdata[16 * mem_addr[1] +: 16] = rs2_v[15:0];
                end
                sw_mem: begin
                    mem_addr = alu_out_grab;
                    mem_wmask = 4'b1111;
                    mem_wdata = rs2_v;
                end
            endcase
        end
    end 

    always_comb begin
        ex_mem_stage_reg.inst = inst;
        ex_mem_stage_reg.pc = pc;
        ex_mem_stage_reg.pc_next = pc_next;
        ex_mem_stage_reg.order = order;
        ex_mem_stage_reg.valid = valid; 
        ex_mem_stage_reg.mem_signal = mem_signal;
        ex_mem_stage_reg.wb_signal = wb_signal;
        ex_mem_stage_reg.alu_out = alu_out_grab;
        ex_mem_stage_reg.br_en = {31'd0, br_en_grab};
        ex_mem_stage_reg.u_imm = u_imm;
        ex_mem_stage_reg.rs1_v = rs1_v;
        ex_mem_stage_reg.rs2_v = rs2_v;
        ex_mem_stage_reg.rs1_s = rs1_s;
        ex_mem_stage_reg.rs2_s = rs2_s;
        ex_mem_stage_reg.rd_s = rd_s;   
        ex_mem_stage_reg.mem_addr = mem_addr;
        ex_mem_stage_reg.mem_rmask = mem_rmask;
        ex_mem_stage_reg.mem_wmask = mem_wmask;
        ex_mem_stage_reg.mem_wdata = mem_wdata;
    end 

endmodule
