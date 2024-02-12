package pcmux;
    typedef enum bit [1:0] {
        pc_plus4  = 2'b00
        ,alu_out  = 2'b01
        ,alu_mod2 = 2'b10
    } pcmux_sel_t;
endpackage

package marmux;
    typedef enum bit {
        pc_out = 1'b0
        ,alu_out = 1'b1
    } marmux_sel_t;
endpackage

package cmpmux;
    typedef enum bit {
        rs2_out = 1'b0
        ,i_imm = 1'b1
    } cmpmux_sel_t;
endpackage

package alumux;
    typedef enum bit {
        rs1_out = 1'b0
        ,pc_out = 1'b1
    } alumux1_sel_t;

    typedef enum bit [2:0] {
        i_imm    = 3'b000
        ,u_imm   = 3'b001
        ,b_imm   = 3'b010
        ,s_imm   = 3'b011
        ,j_imm   = 3'b100
        ,rs2_out = 3'b101
    } alumux2_sel_t;
endpackage

package regfilemux;
    typedef enum bit [3:0] {
        alu_out   = 4'b0000
        ,br_en    = 4'b0001
        ,u_imm    = 4'b0010
        ,lw       = 4'b0011
        ,pc_plus4 = 4'b0100
        ,lb        = 4'b0101
        ,lbu       = 4'b0110  // unsigned byte
        ,lh        = 4'b0111
        ,lhu       = 4'b1000  // unsigned halfword
    } regfilemux_sel_t;
endpackage


