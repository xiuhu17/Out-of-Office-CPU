module load_store_fsm
  import rv32i_types::*;
#(
    parameter LOAD_RS_DEPTH  = 3,
    parameter STORE_RS_DEPTH = 3
) (
    input logic clk,
    input logic rst,

    input logic move_flush,

    input logic rob_ready,
    input logic rob_valid,
    input logic flush_branch,

    input logic dmem_resp,
    input logic dmem_r_rqst,
    input logic dmem_w_rqst,

    // for rqst
    input logic [LOAD_RS_DEPTH-1:0] load_rs_idx_rqst,
    output logic arbiter_load_rs,
    output logic arbiter_store_rs,

    // for pop
    output logic [LOAD_RS_DEPTH-1:0] load_rs_idx_executing,
    output logic load_rs_pop,
    output logic store_rs_pop,
    output logic dmem_rqst
);

  logic [LOAD_RS_DEPTH-1:0] internal_load_rs_idx_executing;

  enum logic [1:0] {
    Start,
    DMEM_R_STALL,
    DMEM_W_STALL
  }
      curr_state, next_state;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      curr_state <= Start;
    end else begin
      curr_state <= next_state;
    end
  end

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      internal_load_rs_idx_executing <= '0;
    end else begin
      case (curr_state)
        Start: begin
          if (!(flush_branch && rob_valid && rob_ready)) begin
            if (!dmem_w_rqst && dmem_r_rqst) begin
              internal_load_rs_idx_executing <= load_rs_idx_rqst;
            end
          end
        end
        DMEM_R_STALL: begin
          if (dmem_resp) begin
            internal_load_rs_idx_executing <= '0;
          end
        end
        DMEM_W_STALL: begin
          if (dmem_resp) begin
            internal_load_rs_idx_executing <= '0;
          end
        end
      endcase
    end
  end

  always_comb begin
    next_state = curr_state;
    dmem_rqst = '0;
    arbiter_load_rs = '0;
    arbiter_store_rs = '0;
    load_rs_pop = '0;
    store_rs_pop = '0;
    load_rs_idx_executing = '0;

    case (curr_state)
      Start: begin
        if (!(flush_branch && rob_valid && rob_ready)) begin
          if (dmem_w_rqst) begin
            next_state = DMEM_W_STALL;
          end else if (dmem_r_rqst) begin
            next_state = DMEM_R_STALL;
          end
        end
      end
      DMEM_R_STALL: begin
        if (dmem_resp) begin
          next_state = Start;
        end
      end
      DMEM_W_STALL: begin
        if (dmem_resp) begin
          next_state = Start;
        end
      end
    endcase

    case (curr_state)
      Start: begin
        if (!(flush_branch && rob_valid && rob_ready)) begin
          if (dmem_w_rqst) begin
            dmem_rqst = '1;
            arbiter_store_rs = '1;
          end else if (dmem_r_rqst) begin
            dmem_rqst = '1;
            arbiter_load_rs = '1;
          end
        end
      end
      DMEM_R_STALL: begin
        if (dmem_resp) begin
          load_rs_pop = '1;
          load_rs_idx_executing = internal_load_rs_idx_executing;
        end
      end
      DMEM_W_STALL: begin
        if (dmem_resp) begin
          store_rs_pop = '1;
        end
      end
    endcase
  end

endmodule
