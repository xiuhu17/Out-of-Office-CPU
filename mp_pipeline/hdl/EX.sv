module EX_Stage(
    input   id_ex_stage_reg_t id_ex_stage_reg,
    output  ex_mem_stage_reg_t ex_mem_stage_reg
);  


    logic   [31:0]      inst;
    logic   [31:0]      pc;
    logic   [63:0]      order;

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
    logic   [31:0]      rs2_v;
    logic   [4:0]       rs1_s;
    logic   [4:0]       rs2_s;
    logic   [4:0]       rd_s;

    // value
    logic   [31:0]      alu_out_grab;
    logic   [31:0]      br_en_grab;

    always_comb begin 
        inst = id_ex_stage_reg.inst;
        pc = id_ex_stage_reg.pc;
        order = id_ex_stage_reg.order;
        ex_signal = id_ex_stage_reg.ex_signal;
        mem_signal = id_ex_stage_reg.mem_signal;
        wb_signal = id_ex_stage_reg.wb_signal;
        i_imm = id_ex_stage_reg.i_imm;
        s_imm = id_ex_stage_reg.s_imm;
        b_imm = id_ex_stage_reg.b_imm;
        u_imm = id_ex_stage_reg.u_imm;
        j_imm = id_ex_stage_reg.j_imm;
        rs1_v = id_ex_stage_reg.rs1_v;
        rs2_v = id_ex_stage_reg.rs2_v;
        rs1_s = id_ex_stage_reg.rs1_s;
        rs2_s = id_ex_stage_reg.rs2_s;
        rd_s = id_ex_stage_reg.rd_s;
    end 


    // alu_m1
    logic [31:0]    alu_m1_sel_grab;
    always_comb begin 
        alu_m1_sel_grab = 'x;
        case (ex_signal.alu_m1_sel)
            rs1_value_alu_ex: alu_m1_sel_grab = rs1_v;
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
            rs2_value_alu_ex: alu_m2_sel_grab = rs2_v;
        endcase
    end 

    // cmp_m
    logic [31:0]   cmp_m_sel_grab;
    always_comb begin
        cmp_m_sel_grab = 'x;
        case (ex_signal.cmp_m_sel) 
            rs2_value_cmp_ex: cmp_m_sel_grab = rs2_v;
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
        .f(br_en_grab)
    );


    always_comb begin
        ex_mem_stage_reg.inst = inst;
        ex_mem_stage_reg.pc = pc;
        ex_mem_stage_reg.order = order;
        ex_mem_stage_reg.is_stall = 1'b0; // default value

        ex_mem_stage_reg.mem_signal = mem_signal;
        ex_mem_stage_reg.wb_signal = wb_signal;

        ex_mem_stage_reg.alu_out = alu_out_grab;
        ex_mem_stage_reg.br_en = br_en_grab;
        ex_mem_stage_reg.u_imm = u_imm;
        ex_mem_stage_reg.rs2_v = rs2_v;
        ex_mem_stage_reg.rd_s = rd_s;   
    end 

endmodule