module load_rs_naive
  import rv32i_types::*;
#(
    parameter LOAD_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    output logic load_rs_full,

    // assigned issue
    input logic load_rs_issue,

    // instructions issued from instruction_queue
    input logic [ 6:0] issue_opcode,
    input logic [ 2:0] issue_funct3,
    input logic [31:0] issue_imm,

    // assigned rob
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    // 3 sources for rs1, rs2: CDB, regfile, and ROB
    // from regfile(with scoreboard)
    input logic                   issue_rs1_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    // from ROB
    input logic [           31:0] issue_rs1_rob_v,
    input logic                   issue_rs1_rob_ready,

    // read from CDB for waking up; pop from load_rs if match
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // memory ports
    output logic [31:0] dmem_addr,
    output logic [3:0] dmem_rmask,
    input logic [31:0] dmem_rdata,
    input logic dmem_resp,

    // output result to CDB
    output logic cdb_load_rs_valid,
    output logic [31:0] cdb_load_rs_v,
    output logic [ROB_DEPTH-1:0] cdb_load_rs_rob,

    // overwrite rvfi_mem ports
    output logic [31:0] rvfi_load_mem_addr,
    output logic [ 3:0] rvfi_load_mem_rmask,
    output logic [31:0] rvfi_load_mem_rdata
);

  // number of elements in the LOAD_RS
  localparam LOAD_RS_NUM_ELEM = 2 ** LOAD_RS_DEPTH;

  // internal registers
  logic                     load_rs_available     [LOAD_RS_NUM_ELEM];

  // instruction information
  logic [              6:0] opcode_arr            [LOAD_RS_NUM_ELEM];
  logic [              2:0] funct3_arr            [LOAD_RS_NUM_ELEM];
  logic [             31:0] imm_arr               [LOAD_RS_NUM_ELEM];

  // rs1_ready determine if the value will be from ROB
  logic                     rs1_ready_arr         [LOAD_RS_NUM_ELEM];
  logic [             31:0] rs1_v_arr             [LOAD_RS_NUM_ELEM];
  logic [    ROB_DEPTH-1:0] rs1_rob_arr           [LOAD_RS_NUM_ELEM];

  // target ROB for the result
  logic [    ROB_DEPTH-1:0] target_rob_arr        [LOAD_RS_NUM_ELEM];

  // counter for traversing stations
  logic [LOAD_RS_DEPTH-1:0] counter;

  // pop signal
  logic                     load_start;
  logic                     load_rs_pop;
  logic                     load_executing;
  logic [LOAD_RS_DEPTH-1:0] load_rs_idx_executing;
  logic [    ROB_DEPTH-1:0] load_rob_executing;

  // load operands
  logic [             31:0] load_rs1_executing;
  logic [             31:0] load_imm_executing;
  logic [              2:0] load_funct3_executing;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      counter <= '0;
      for (int i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        load_rs_available[i] <= '1;
        opcode_arr[i] <= '0;
        funct3_arr[i] <= '0;
        imm_arr[i] <= '0;
        rs1_ready_arr[i] <= '0;
        rs1_v_arr[i] <= '0;
        rs1_rob_arr[i] <= '0;
        target_rob_arr[i] <= '0;
      end
    end else begin
      // issue logic
      if (load_rs_issue) begin
        for (int i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
          if (load_rs_available[i]) begin
            load_rs_available[i] <= '0;
            opcode_arr[i] <= issue_opcode;
            funct3_arr[i] <= issue_funct3;
            imm_arr[i] <= issue_imm;
            rs1_ready_arr[i] <= '0;
            rs1_v_arr[i] <= '0;
            rs1_rob_arr[i] <= issue_rs1_regfile_rob;
            target_rob_arr[i] <= issue_target_rob;
            if (issue_rs1_regfile_ready) begin
              rs1_ready_arr[i] <= '1;
              rs1_v_arr[i] <= issue_rs1_regfile_v;
            end else if (issue_rs1_rob_ready) begin
              rs1_ready_arr[i] <= '1;
              rs1_v_arr[i] <= issue_rs1_rob_v;
            end else begin
              rs1_ready_arr[i] <= '0;
            end
            break;
          end
        end
      end

      // snoop CDB to update any rs1/rs2 values
      for (int i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        if (!load_rs_available[i]) begin
          for (int j = 0; j < CDB_SIZE; j++) begin
            if (cdb_valid[j] && rs1_ready_arr[i] == 0 && (cdb_rob[j] == rs1_rob_arr[i])) begin
              rs1_v_arr[i] <= cdb_rd_v[j];
              rs1_ready_arr[i] <= '1;
            end
          end
        end
      end

      // remove once the result is computed and put on the CDB
      if (load_rs_pop) begin
        load_rs_available[load_rs_idx_executing] <= '1;
        rs1_ready_arr[load_rs_idx_executing] <= '0;
        counter <= load_rs_idx_executing + 1'b1;
      end
    end
  end

  // output whether LOAD_RS is full or not
  always_comb begin
    load_rs_full = '1;
    for (int i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
      if (load_rs_available[i]) begin
        load_rs_full = '0;
        break;
      end
    end
  end

  // store the stage of the load instruction
  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      load_executing <= '0;
      load_start <= '0;
      load_rs_idx_executing <= '0;
      load_rob_executing <= '0;
      load_rs1_executing <= '0;
      load_imm_executing <= '0;
      load_funct3_executing <= '0;
    end else begin
      if (!load_executing) begin
        for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
          if (!load_rs_available[(LOAD_RS_DEPTH)'(i+counter)] && rs1_ready_arr[(LOAD_RS_DEPTH)'(i+counter)]) begin
            load_executing <= '1;
            load_start <= '1;
            load_rs_idx_executing <= (LOAD_RS_DEPTH)'(i + counter);
            load_rob_executing <= target_rob_arr[(LOAD_RS_DEPTH)'(i+counter)];
            load_rs1_executing <= rs1_v_arr[(LOAD_RS_DEPTH)'(i+counter)];
            load_imm_executing <= imm_arr[(LOAD_RS_DEPTH)'(i+counter)];
            load_funct3_executing <= funct3_arr[(LOAD_RS_DEPTH)'(i+counter)];
            break;
          end
        end
      end
      if (load_start) begin
        load_start <= '0;
      end
      if (dmem_resp) begin
        load_executing <= '0;
      end
    end
  end

  // rdata
  logic [7:0] byte_3, byte_2, byte_1, byte_0;
  logic [15:0] half_1, half_0;
  always_comb begin
    byte_3 = dmem_rdata[24+:8];
    byte_2 = dmem_rdata[16+:8];
    byte_1 = dmem_rdata[8+:8];
    byte_0 = dmem_rdata[0+:8];
    half_1 = dmem_rdata[16+:16];
    half_0 = dmem_rdata[0+:16];
  end

  // for selecting reservation waking up
  always_comb begin
    cdb_load_rs_valid = '0;
    load_rs_pop = '0;
    cdb_load_rs_rob = '0;
    cdb_load_rs_v = '0;
    if (dmem_resp && load_executing) begin
      load_rs_pop = '1;
      cdb_load_rs_valid = '1;
      cdb_load_rs_rob = load_rob_executing;
      case (load_funct3_executing)
        lb_mem: begin
          case (rvfi_load_mem_rmask)
            4'b1000: cdb_load_rs_v = {{24{byte_3[7]}}, byte_3};
            4'b0100: cdb_load_rs_v = {{24{byte_2[7]}}, byte_2};
            4'b0010: cdb_load_rs_v = {{24{byte_1[7]}}, byte_1};
            4'b0001: cdb_load_rs_v = {{24{byte_0[7]}}, byte_0};
          endcase
        end
        lbu_mem: begin
          case (rvfi_load_mem_rmask)
            4'b1000: cdb_load_rs_v = {{24{1'b0}}, byte_3};
            4'b0100: cdb_load_rs_v = {{24{1'b0}}, byte_2};
            4'b0010: cdb_load_rs_v = {{24{1'b0}}, byte_1};
            4'b0001: cdb_load_rs_v = {{24{1'b0}}, byte_0};
            default: ;
          endcase
        end
        lh_mem: begin
          case (rvfi_load_mem_rmask)
            4'b1100: cdb_load_rs_v = {{16{half_1[15]}}, half_1};
            4'b0011: cdb_load_rs_v = {{16{half_0[15]}}, half_0};
            default: ;
          endcase
        end
        lhu_mem: begin
          case (rvfi_load_mem_rmask)
            4'b1100: cdb_load_rs_v = {{16{1'b0}}, half_1};
            4'b0011: cdb_load_rs_v = {{16{1'b0}}, half_0};
            default: ;
          endcase
        end
        lw_mem:  cdb_load_rs_v = dmem_rdata;
        default: cdb_load_rs_v = 'x;
      endcase
    end
  end

  // for connecting to memory ports
  always_comb begin
    rvfi_load_mem_addr = load_rs1_executing + load_imm_executing;
    case (load_funct3_executing)
      lb_mem, lbu_mem: dmem_rmask = 4'b0001 << (rvfi_load_mem_addr[1:0]);
      lh_mem, lhu_mem: dmem_rmask = 4'b0011 << (rvfi_load_mem_addr[1:0]);
      lw_mem: dmem_rmask = 4'b1111;
      default: dmem_rmask = 'x;
    endcase
    rvfi_load_mem_rmask = dmem_rmask;
    rvfi_load_mem_rdata = dmem_rdata;
    dmem_addr = rvfi_load_mem_addr & 32'hfffffffc;
    dmem_rmask = dmem_rmask & {4{load_start}};  // mask rmask after first request
  end

endmodule
