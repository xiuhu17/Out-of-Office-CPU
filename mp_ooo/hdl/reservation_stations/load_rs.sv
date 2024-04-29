module load_rs
  import rv32i_types::*;
#(
    parameter LOAD_RS_DEPTH = 3,
    parameter STORE_RS_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 4,
    parameter STORE_RS_NUM_ELEM = 2 ** STORE_RS_DEPTH,
    parameter LOAD_RS_NUM_ELEM = 2 ** LOAD_RS_DEPTH,
    parameter STORE_RS_NUM_ELEM_1 = STORE_RS_NUM_ELEM + 1
) (
    input logic clk,
    input logic rst,
    input logic move_flush,

    // output full
    output logic load_rs_full,

    // control signal
    input logic load_rs_issue,

    // update the total number
    input logic store_rs_pop,

    // output to fsm
    output logic dmem_r_rqst,
    output logic [LOAD_RS_DEPTH-1:0] load_rs_idx_rqst,

    // fsm control pop
    input logic load_rs_pop,
    input logic [LOAD_RS_DEPTH-1:0] load_rs_idx_executing,

    // from dmem
    input logic [31:0] dmem_rdata,

    // issue input data
    input logic [               2:0] issue_funct3,
    input logic [              31:0] issue_imm,
    input logic [     ROB_DEPTH-1:0] issue_target_rob,
    input logic [   ROB_DEPTH - 1:0] issue_rs1_regfile_rob,
    input logic                      issue_rs1_regfile_ready,
    input logic [              31:0] issue_rs1_regfile_v,
    input logic                      issue_rs1_rob_ready,
    input logic [              31:0] issue_rs1_rob_v,
    // we store the tail, count when we are issuing the load 
    // input logic [STORE_RS_DEPTH-1:0] issue_store_rs_head,
    input logic [  STORE_RS_DEPTH:0] issue_store_rs_count,

    // snoop from cdb
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // read from store_queue
    // input logic forward_wready[STORE_RS_NUM_ELEM],
    // input logic [31:0] forward_waddr[STORE_RS_NUM_ELEM],

    // to cdb
    output logic cdb_load_rs_valid,
    output logic [31:0] cdb_load_rs_v,
    output logic [ROB_DEPTH-1:0] cdb_load_rs_rob,
    output logic [3:0] cdb_load_rs_rmask,
    output logic [31:0] cdb_load_rs_addr,
    output logic [31:0] cdb_load_rs_rdata,

    // to arbiter
    output logic [ 3:0] arbiter_load_rs_rmask,
    output logic [31:0] arbiter_load_rs_addr
);

  // valid, ready, status
  logic load_rs_available[LOAD_RS_NUM_ELEM];
  logic rs1_ready_arr[LOAD_RS_NUM_ELEM];
  logic could_load_arr[LOAD_RS_NUM_ELEM];

  //
  logic [2:0] funct3_arr[LOAD_RS_NUM_ELEM];
  logic [31:0] imm_arr[LOAD_RS_NUM_ELEM];
  // logic [STORE_RS_DEPTH-1:0] store_rs_head_arr[LOAD_RS_NUM_ELEM];
  logic [STORE_RS_DEPTH:0] store_rs_count_arr[LOAD_RS_NUM_ELEM];

  //
  logic [31:0] rs1_v_arr[LOAD_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs1_rob_arr[LOAD_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] target_rob_arr[LOAD_RS_NUM_ELEM];

  //
  logic [LOAD_RS_DEPTH-1:0] counter;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      counter <= '0;
      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        load_rs_available[i] <= '1;
        funct3_arr[i] <= '0;
        imm_arr[i] <= '0;
        // store_rs_head_arr[i] <= '0;
        store_rs_count_arr[i] <= '0;
        could_load_arr[i] <= '0;
        rs1_ready_arr[i] <= '0;
        rs1_v_arr[i] <= '0;
        rs1_rob_arr[i] <= '0;
        target_rob_arr[i] <= '0;
      end
    end else begin
      if (load_rs_issue) begin
        for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
          if (load_rs_available[i]) begin
            load_rs_available[i] <= '0;
            funct3_arr[i] <= issue_funct3;
            imm_arr[i] <= issue_imm;
            // store_rs_head_arr[i] <= issue_store_rs_head;
            store_rs_count_arr[i] <= issue_store_rs_count;
            could_load_arr[i] <= '0;
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
            if (store_rs_pop && issue_store_rs_count != '0) begin
              store_rs_count_arr[i] <= issue_store_rs_count - 1'b1;
            end
            break;
          end
        end
      end

      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        if (!load_rs_available[i]) begin
          for (int unsigned j = 0; j < CDB_SIZE; j++) begin
            if (cdb_valid[j] && (rs1_ready_arr[i] == '0) && (rs1_rob_arr[i] == cdb_rob[j])) begin
              rs1_ready_arr[i] <= '1;
              rs1_v_arr[i] <= cdb_rd_v[j];
            end
          end
          // update count
          if (store_rs_pop && store_rs_count_arr[i] != '0) begin
            store_rs_count_arr[i] <= store_rs_count_arr[i] - 1'b1;
          end
          // when could load
          if (!could_load_arr[i]) begin
            if (rs1_ready_arr[i]) begin
              // for (int unsigned j = 0; j < STORE_RS_NUM_ELEM_1; j++) begin
              //   if (store_rs_count_arr[i] == (STORE_RS_DEPTH + 1)'(j)) begin
              //     could_load_arr[i] <= '1;
              //     break;
              //   end
              //   if (forward_wready[(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j))] == '0) begin
              //     break;
              //   end
              //   if ((forward_waddr[(store_rs_head_arr[i] - (STORE_RS_DEPTH)'(j))] & 32'hfffffffc) == ((rs1_v_arr[i] + imm_arr[i]) & 32'hfffffffc)) begin
              //     break;
              //   end
              // end
              if (store_rs_count_arr[i] == '0) begin
                could_load_arr[i] <= '1;
              end 
            end
          end
        end
      end

      if (load_rs_pop) begin
        load_rs_available[load_rs_idx_executing] <= '1;
        rs1_ready_arr[load_rs_idx_executing] <= '0;
        could_load_arr[load_rs_idx_executing] <= '0;
        counter <= load_rs_idx_executing + 1'b1;
      end
    end
  end

  // output whether load_rs is full or not
  always_comb begin
    load_rs_full = '1;
    for (int i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
      if (load_rs_available[i]) begin
        load_rs_full = '0;
        break;
      end
    end
  end

  // fsm and arbiter
  always_comb begin
    dmem_r_rqst = '0;
    load_rs_idx_rqst = '0;
    arbiter_load_rs_rmask = '0;
    arbiter_load_rs_addr = '0;
    for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
      if (!load_rs_available[(LOAD_RS_DEPTH)'(i+counter)]) begin
        if (could_load_arr[(LOAD_RS_DEPTH)'(i+counter)]) begin
          dmem_r_rqst = '1;
          load_rs_idx_rqst = (LOAD_RS_DEPTH)'(i + counter);
          arbiter_load_rs_addr = rs1_v_arr[(LOAD_RS_DEPTH)'(i+counter)] + imm_arr[(LOAD_RS_DEPTH)'(i+counter)];
          case (funct3_arr[(LOAD_RS_DEPTH)'(i+counter)])
            lb_mem, lbu_mem: begin
              arbiter_load_rs_rmask = 4'b0001 << (arbiter_load_rs_addr[1:0]);
            end
            lh_mem, lhu_mem: begin
              arbiter_load_rs_rmask = 4'b0011 << (arbiter_load_rs_addr[1:0]);
            end
            lw_mem: begin
              arbiter_load_rs_rmask = 4'b1111;
            end
          endcase
          if (rs1_v_arr[(LOAD_RS_DEPTH)'(i+counter)] == 32'h0 && imm_arr[(LOAD_RS_DEPTH)'(i+counter)] == 32'h4) begin
              dmem_r_rqst = '0;
          end
          break;
        end
      end
    end
  end

  // to cdb
  always_comb begin
    cdb_load_rs_valid = '0;
    cdb_load_rs_v = '0;
    cdb_load_rs_rob = '0;
    cdb_load_rs_rmask = '0;
    cdb_load_rs_addr = '0;
    cdb_load_rs_rdata = '0;
    if (load_rs_pop) begin
      cdb_load_rs_valid = '1;
      cdb_load_rs_rob   = target_rob_arr[load_rs_idx_executing];
      cdb_load_rs_addr  = rs1_v_arr[load_rs_idx_executing] + imm_arr[load_rs_idx_executing];
      cdb_load_rs_rdata = dmem_rdata;
      case (funct3_arr[load_rs_idx_executing])
        lb_mem: begin
          cdb_load_rs_rmask = 4'b0001 << (cdb_load_rs_addr[1:0]);
          cdb_load_rs_v = {
            {24{dmem_rdata[7+8*cdb_load_rs_addr[1:0]]}}, dmem_rdata[8*cdb_load_rs_addr[1:0]+:8]
          };
        end
        lbu_mem: begin
          cdb_load_rs_rmask = 4'b0001 << (cdb_load_rs_addr[1:0]);
          cdb_load_rs_v     = {{24{1'b0}}, dmem_rdata[8*cdb_load_rs_addr[1:0]+:8]};
        end
        lh_mem: begin
          cdb_load_rs_rmask = 4'b0011 << (cdb_load_rs_addr[1:0]);
          cdb_load_rs_v = {
            {16{dmem_rdata[15+16*cdb_load_rs_addr[1]]}}, dmem_rdata[16*cdb_load_rs_addr[1]+:16]
          };
        end
        lhu_mem: begin
          cdb_load_rs_rmask = 4'b0011 << (cdb_load_rs_addr[1:0]);
          cdb_load_rs_v     = {{16{1'b0}}, dmem_rdata[16*cdb_load_rs_addr[1]+:16]};
        end
        lw_mem: begin
          cdb_load_rs_rmask = 4'b1111;
          cdb_load_rs_v = dmem_rdata;
        end
      endcase
    end
  end
endmodule
