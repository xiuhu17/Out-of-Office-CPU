module store_rs_naive
  import rv32i_types::*;
#(
    parameter STORE_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 3
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    output logic store_rs_full,

    // assigned issue
    input logic store_rs_issue,

    // instructions issued from instruction_queue
    input logic [ 6:0] issue_opcode,
    input logic [ 2:0] issue_funct3,
    input logic [31:0] issue_imm,

    // assigned rob
    input logic [ROB_DEPTH-1:0] issue_target_rob,

    // 3 sources for rs1, rs2: CDB, regfile, and ROB
    // from regfile(with scoreboard)
    input logic                   issue_rs1_regfile_ready,
    input logic                   issue_rs2_regfile_ready,
    input logic [           31:0] issue_rs1_regfile_v,
    input logic [           31:0] issue_rs2_regfile_v,
    input logic [ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic [ROB_DEPTH - 1:0] issue_rs2_regfile_rob,
    // from ROB
    input logic [           31:0] issue_rs1_rob_v,
    input logic [           31:0] issue_rs2_rob_v,
    input logic                   issue_rs1_rob_ready,
    input logic                   issue_rs2_rob_ready,

    // snoop from CDB
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // output result to CDB
    output logic cdb_store_rs_valid,
    output logic [31:0] cdb_store_rs_v,
    output logic [ROB_DEPTH-1:0] cdb_store_rs_rob,

    // overwrite rvfi_mem ports
    output logic [31:0] rvfi_store_mem_addr,
    output logic [ 3:0] rvfi_store_mem_wmask,
    output logic [31:0] rvfi_store_mem_wdata
);

  // number of elements in the STORE_RS
  localparam STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH;

  // internal registers
  logic                      store_rs_available [STORE_RS_NUM_ELEM];

  // instruction information
  logic [               6:0] opcode_arr         [STORE_RS_NUM_ELEM];
  logic [               2:0] funct3_arr         [STORE_RS_NUM_ELEM];
  logic [              31:0] imm_arr            [STORE_RS_NUM_ELEM];

  // rs1_ready determine if the value will be from ROB
  logic                      rs1_ready_arr      [STORE_RS_NUM_ELEM];
  logic                      rs2_ready_arr      [STORE_RS_NUM_ELEM];
  logic [              31:0] rs1_v_arr          [STORE_RS_NUM_ELEM];
  logic [              31:0] rs2_v_arr          [STORE_RS_NUM_ELEM];
  logic [     ROB_DEPTH-1:0] rs1_rob_arr        [STORE_RS_NUM_ELEM];
  logic [     ROB_DEPTH-1:0] rs2_rob_arr        [STORE_RS_NUM_ELEM];

  // target ROB for the result
  logic [     ROB_DEPTH-1:0] target_rob_arr     [STORE_RS_NUM_ELEM];

  // pop logic
  logic                      store_rs_pop;
  logic [STORE_RS_DEPTH-1:0] store_rs_pop_index;

  // counter for traversing stations
  logic [STORE_RS_DEPTH-1:0] counter;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      counter <= '0;
      for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin
        store_rs_available[i] <= '1;
        opcode_arr[i] <= '0;
        funct3_arr[i] <= '0;
        imm_arr[i] <= '0;
        rs1_ready_arr[i] <= '0;
        rs2_ready_arr[i] <= '0;
        rs1_v_arr[i] <= '0;
        rs2_v_arr[i] <= '0;
        rs1_rob_arr[i] <= '0;
        rs2_rob_arr[i] <= '0;
        target_rob_arr[i] <= '0;
      end
    end else begin
      // issue logic
      if (store_rs_issue) begin
        for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin
          if (store_rs_available[i]) begin
            store_rs_available[i] <= '0;
            opcode_arr[i] <= issue_opcode;
            funct3_arr[i] <= issue_funct3;
            imm_arr[i] <= issue_imm;
            rs1_ready_arr[i] <= '0;
            rs2_ready_arr[i] <= '0;
            rs1_v_arr[i] <= '0;
            rs2_v_arr[i] <= '0;
            rs1_rob_arr[i] <= issue_rs1_regfile_rob;
            rs2_rob_arr[i] <= issue_rs2_regfile_rob;
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
            if (issue_rs2_regfile_ready) begin
              rs2_ready_arr[i] <= '1;
              rs2_v_arr[i] <= issue_rs2_regfile_v;
            end else if (issue_rs2_rob_ready) begin
              rs2_ready_arr[i] <= '1;
              rs2_v_arr[i] <= issue_rs2_rob_v;
            end else begin
              rs2_ready_arr[i] <= '0;
            end
            break;
          end
        end
      end

      // snoop CDB to update any rs1/rs2 values
      for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin
        if (!store_rs_available[i]) begin
          for (int j = 0; j < CDB_SIZE; j++) begin
            if (cdb_valid[j] && rs1_ready_arr[i] == 0 && (cdb_rob[j] == rs1_rob_arr[i])) begin
              rs1_v_arr[i] <= cdb_rd_v[j];
              rs1_ready_arr[i] <= '1;
            end
            if (cdb_valid[j] && rs2_ready_arr[i] == 0 && (cdb_rob[j] == rs2_rob_arr[i])) begin
              rs2_v_arr[i] <= cdb_rd_v[j];
              rs2_ready_arr[i] <= '1;
            end
          end
        end
      end

      // remove once the result is computed and put on the CDB
      if (store_rs_pop) begin
        store_rs_available[store_rs_pop_index] <= '1;
        rs1_ready_arr[store_rs_pop_index] <= '0;
        rs2_ready_arr[store_rs_pop_index] <= '0;
        counter <= store_rs_pop_index + 1'b1;
      end
    end
  end

  // output whether STORE_RS is full or not
  always_comb begin
    store_rs_full = '1;
    for (int i = 0; i < STORE_RS_NUM_ELEM; i++) begin
      if (store_rs_available[i]) begin
        store_rs_full = '0;
        break;
      end
    end
  end

  always_comb begin
    store_rs_pop = '0;
    store_rs_pop_index = '0;
    cdb_store_rs_rob = '0;
    cdb_store_rs_valid = '0;
    cdb_store_rs_v = '0;
    rvfi_store_mem_addr = '0;
    rvfi_store_mem_wmask = '0;
    rvfi_store_mem_wdata = '0;
    // execution logic
    for (int unsigned i = 0; i < STORE_RS_NUM_ELEM; i++) begin
      if (!store_rs_available[(STORE_RS_DEPTH)'(i+counter)] && rs1_ready_arr[(STORE_RS_DEPTH)'(i+counter)] && rs2_ready_arr[(STORE_RS_DEPTH)'(i+counter)]) begin
        store_rs_pop = '1;
        store_rs_pop_index = (STORE_RS_DEPTH)'(i + counter);
        cdb_store_rs_rob = target_rob_arr[(STORE_RS_DEPTH)'(i+counter)];
        cdb_store_rs_valid = '1;
        rvfi_store_mem_addr = rs1_v_arr[(STORE_RS_DEPTH)'(i+counter)] + imm_arr[(STORE_RS_DEPTH)'(i+counter)];
        case (funct3_arr[(STORE_RS_DEPTH)'(i+counter)])
          sb_mem: begin
            rvfi_store_mem_wmask = 4'b0001 << (rvfi_store_mem_addr[1:0]);
            case (rvfi_store_mem_wmask)
              4'b1000: rvfi_store_mem_wdata = {rs2_v_arr[(i+counter)&3'b111][7:0], 24'b0};
              4'b0100: rvfi_store_mem_wdata = {8'b0, rs2_v_arr[(i+counter)&3'b111][7:0], 16'b0};
              4'b0010: rvfi_store_mem_wdata = {16'b0, rs2_v_arr[(i+counter)&3'b111][7:0], 8'b0};
              4'b0001: rvfi_store_mem_wdata = {24'b0, rs2_v_arr[(i+counter)&3'b111][7:0]};
              default: ;
            endcase
          end
          sh_mem: begin
            rvfi_store_mem_wmask = 4'b0011 << (rvfi_store_mem_addr[1:0]);
            case (rvfi_store_mem_wmask)
              4'b1100: rvfi_store_mem_wdata = {rs2_v_arr[(i+counter)&3'b111][15:0], 16'b0};
              4'b0011: rvfi_store_mem_wdata = {16'b0, rs2_v_arr[(i+counter)&3'b111][15:0]};
              default: ;
            endcase
          end
          sw_mem: begin
            rvfi_store_mem_wmask = 4'b1111;
            rvfi_store_mem_wdata = rs2_v_arr[(i+counter)&3'b111];
          end
          default: begin
            rvfi_store_mem_wmask = 'x;
            rvfi_store_mem_wdata = 'x;
          end
        endcase
        break;
      end
    end
  end

  // // for selecting reservation waking up
  // always_comb begin
  //   cdb_store_rs_valid = '0;
  //   store_rs_pop = '0;
  //   cdb_store_rs_rob = '0;
  //   cdb_store_rs_f = '0;
  //   if (dmem_resp) begin
  //     cdb_store_rs_valid = '1;
  //     store_rs_pop = '1;
  //     cdb_store_rs_rob = store_rob_executing;
  //     cdb_store_rs_f = 'x;  // TODO: we can just delete this port since no data transfer is needed
  //   end
  // end


endmodule
