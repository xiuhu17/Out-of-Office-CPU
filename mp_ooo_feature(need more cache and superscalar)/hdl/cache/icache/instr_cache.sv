module instr_cache
  import cache_types::*;
(
    input logic clk,
    input logic rst,

    // cpu side signals, ufp -> upward facing port
    input  logic [31:0] cpu_ufp_addr,
    input  logic [ 3:0] cpu_ufp_rmask,
    output logic [31:0] ufp_rdata,
    output logic        ufp_resp,

    // memory side signals, bfp -> downward facing port
    input logic        bfp_ready,
    input logic [63:0] bfp_rdata,
    input logic [31:0] bfp_raddr,
    input logic        bfp_rvalid,

    output logic [31:0] bfp_addr,
    output logic        bfp_read,

    output logic bfp_read_stage
);

  logic [31:0] ufp_addr;
  logic [3:0] ufp_rmask;

  logic [255:0] internal_data_array_read[4];
  logic [255:0] internal_data_array_write[4];
  logic [22:0] internal_tag_array_read[4];
  logic [22:0] internal_tag_array_write[4];
  logic internal_valid_array_read[4];
  logic internal_valid_array_write[4];
  logic data_array_web0[4];
  logic tag_array_web0[4];
  logic valid_array_web0[4];
  logic [31:0] internal_data_array_mask[4];

  logic [3:0] curr_set;
  logic [3:0] read_set;
  logic [22:0] curr_tag;
  logic ufp_read;
  logic [1:0] Hit_Miss;
  logic [1:0] Sram_op;
  logic [1:0] PLRU_Way_Replace;
  logic [1:0] PLRU_Way_Visit;
  logic csb0;
  logic [1:0] bank_shift;

  always_comb begin
    curr_set = ufp_addr[8:5];
    curr_tag = ufp_addr[31:9];
    read_set = curr_set;
    ufp_read = '0;
    csb0 = '1;
    if (ufp_rmask != '0) begin
      ufp_read = '1;
      csb0 = '0;
    end
    if (ufp_resp) begin 
      if (cpu_ufp_rmask != '0) begin
        csb0 = '0;
        read_set = cpu_ufp_addr[8:5];
      end
    end
  end

  // hit read
  always_comb begin
    ufp_rdata = '0;
    if (Sram_op == Hit_Read_Clean) begin
      ufp_rdata = internal_data_array_read[PLRU_Way_Visit][32*ufp_addr[4:2]+:32];
    end
  end

  // web0: miss replace write
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      data_array_web0[i]  = '1;
      tag_array_web0[i]   = '1;
      valid_array_web0[i] = '1;
    end
    if (Sram_op == Miss_Replace) begin
      data_array_web0[PLRU_Way_Replace]  = 1'b0;
      tag_array_web0[PLRU_Way_Replace]   = 1'b0;
      valid_array_web0[PLRU_Way_Replace] = 1'b0;
    end
  end

  // data write: miss replace write
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      internal_data_array_write[i]  = '0;
      internal_tag_array_write[i]   = '0;
      internal_valid_array_write[i] = '0;
      internal_data_array_mask[i]   = '0;
    end
    if (Sram_op == Miss_Replace) begin
      internal_data_array_write[PLRU_Way_Replace][64*bank_shift+:64] = bfp_rdata;
      internal_tag_array_write[PLRU_Way_Replace] = curr_tag;
      internal_valid_array_write[PLRU_Way_Replace] = 1'b1;
      internal_data_array_mask[PLRU_Way_Replace] = 32'hff << (bank_shift * 8);
    end
  end

  // bfp:
  always_comb begin
    bfp_addr = '0;
    if (bfp_read) begin
      bfp_addr = {curr_tag, curr_set, 5'b0};
    end
  end

  instr_cachefsm instr_cachefsm (
      .clk(clk),
      .rst(rst),
      .cpu_ufp_rmask(cpu_ufp_rmask),
      .ufp_read(ufp_read),
      .Hit_Miss(Hit_Miss),
      .ufp_addr(ufp_addr),
      .bfp_ready(bfp_ready),
      .bfp_raddr(bfp_raddr),
      .bfp_rvalid(bfp_rvalid),
      .Sram_op(Sram_op),
      .ufp_resp(ufp_resp),
      .bfp_read(bfp_read),
      .bfp_read_stage(bfp_read_stage),
      .bank_shift(bank_shift)
  );

  instr_serve instr_serve (
      .clk(clk),
      .rst(rst),
      .ufp_resp(ufp_resp),
      .cpu_ufp_addr(cpu_ufp_addr),
      .cpu_ufp_rmask(cpu_ufp_rmask),
      .ufp_addr(ufp_addr),
      .ufp_rmask(ufp_rmask)
  );


  logic [3:0] PLRU_Way_4;
  always_comb begin
    Hit_Miss = 'x;
    PLRU_Way_Visit = 'x;

    PLRU_Way_4[3] = (internal_tag_array_read[Way_A] == curr_tag) & internal_valid_array_read[Way_A];
    PLRU_Way_4[2] = (internal_tag_array_read[Way_B] == curr_tag) & internal_valid_array_read[Way_B];
    PLRU_Way_4[1] = (internal_tag_array_read[Way_C] == curr_tag) & internal_valid_array_read[Way_C];
    PLRU_Way_4[0] = (internal_tag_array_read[Way_D] == curr_tag) & internal_valid_array_read[Way_D];

    if (PLRU_Way_4 != '0) begin
      Hit_Miss = Hit;
      case (PLRU_Way_4)
        Way_A_4: begin
          PLRU_Way_Visit = Way_A;
        end
        Way_B_4: begin
          PLRU_Way_Visit = Way_B;
        end
        Way_C_4: begin
          PLRU_Way_Visit = Way_C;
        end
        Way_D_4: begin
          PLRU_Way_Visit = Way_D;
        end
      endcase
    end else begin
      Hit_Miss = Clean_Miss;
    end
  end


  PLRU plru (
      .clk(clk),
      .rst(rst),
      .ufp_Resp(ufp_resp),
      .curr_set(curr_set),
      // .Way_A_Valid(internal_valid_array_read[Way_A]),
      // .Way_B_Valid(internal_valid_array_read[Way_B]),
      // .Way_C_Valid(internal_valid_array_read[Way_C]),
      // .Way_D_Valid(internal_valid_array_read[Way_D]),
      .PLRU_Way_Visit(PLRU_Way_Visit),
      .PLRU_Way_Replace(PLRU_Way_Replace)
  );

  generate
    for (genvar i = 0; i < 4; i++) begin : arrays
      instr_cache_data_array data_array (
          .clk0  (clk),
          .csb0  (csb0),
          .web0  (data_array_web0[i]),
          .wmask0(internal_data_array_mask[i]),
          .addr0 (read_set),
          .din0  (internal_data_array_write[i]),
          .dout0 (internal_data_array_read[i])
      );
      instr_cache_tag_array tag_array (
          .clk0 (clk),
          .csb0 (csb0),
          .web0 (tag_array_web0[i]),
          .addr0(read_set),
          .din0 (internal_tag_array_write[i]),
          .dout0(internal_tag_array_read[i])
      );
      ff_array #(
          .WIDTH(1)
      ) valid_array (
          .clk0 (clk),
          .rst0 (rst),
          .csb0 (csb0),
          .web0 (valid_array_web0[i]),
          .addr0(read_set),
          .din0 (internal_valid_array_write[i]),
          .dout0(internal_valid_array_read[i])
      );

    end
  endgenerate

endmodule
