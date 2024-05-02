module load_rs
  import rv32i_types::*;
#(
    parameter LOAD_RS_DEPTH = 3,
    parameter STORE_RS_DEPTH = 3,
    parameter STORE_BUFFER_DEPTH = 3,
    parameter ROB_DEPTH = 3,
    parameter CDB_SIZE = 4,
    parameter STORE_BUFFER_NUM_ELEM = 2 ** STORE_BUFFER_DEPTH,
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
    output logic [LOAD_RS_DEPTH-1:0] load_rs_dmem_idx_rqst,

    // fsm control pop
    input logic load_rs_dmem_ready,
    input logic [LOAD_RS_DEPTH-1:0] load_rs_dmem_idx_executing,

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
    input logic [STORE_RS_DEPTH-1:0] issue_store_rs_head,
    input logic [  STORE_RS_DEPTH:0] issue_store_rs_count,

    // snoop from cdb
    input logic                 cdb_valid[CDB_SIZE],
    input logic [ROB_DEPTH-1:0] cdb_rob  [CDB_SIZE],
    input logic [         31:0] cdb_rd_v [CDB_SIZE],

    // forward from store_rs
    input logic store_rs_wready[STORE_RS_NUM_ELEM],
    input logic [31:0] store_rs_addr[STORE_RS_NUM_ELEM],
    input logic [3:0] store_rs_wmask[STORE_RS_NUM_ELEM],
    input logic [31:0] store_rs_wdata[STORE_RS_NUM_ELEM],
    // forward from store_buffer
    input logic store_buffer_valid[STORE_BUFFER_NUM_ELEM],
    input logic [31:0] store_buffer_addr[STORE_BUFFER_NUM_ELEM],
    input logic [3:0] store_buffer_wmask[STORE_BUFFER_NUM_ELEM],
    input logic [31:0] store_buffer_wdata[STORE_BUFFER_NUM_ELEM],

    // to cdb
    output logic cdb_load_rs_valid,
    output logic cdb_load_rs_rdata_valid,
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

  //
  logic [2:0] funct3_arr[LOAD_RS_NUM_ELEM];
  logic [31:0] imm_arr[LOAD_RS_NUM_ELEM];
  logic [STORE_RS_DEPTH-1:0] store_rs_head_arr[LOAD_RS_NUM_ELEM];
  logic [STORE_RS_DEPTH:0] store_rs_count_arr[LOAD_RS_NUM_ELEM];

  //
  logic [31:0] rs1_v_arr[LOAD_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] rs1_rob_arr[LOAD_RS_NUM_ELEM];
  logic [ROB_DEPTH-1:0] target_rob_arr[LOAD_RS_NUM_ELEM];

  // 
  logic load_rs_forward_ready;
  logic [LOAD_RS_DEPTH-1:0] load_rs_forward_idx_executing;

  // forwarding logic helper
  logic store_rs_solved[LOAD_RS_NUM_ELEM];
  logic store_rs_conflict[LOAD_RS_NUM_ELEM]; 
  logic store_rs_could_forward[LOAD_RS_NUM_ELEM];
  logic [STORE_RS_DEPTH-1:0]store_rs_conflict_idx[LOAD_RS_NUM_ELEM]; 
  logic store_buffer_conflict[LOAD_RS_NUM_ELEM]; 
  logic store_buffer_could_forward[LOAD_RS_NUM_ELEM];
  logic [STORE_BUFFER_DEPTH-1:0]store_buffer_conflict_idx[LOAD_RS_NUM_ELEM]; 
  logic [31:0] load_rs_addr[LOAD_RS_NUM_ELEM];
  logic [3:0] load_rs_rmask[LOAD_RS_NUM_ELEM];
  logic [3:0] forward_wmask;
  logic [31:0] forward_wdata;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        load_rs_available[i] <= '1;
        funct3_arr[i] <= '0;
        imm_arr[i] <= '0;
        store_rs_head_arr[i] <= '0;
        store_rs_count_arr[i] <= '0;
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
            store_rs_head_arr[i] <= issue_store_rs_head;
            store_rs_count_arr[i] <= issue_store_rs_count;
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
        end
      end

      if (load_rs_dmem_ready) begin
        load_rs_available[load_rs_dmem_idx_executing] <= '1;
        rs1_ready_arr[load_rs_dmem_idx_executing] <= '0;
      end else if (load_rs_forward_ready) begin
        if (forward_wmask == 4'b1111) begin
          load_rs_available[load_rs_forward_idx_executing] <= '1;
          rs1_ready_arr[load_rs_forward_idx_executing] <= '0;
        end
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

  // load: !available && ready
  // whether all solved
  // whether conflict(overlap)
  // if it is, where is the closet overlapped (wmask & rmask != '0)
  // closet overlapped in store_queue or store_buffer
  // whether the closet 1: available for forwarding, 2: overlapped wmask must contain all overlapped rmask (wmask | rmask == wmask)
  // determines whether forward or wait till sending request to dmem  
  always_comb begin
    dmem_r_rqst = '0;
    load_rs_dmem_idx_rqst = '0;
    arbiter_load_rs_addr = '0;
    arbiter_load_rs_rmask = '0;
    load_rs_forward_ready = '0;
    load_rs_forward_idx_executing = '0;
    forward_wmask = '0;
    forward_wdata = '0;

    // initialization
    for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i ++) begin
        store_rs_solved[i] = '0;
        store_rs_conflict[i] = '0;
        store_rs_could_forward[i] = '0;
        store_rs_conflict_idx[i] = '0;
        store_buffer_conflict[i] = '0;
        store_buffer_could_forward[i] = '0;
        store_buffer_conflict_idx[i] = '0;
        load_rs_addr[i] = rs1_v_arr[i] + imm_arr[i];
        load_rs_rmask[i] = '0;
        case (funct3_arr[i])
          lb_mem, lbu_mem: begin
            load_rs_rmask[i] = 4'b0001 << (load_rs_addr[i][1:0]);
          end
          lh_mem, lhu_mem: begin
            load_rs_rmask[i] = 4'b0011 << (load_rs_addr[i][1:0]);
          end
          lw_mem: begin
            load_rs_rmask[i] = 4'b1111;
          end
        endcase
    end

    // can not check when read from dmem is avaible
    if (!load_rs_dmem_ready) begin
      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i ++) begin
        if (!load_rs_available[i] && rs1_ready_arr[i]) begin
          for (int unsigned j = 0; j < STORE_RS_NUM_ELEM_1; j++) begin
            if (store_rs_count_arr[i] == (STORE_RS_DEPTH + 1)'(j)) begin
              store_rs_solved[i] = '1;
              break;
            end
            if (store_rs_wready[(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j))] == '0) begin
              break;
            end
          end
        end
      end

      // find closest conflict, and check whether could forward or not
      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i ++) begin
        if (!load_rs_available[i] && rs1_ready_arr[i] && store_rs_solved[i]) begin
            for (int unsigned j = 0; j < STORE_RS_NUM_ELEM_1; j++) begin
              if (store_rs_count_arr[i] == (STORE_RS_DEPTH + 1)'(j)) begin
                break;
              end
              if ((store_rs_addr[(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j))] >> 2) == (load_rs_addr[i] >> 2)) begin
                if ((store_rs_wmask[(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j))] & load_rs_rmask[i]) != '0) begin
                  store_rs_conflict[i] = '1;
                  store_rs_conflict_idx[i] = (STORE_RS_DEPTH)'(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j));
                  if ((store_rs_wmask[(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j))] | load_rs_rmask[i]) == store_rs_wmask[(store_rs_head_arr[i]-(STORE_RS_DEPTH)'(j))]) begin
                    store_rs_could_forward[i] = '1;
                  end
                  break;
                end
              end
            end
          for (int unsigned k = 0; k < STORE_BUFFER_NUM_ELEM; k ++) begin
            if (store_buffer_valid[k]) begin
              if ((store_buffer_addr[k] >> 2) == (load_rs_addr[i] >> 2)) begin
                if ((store_buffer_wmask[k] & load_rs_rmask[i]) != '0) begin
                  store_buffer_conflict[i] = '1;
                  store_buffer_conflict_idx[i] = (STORE_BUFFER_DEPTH)'(k);
                  if ((store_buffer_wmask[k] | load_rs_rmask[i]) == store_buffer_wmask[k]) begin
                    store_buffer_could_forward[i] = '1;
                  end
                  break;
                end
              end
            end
          end
        end
      end

      // for request to dcache, load_store_fsm, arbiter
      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        if (!load_rs_available[i] && rs1_ready_arr[i] && store_rs_solved[i]) begin
          if (store_rs_conflict[i] == '0 && store_buffer_conflict[i] == '0) begin
            if (load_rs_addr[i] != 32'h4) begin
              dmem_r_rqst = '1;
              load_rs_dmem_idx_rqst = (LOAD_RS_DEPTH)'(i);
              arbiter_load_rs_addr = load_rs_addr[i];
              arbiter_load_rs_rmask = load_rs_rmask[i];
              break;
            end
          end
        end
      end

      // for forwarding
      for (int unsigned i = 0; i < LOAD_RS_NUM_ELEM; i++) begin
        if (!load_rs_available[i] && rs1_ready_arr[i] && store_rs_solved[i]) begin
          if (store_rs_conflict[i]) begin
            if (store_rs_could_forward[i]) begin
              load_rs_forward_ready = '1;
              load_rs_forward_idx_executing = (LOAD_RS_DEPTH)'(i);
              forward_wmask = store_rs_wmask[store_rs_conflict_idx[i]];
              forward_wdata = store_rs_wdata[store_rs_conflict_idx[i]];
              break;
            end
          end else if (store_buffer_conflict[i]) begin
            if (store_buffer_could_forward[i]) begin
              load_rs_forward_ready = '1;
              load_rs_forward_idx_executing = (LOAD_RS_DEPTH)'(i);
              forward_wmask = store_buffer_wmask[store_buffer_conflict_idx[i]];
              forward_wdata = store_buffer_wdata[store_buffer_conflict_idx[i]];
              break;
            end
          end
        end
      end
    end   
  end

  // assign to cdb
  always_comb begin
    cdb_load_rs_valid = '0;
    cdb_load_rs_rdata_valid = '0;
    cdb_load_rs_v = '0;
    cdb_load_rs_rob = '0;
    cdb_load_rs_rmask = '0;
    cdb_load_rs_addr = '0;
    cdb_load_rs_rdata = '0;
    if (load_rs_dmem_ready) begin
      cdb_load_rs_valid = '1;
      cdb_load_rs_rob = target_rob_arr[load_rs_dmem_idx_executing];
      // valid in rob and could pop from load_rs
      cdb_load_rs_rdata_valid = '1;
      cdb_load_rs_rdata = dmem_rdata;
      cdb_load_rs_rmask = load_rs_rmask[load_rs_dmem_idx_executing];
      cdb_load_rs_addr = load_rs_addr[load_rs_dmem_idx_executing];
      case (funct3_arr[load_rs_dmem_idx_executing])
        lb_mem: begin
          cdb_load_rs_v = { {24{dmem_rdata[7+8*cdb_load_rs_addr[1:0]]}}, dmem_rdata[8*cdb_load_rs_addr[1:0]+:8] };
        end
        lbu_mem: begin
          cdb_load_rs_v = {{24{1'b0}}, dmem_rdata[8*cdb_load_rs_addr[1:0]+:8]};
        end
        lh_mem: begin
          cdb_load_rs_v = { {16{dmem_rdata[15+16*cdb_load_rs_addr[1]]}}, dmem_rdata[16*cdb_load_rs_addr[1]+:16] };
        end
        lhu_mem: begin
          cdb_load_rs_v = {{16{1'b0}}, dmem_rdata[16*cdb_load_rs_addr[1]+:16]};
        end
        lw_mem: begin
          cdb_load_rs_v = dmem_rdata;
        end
      endcase
    end else if (load_rs_forward_ready) begin
      cdb_load_rs_valid = '1;
      cdb_load_rs_rob = target_rob_arr[load_rs_forward_idx_executing];
      cdb_load_rs_rdata = forward_wdata;
      cdb_load_rs_rmask = load_rs_rmask[load_rs_forward_idx_executing];
      cdb_load_rs_addr = load_rs_addr[load_rs_forward_idx_executing];
      case (funct3_arr[load_rs_forward_idx_executing])
        lb_mem: begin
          cdb_load_rs_v = { {24{forward_wdata[7+8*cdb_load_rs_addr[1:0]]}}, forward_wdata[8*cdb_load_rs_addr[1:0]+:8] };
        end
        lbu_mem: begin
          cdb_load_rs_v = {{24{1'b0}}, forward_wdata[8*cdb_load_rs_addr[1:0]+:8]};
        end
        lh_mem: begin
          cdb_load_rs_v = { {16{forward_wdata[15+16*cdb_load_rs_addr[1]]}}, forward_wdata[16*cdb_load_rs_addr[1]+:16] };
        end
        lhu_mem: begin
          cdb_load_rs_v = {{16{1'b0}}, forward_wdata[16*cdb_load_rs_addr[1]+:16]};
        end
        lw_mem: begin
          cdb_load_rs_v = forward_wdata;
        end
      endcase
      if (forward_wmask == 4'b1111) begin
        cdb_load_rs_rdata_valid = '1;
      end
    end
  end

endmodule