package rv32i_types;

    // Mux types are in their own packages to prevent identiier collisions
    // e.g. pcmux::pc_plus4 and regfilemux::pc_plus4 are seperate identifiers
    // for seperate enumerated types
    import pcmux::*;
    import marmux::*;
    import cmpmux::*;
    import alumux::*;
    import regfilemux::*;

    typedef enum bit [6:0] {
        lui_opcode   = 7'b0110111, // load upper immediate (U type)
        auipc_opcode = 7'b0010111, // add upper immediate PC (U type)
        jal_opcode   = 7'b1101111, // jump and link (J type)
        jalr_opcode  = 7'b1100111, // jump and link register (I type)
        br_opcode    = 7'b1100011, // branch (B type)
        load_opcode  = 7'b0000011, // load (I type)
        store_opcode = 7'b0100011, // store (S type)
        imm_opcode   = 7'b0010011, // arith ops with register/immediate operands (I type)
        reg_opcode   = 7'b0110011,  // arith ops with register operands (R type)
        csr_opcode   = 7'b1110011  // I control and status register 
    } rv32i_opcode;
    typedef enum bit [2:0] {
        add_funct3  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll_funct3  = 3'b001,
        slt_funct3  = 3'b010,
        sltu_funct3 = 3'b011,
        axor_funct3 = 3'b100,
        sr_funct3   = 3'b101, //check bit 30 for logical/arithmetic
        aor_funt3  = 3'b110,
        aand_funct3 = 3'b111
    } arith_funct3_t;
    typedef enum bit [2:0] {
        beq_funct3  = 3'b000,
        bne_funct3  = 3'b001,
        blt_funct3  = 3'b100,
        bge_funct3  = 3'b101,
        bltu_funct3 = 3'b110,
        bgeu_funct3 = 3'b111
    } branch_funct3_t;
    typedef enum bit [2:0] {
        lb_funct3  = 3'b000,
        lh_funct3  = 3'b001,
        lw_funct3  = 3'b010,
        lbu_funct3 = 3'b100,
        lhu_funct3 = 3'b101
    } load_funct3_t;
    typedef enum bit [2:0] {
        sb_funct3 = 3'b000,
        sh_funct3 = 3'b001,
        sw_funct3 = 3'b010
    } store_funct3_t;
    typedef enum bit [6:0] {
        base_funct7    = 7'b0000000,
        variant_funct7 = 7'b0100000
    } arith_funct7_t;

    typedef enum bit [2:0] {
        add_alu_op = 3'b000,
        sll_alu_op = 3'b001,
        sra_alu_op = 3'b010,
        sub_alu_op = 3'b011,
        xor_alu_op = 3'b100,
        srl_alu_op = 3'b101,
        or_alu_op  = 3'b110,
        and_alu_op = 3'b111
    } alu_ops_t;
    typedef enum bit [2:0] {
        beq_cmp_op  = 3'b000,
        bne_cmp_op  = 3'b001,
        blt_cmp_op  = 3'b100,
        bge_cmp_op  = 3'b101,
        bltu_cmp_op = 3'b110,
        bgeu_cmp_op = 3'b111
    } cmp_ops_t;


    typedef enum bit {
        rs1_v_alu_ex = 1'b0,
        pc_out_alu_ex = 1'b1
    } alu_m1_sel_t;
    typedef enum bit [2:0] {
        i_imm_alu_ex    = 3'b000, 
        u_imm_alu_ex   = 3'b001, 
        b_imm_alu_ex   = 3'b010,
        s_imm_alu_ex   = 3'b011,
        j_imm_alu_ex   = 3'b100,
        rs2_v_alu_ex = 3'b101
    } alu_m2_sel_t;
    typedef enum bit {
        rs2_v_cmp_ex = 1'b0,
        i_imm_cmp_ex = 1'b1
    } cmp_m_sel_t;
    typedef enum bit [2:0] {
        lb_mem  = 3'b000,
        lh_mem  = 3'b001,
        lw_mem  = 3'b010,
        lbu_mem = 3'b100,
        lhu_mem = 3'b101
    } load_ops_t;
    typedef enum bit [2:0] {
        sb_mem = 3'b000,
        sh_mem = 3'b001,
        sw_mem = 3'b010
    } store_ops_t;
    typedef enum bit [3:0] {
        alu_out_wb   = 4'b0000
        ,br_en_wb    = 4'b0001
        ,u_imm_wb    = 4'b0010
        ,lw_wb       = 4'b0011
        ,pc_plus4_wb = 4'b0100
        ,lb_wb        = 4'b0101
        ,lbu_wb       = 4'b0110  // unsigned byte
        ,lh_wb        = 4'b0111
        ,lhu_wb       = 4'b1000  // unsigned halfword
    } regf_m_sel_t;
    typedef enum bit[1:0] {
        rs1_s_ex_ex = 2'b00,
        rs1_s_mem_ex = 2'b01,
        rs1_s_wb_ex = 2'b10 
    } ex_rs1_forward_sel_t;
    typedef enum bit[1:0] {
        rs2_s_ex_ex = 2'b00,
        rs2_s_mem_ex = 2'b01,
        rs2_s_wb_ex = 2'b10 
    } ex_rs2_forward_sel_t;
    // transparent register
    typedef enum bit {
        rs1_s_id_id = 1'b0,
        rs1_s_wb_id = 1'b1
    } id_rs1_forward_sel_t;
    typedef enum bit {
        rs2_s_id_id = 1'b0,
        rs2_s_wb_id = 1'b1
    } id_rs2_forward_sel_t;

    typedef struct packed {
        // signal for alu
        logic                   alu_m1_sel;
        logic [2:0]             alu_m2_sel;
        logic [2:0]             alu_ops;
        // signal for cmp
        // default is rs1_v
        logic                   cmp_m_sel;
        logic [2:0]             cmp_ops;
    }ex_signal_t;
    typedef struct packed {
        logic               MemRead;
        logic               MemWrite;
        logic [2:0]         load_ops;
        logic [2:0]         store_ops;
    }mem_signal_t;
    typedef struct packed {
        logic [3:0]         regf_m_sel;
        logic               regf_we;
    }wb_signal_t;

    typedef struct packed {
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic               valid;
    } if_id_stage_reg_t;
    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
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
        logic   [31:0]      rs2_v;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [4:0]       rd_s;
    } id_ex_stage_reg_t;
    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
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

        logic   [31:0]      mem_addr;
        logic   [3:0]       mem_rmask;
        logic   [3:0]       mem_wmask;
        logic   [31:0]      mem_wdata;
    } ex_mem_stage_reg_t;
    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
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


        logic   [31:0]      mem_addr;
        logic   [3:0]       mem_rmask;
        logic   [3:0]       mem_wmask;
        logic   [31:0]      mem_wdata;
    } mem_wb_stage_reg_t;

endpackage