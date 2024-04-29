module data_cachefsm
  import cache_types::*;
(
    input logic        clk,
    input logic        rst,
    input logic        ufp_read,
    input logic        ufp_write,
    input logic [ 1:0] Hit_Miss,
    input logic [31:0] ufp_addr,
    input logic        bfp_ready,
    input logic [31:0] bfp_raddr,
    input logic        bfp_rvalid,

    // signal
    output logic [1:0] Sram_op,
    output logic       ufp_resp,
    output logic       bfp_read,
    output logic       bfp_write,
    output logic       bfp_read_stage,
    output logic       bfp_write_stage,

    output logic [1:0] bank_shift
);

  enum logic [3:0] {
    Idle,
    Compare_Tag,
    Write_Back_0,
    Write_Back_1,
    Write_Back_2,
    Write_Back_3,
    Allocate,
    Allocate_0,
    Allocate_1,
    Allocate_2,
    Allocate_3
  }
      curr_state, next_state;

  always_ff @(posedge clk) begin
    if (rst) begin
      curr_state <= Idle;
    end else begin
      curr_state <= next_state;
    end
  end

  always_comb begin
    next_state = curr_state;
    Sram_op = 'x;
    bank_shift = '0;
    ufp_resp = '0;
    bfp_read = '0;
    bfp_write = '0;
    bfp_read_stage = '0;
    bfp_write_stage = '0;

    case (curr_state)
      Idle: begin
        if (ufp_read) begin
          next_state = Compare_Tag;
        end else if (ufp_write) begin
          next_state = Compare_Tag;
        end
      end
      Compare_Tag: begin
        case (Hit_Miss)
          Hit: begin
            next_state = Idle;
          end
          Dirty_Miss: begin
            next_state = Write_Back_0;
          end
          Clean_Miss: begin
            next_state = Allocate;
          end
        endcase
      end
      Write_Back_0: begin
        if (bfp_ready) begin
          next_state = Write_Back_1;
        end
      end
      Write_Back_1: begin
        if (bfp_ready) begin
          next_state = Write_Back_2;
        end
      end
      Write_Back_2: begin
        if (bfp_ready) begin
          next_state = Write_Back_3;
        end
      end
      Write_Back_3: begin
        if (bfp_ready) begin
          next_state = Allocate;
        end
      end
      Allocate: begin
        if (bfp_ready) begin
          next_state = Allocate_0;
        end
      end
      Allocate_0: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          next_state = Allocate_1;
        end
      end
      Allocate_1: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          next_state = Allocate_2;
        end
      end
      Allocate_2: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          next_state = Allocate_3;
        end
      end
      Allocate_3: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          next_state = Idle;
        end
      end
    endcase

    case (curr_state)
      Compare_Tag: begin
        if (Hit_Miss == Hit) begin
          ufp_resp = '1;
          if (ufp_read) begin
            Sram_op = Hit_Read_Clean;
          end else if (ufp_write) begin
            Sram_op = Hit_Write_Dirty;
          end
        end
      end
      Write_Back_0: begin
        bfp_write_stage = '1;
        if (bfp_ready) begin
          bank_shift = 2'b00;
          bfp_write  = '1;
        end
      end
      Write_Back_1: begin
        bfp_write_stage = '1;
        if (bfp_ready) begin
          bank_shift = 2'b01;
          bfp_write  = '1;
        end
      end
      Write_Back_2: begin
        bfp_write_stage = '1;
        if (bfp_ready) begin
          bank_shift = 2'b10;
          bfp_write  = '1;
        end
      end
      Write_Back_3: begin
        bfp_write_stage = '1;
        if (bfp_ready) begin
          bank_shift = 2'b11;
          bfp_write  = '1;
        end
      end
      Allocate: begin
        bfp_read_stage = '1;
        if (bfp_ready) begin
          bfp_read = '1;
        end
      end
      Allocate_0: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          bank_shift = 2'b00;
          Sram_op = Miss_Replace;
        end
      end
      Allocate_1: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          bank_shift = 2'b01;
          Sram_op = Miss_Replace;
        end
      end
      Allocate_2: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          bank_shift = 2'b10;
          Sram_op = Miss_Replace;
        end
      end
      Allocate_3: begin
        if (bfp_rvalid && (bfp_raddr == (ufp_addr & 32'hffffffe0))) begin
          bank_shift = 2'b11;
          Sram_op = Miss_Replace;
        end
      end
    endcase
  end

endmodule
