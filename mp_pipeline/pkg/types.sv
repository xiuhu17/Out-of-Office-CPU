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
        op_lui   = 7'b0110111, // load upper immediate (U type)
        op_auipc = 7'b0010111, // add upper immediate PC (U type)
        op_jal   = 7'b1101111, // jump and link (J type)
        op_jalr  = 7'b1100111, // jump and link register (I type)
        op_br    = 7'b1100011, // branch (B type)
        op_load  = 7'b0000011, // load (I type)
        op_store = 7'b0100011, // store (S type)
        op_imm   = 7'b0010011, // arith ops with register/immediate operands (I type)
        op_reg   = 7'b0110011  // arith ops with register operands (R type)
        op_csr   = 7'b1110011  // I control and status register 
    } rv32i_opcode;

    typedef enum bit [2:0] {
        add  = 3'b000, //check bit 30 for sub if op_reg opcode
        sll  = 3'b001,
        slt  = 3'b010,
        sltu = 3'b011,
        axor = 3'b100,
        sr   = 3'b101, //check bit 30 for logical/arithmetic
        aor  = 3'b110,
        aand = 3'b111
    } arith_funct3_t;

    typedef enum bit [2:0] {
        alu_add = 3'b000,
        alu_sll = 3'b001,
        alu_sra = 3'b010,
        alu_sub = 3'b011,
        alu_xor = 3'b100,
        alu_srl = 3'b101,
        alu_or  = 3'b110,
        alu_and = 3'b111
    } alu_ops_t;
    typedef enum bit [2:0] {
        beq  = 3'b000,
        bne  = 3'b001,
        blt  = 3'b100,
        bge  = 3'b101,
        bltu = 3'b110,
        bgeu = 3'b111
    } cmp_ops_t;


    //////////////////////////////////////////
    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic   [2:0]       funct3;
        logic   [6:0]       funct7;
        logic   [6:0]       opcode;
        logic   [31:0]      i_imm;
        logic   [31:0]      s_imm;
        logic   [31:0]      b_imm;
        logic   [31:0]      u_imm;
        logic   [31:0]      j_imm;
        logic   [4:0]       rs1_s;
        logic   [4:0]       rs2_s;
        logic   [4:0]       rd_s;
    } if_id_stage_reg_t;


    typedef enum bit {
        rs1_value_alu = 1'b0,
        pc_out_alu = 1'b1
    } alu_m1_sel_t;
    typedef enum bit [2:0] {
        i_imm_alu    = 3'b000, 
        u_imm_alu   = 3'b001, 
        b_imm_alu   = 3'b010,
        s_imm_alu   = 3'b011,
        j_imm_alu   = 3'b100,
        rs2_value_alu = 3'b101
    } alu_m2_sel_t;
    typedef enum bit {
        rs2_value_cmp = 1'b0,
        i_imm_cmp = 1'b1
    } cmp_m_sel_t;
    typedef enum bit [2:0] {
        lb  = 3'b000,
        lh  = 3'b001,
        lw  = 3'b010,
        lbu = 3'b100,
        lhu = 3'b101
    } load_ops_t;
    typedef enum bit [2:0] {
        sb = 3'b000,
        sh = 3'b001,
        sw = 3'b010
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

    typedef struct packed {
        // signal for alu
        alu_m1_sel_t        alu_m1_sel;
        alu_m2_sel_t        alu_m2_sel;
        alu_ops_t           alu_ops;
        // signal for cmp
        // default is rs1_v
        cmp_m_sel_t         cmp_m_sel;
        cmp_ops_t           cmp_ops;
    }ex_signal_t;

    typedef struct packed {
        logic               MemRead;
        logic               MemWrite;
        load_ops_t          load_ops;
        store_ops_t         store_ops;
    }mem_signal_t;

    typedef struct packed {
        regf_m_sel_t        regf_m_sel;
        logic               regf_we;
    }wb_signal_t;

    typedef struct packed {
        logic   [31:0]      inst;
        logic   [31:0]      pc;
        logic   [63:0]      order;
        logic               is_stall;

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

endpackage