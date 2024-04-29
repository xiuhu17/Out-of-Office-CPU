/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////

package rv32i_types;

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
    add_funct3  = 3'b000,  //check bit 30 for sub if op_reg opcode
    sll_funct3  = 3'b001,
    slt_funct3  = 3'b010,
    sltu_funct3 = 3'b011,
    axor_funct3 = 3'b100,
    sr_funct3   = 3'b101,  //check bit 30 for logical/arithmetic
    aor_funt3   = 3'b110,
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
    variant_funct7 = 7'b0100000,
    multiply_funct7 = 7'b0000001
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

  typedef enum bit [2:0] {
    mul_funct3 = 3'b000,
    mulh_funct3 = 3'b001,
    mulhsu_funct3 = 3'b010,
    mulhu_funct3 = 3'b011,
    div_funct3 = 3'b100,
    udiv_funct3 = 3'b101,
    rem_funct3 = 3'b110,
    urem_funct3 = 3'b111
  } mul_funct3_t;

  typedef enum bit [1:0] {
    mul_unsigned_unsigned = 2'b00,
    mul_signed_signed = 2'b01,
    mul_signed_unsigned = 2'b10
  } mul_type_t;
  
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

  typedef struct packed {
    logic [31:0] pc;
    logic [31:0] pc_next;
    logic [63:0] order;
    logic        valid;

    logic [31:0] inst;
    logic [4:0]  rs1_s;
    logic [4:0]  rs2_s;
    logic [31:0] rs1_v;
    logic [31:0] rs2_v;
    logic [4:0]  rd_s;
    logic [31:0] rd_d;

    logic [31:0] mem_addr;
    logic [3:0]  mem_rmask;
    logic [3:0]  mem_wmask;
    logic [31:0] mem_wdata;
    logic [31:0] mem_rdata;
  } rvfi_t;
endpackage

package cache_types;

  typedef enum bit [1:0] {
    Hit_Read_Clean = 2'b00,  // valid, clean
    Hit_Write_Dirty = 2'b01,  // valid, dirty
    Miss_Replace = 2'b10  // valid, clean
  } Sram_op_t;

  typedef enum bit [1:0] {
    Way_A = 2'b11,
    Way_B = 2'b10,
    Way_C = 2'b01,
    Way_D = 2'b00
  } PLRU_Way_t;

  typedef enum bit [3:0] {
    Way_A_4 = 4'b1000,
    Way_B_4 = 4'b0100,
    Way_C_4 = 4'b0010,
    Way_D_4 = 4'b0001
  } PLRU_Way_4_t;

  typedef enum bit [1:0] {
    Hit = 2'b11,
    Dirty_Miss = 2'b10,
    Clean_Miss = 2'b01
  } Hit_Miss_t;

endpackage
