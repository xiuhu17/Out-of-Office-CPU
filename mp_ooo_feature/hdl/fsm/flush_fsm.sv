module flush_fsm (
    input logic clk,
    input logic rst,

    input logic imem_resp,
    input logic imem_rqst,
    input logic dmem_resp,
    input logic dmem_rqst,

    input logic rob_valid,
    input logic rob_ready,
    input logic flush_branch,

    output logic move_flush
);

  enum logic [1:0] {
    Start,
    IMEM_STALL,
    DMEM_STALL,
    IMEM_DMEM_STALL
  }
      curr_state, next_state;

  always_ff @(posedge clk) begin
    if (rst || move_flush) begin
      curr_state <= Start;
    end else begin
      curr_state <= next_state;
    end
  end

  always_comb begin
    next_state = curr_state;
    move_flush = '0;

    case (curr_state)
      Start:
      if (imem_rqst && dmem_rqst) begin
        next_state = IMEM_DMEM_STALL;
      end else if (imem_rqst) begin
        next_state = IMEM_STALL;
      end else if (dmem_rqst) begin
        next_state = DMEM_STALL;
      end else begin
        next_state = Start;
      end
      IMEM_STALL:
      if (imem_resp) begin
        if (imem_rqst && dmem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end else if (imem_rqst) begin
          next_state = IMEM_STALL;
        end else if (dmem_rqst) begin
          next_state = DMEM_STALL;
        end else begin
          next_state = Start;
        end
      end else begin
        if (dmem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end
      end
      DMEM_STALL:
      if (dmem_resp) begin
        if (imem_rqst && dmem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end else if (imem_rqst) begin
          next_state = IMEM_STALL;
        end else if (dmem_rqst) begin
          next_state = DMEM_STALL;
        end else begin
          next_state = Start;
        end
      end else begin
        if (imem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end
      end
      IMEM_DMEM_STALL:
      if (imem_resp && dmem_resp) begin
        if (imem_rqst && dmem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end else if (imem_rqst) begin
          next_state = IMEM_STALL;
        end else if (dmem_rqst) begin
          next_state = DMEM_STALL;
        end else begin
          next_state = Start;
        end
      end else if (imem_resp) begin
        if (imem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end else begin
          next_state = DMEM_STALL;
        end
      end else if (dmem_resp) begin
        if (dmem_rqst) begin
          next_state = IMEM_DMEM_STALL;
        end else begin
          next_state = IMEM_STALL;
        end
      end
    endcase

    case (curr_state)
      Start:
      if (rob_valid && rob_ready && flush_branch) begin
        move_flush = '1;
      end else begin
        move_flush = '0;
      end
      IMEM_STALL:
      if (imem_resp) begin
        if (rob_valid && rob_ready && flush_branch) begin
          move_flush = '1;
        end else begin
          move_flush = '0;
        end
      end
      DMEM_STALL:
      if (dmem_resp) begin
        if (rob_valid && rob_ready && flush_branch) begin
          move_flush = '1;
        end else begin
          move_flush = '0;
        end
      end
      IMEM_DMEM_STALL:
      if (imem_resp && dmem_resp) begin
        if (rob_valid && rob_ready && flush_branch) begin
          move_flush = '1;
        end else begin
          move_flush = '0;
        end
      end
    endcase
  end

endmodule
