/////////////////////////////////////////////////////////////
//  Maybe use some of your types from mp_pipeline here?    //
//    Note you may not need to use your stage structs      //
/////////////////////////////////////////////////////////////

package rv32i_types;
  int ROB_DEPTH = 4;
  int ALU_SIZE = 4;

  typedef enum logic [6:0] {
    op_b_lui   = 7'b0110111, // U load upper immediate
    op_b_auipc = 7'b0010111, // U add upper immediate PC
    op_b_jal   = 7'b1101111, // J jump and link
    op_b_jalr  = 7'b1100111, // I jump and link register
    op_b_br    = 7'b1100011, // B branch
    op_b_load  = 7'b0000011, // I load
    op_b_store = 7'b0100011, // S store
    op_b_imm   = 7'b0010011, // I arith ops with register/immediate operands
    op_b_reg   = 7'b0110011 // R arith ops with register operands
  } rv32i_op_b_t;

  typedef enum bit [6:0] {
    base = 7'b0000000,
    variant = 7'b0100000,
    multiply = 7'b0000001
  } funct7_t;

  typedef enum bit [1:0] {
    mul_unsigned_unsigned = 2'b00,
    mul_signed_signed = 2'b01,
    mul_signed_unsigned = 2'b10
  } mul_type_t;

  typedef enum bit [2:0] {
    mul = 3'b000,
    mulh = 3'b001,
    mulhsu = 3'b010,
    mulhu = 3'b011
  } mul_funct3_t;

  // Add more things here . . .

  // issue an instruction
  // if the cdb can give the value in the same cycle
  typedef enum logic [1:0] {
    reg_file = 2'b00,
    rob_file = 2'b01,
    cdb = 2'b10
  } issue_read_t;

  // // for commit purpose
  // typedef struct packed {
  //   logic                   commit_regf_we;
  //   logic [4:0]             commit_rd_s;
  //   logic [31:0]            commit_rd_v;
  //   logic [ROB_DEPTH - 1:0] commit_rob;
  // } rob_to_regfile_t;

  // typedef struct packed {
  //   // write to scoreboard
  //   logic                   issue_valid;
  //   logic [4:0]             issue_rd_s;
  //   logic [ROB_DEPTH - 1:0] issue_rob;
  //   // read from regfile
  //   logic [4:0]             issue_rs_1;
  //   logic [4:0]             issue_rs_2;
  // } iq_to_regfile_t;

  // typedef struct packed {
  //   logic [31:0]            issue_rs1_regfile_v;
  //   logic [31:0]            issue_rs2_regfile_v;
  //   logic                   issue_rs1_regfile_ready;
  //   logic                   issue_rs2_regfile_ready;
  //   logic [ROB_DEPTH - 1:0] issue_rs1_rob;
  //   logic [ROB_DEPTH - 1:0] issue_rs2_rob;
  // } regfile_to_iq_t;


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

  // typedef struct packed {
  //   logic                 cdb_valid;
  //   logic [ROB_DEPTH-1:0] cdb_rob;
  //   logic [31:0]          cdb_rd_v;
  // } cdb_t;

  typedef enum bit [3:0] {
    alu_add  = 4'b0000,
    alu_sub  = 4'b0001,
    alu_sll  = 4'b0010,
    alu_slt  = 4'b0011,
    alu_sltu = 4'b0100,
    alu_xor  = 4'b0101,
    alu_srl  = 4'b0110,
    alu_sra  = 4'b0111,
    alu_or   = 4'b1100,
    alu_and  = 4'b1101,
    alu_lui  = 4'b1110,
    alu_jalr = 4'b1111
  } alu_ops_t;

endpackage
