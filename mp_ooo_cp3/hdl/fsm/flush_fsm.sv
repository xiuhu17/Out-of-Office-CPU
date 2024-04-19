module flush_fsm (
    input logic clk,
    input logic rst,

    input logic imem_resp,
    input logic imem_rqst,

    input logic rob_valid,
    input logic rob_ready,
    input logic flush_branch,

    output logic move_flush
);

  enum logic {
    Start,
    IMEM_STALL
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
      if (imem_rqst) begin
        next_state = IMEM_STALL;
      end else begin
        next_state = Start;
      end
      IMEM_STALL:
      if (imem_resp) begin
        if (imem_rqst) begin
          next_state = IMEM_STALL;
        end else begin
          next_state = Start;
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
    endcase
  end

endmodule
