module fetch_fsm (
    input logic clk,
    input logic rst,

    input logic imem_resp,
    input logic imem_rqst,

    input logic instr_full,
    input logic move_flush,

    output logic move_fetch
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
    move_fetch = '0;

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
      if (instr_full || move_flush) begin
        move_fetch = '0;
      end else begin
        move_fetch = '1;
      end
      IMEM_STALL:
      if (imem_resp) begin
        if (instr_full || move_flush) begin
          move_fetch = '0;
        end else begin
          move_fetch = '1;
        end
      end
    endcase
  end

endmodule
