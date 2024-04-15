module cache
  import cache_types::*;
(
    input logic clk,
    input logic rst,

    // cpu side signals, ufp -> upward facing port
    input  logic [31:0] cpu_ufp_addr,
    input  logic [ 3:0] cpu_ufp_rmask,
    input  logic [ 3:0] cpu_ufp_wmask,
    output logic [31:0] cpu_ufp_rdata,
    input  logic [31:0] cpu_ufp_wdata,
    output logic        cpu_ufp_resp,

    // memory side signals, dfp -> downward facing port
    output logic [ 31:0] dfp_addr,
    output logic         dfp_read,
    output logic         dfp_write,
    output logic [255:0] dfp_wdata,
    input  logic         dfp_ready,

    input logic [255:0] dfp_rdata,
    input logic         dfp_resp
);

  // mp_ooo modifications
  logic [31:0] ufp_addr_reg;
  logic [3:0] ufp_rmask_reg;
  logic [3:0] ufp_wmask_reg;
  logic [31:0] ufp_wdata_reg;
  logic [31:0] ufp_rdata;
  logic ufp_resp;

  // 1: mask lower 4 bytes
  logic [31:0] ufp_addr;
  assign ufp_addr = cpu_ufp_addr & 32'hfffffffc;

  // 2: store request
  logic request;
  always_ff @(clk) begin
    if (rst) begin
      request <= 1'b0;
    end else if (ufp_Read || ufp_Write) begin
      request <= 1'b1;
      ufp_addr_reg <= ufp_addr;
      ufp_rmask_reg <= cpu_ufp_rmask;
      ufp_wmask_reg <= cpu_ufp_wmask;
      ufp_wdata_reg <= cpu_ufp_wdata;
    end else if (cpu_ufp_resp) begin
      request <= 1'b0;
    end
  end
  // 3: resp cycle, incoming rqst

  logic [255:0] internal_data_array_read[4];
  logic [255:0] internal_data_array_write[4];
  logic [23:0] internal_tag_array_read[4];
  logic [23:0] internal_tag_array_write[4];
  logic internal_valid_array_read[4];
  logic internal_valid_array_write[4];
  logic data_array_web0[4];
  logic tag_array_web0[4];
  logic valid_array_web0[4];
  logic [31:0] internal_data_array_mask[4];

  logic [3:0] curr_set;
  logic [22:0] curr_tag;
  logic ufp_Read;
  logic ufp_Write;
  logic [1:0] Hit_Miss;
  logic [1:0] Sram_op;
  logic [1:0] PLRU_Way_Replace;
  logic [1:0] PLRU_Way_Visit;

  logic csb0;


  always_comb begin
    curr_set = ufp_addr[8:5];
    curr_tag = ufp_addr[31:9];
    ufp_Read = '0;
    ufp_Write = '0;
    csb0 = '1;
    if (ufp_rmask != '0) begin
      ufp_Read = '1;
    end
    if (ufp_wmask != '0) begin
      ufp_Write = '1;
    end
    if ((ufp_rmask | ufp_wmask) != '0) begin
      csb0 = '0;
    end
  end

  // hit read
  always_comb begin
    ufp_rdata = '0;
    if (Sram_op == Hit_Read_Clean) begin
      ufp_rdata = internal_data_array_read[PLRU_Way_Visit][32*ufp_addr[4:2]+:32];
    end
  end

  // web0: hit dirty write or miss replace write
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      data_array_web0[i]  = '1;
      tag_array_web0[i]   = '1;
      valid_array_web0[i] = '1;
    end
    if (Sram_op == Hit_Write_Dirty) begin
      data_array_web0[PLRU_Way_Visit]  = 1'b0;
      tag_array_web0[PLRU_Way_Visit]   = 1'b0;
      valid_array_web0[PLRU_Way_Visit] = 1'b0;
    end else if (Sram_op == Miss_Replace) begin
      data_array_web0[PLRU_Way_Replace]  = 1'b0;
      tag_array_web0[PLRU_Way_Replace]   = 1'b0;
      valid_array_web0[PLRU_Way_Replace] = 1'b0;
    end
  end

  // data write: hit dirty write or miss replace write
  always_comb begin
    for (int i = 0; i < 4; i++) begin
      internal_data_array_write[i]  = '0;
      internal_tag_array_write[i]   = '0;
      internal_valid_array_write[i] = '0;
      internal_data_array_mask[i]   = '0;
    end
    if (Sram_op == Hit_Write_Dirty) begin
      internal_data_array_write[PLRU_Way_Visit][32*ufp_addr[4:2]+:32] = ufp_wdata;
      internal_tag_array_write[PLRU_Way_Visit] = {1'b1, curr_tag};
      internal_valid_array_write[PLRU_Way_Visit] = 1'b1;
      internal_data_array_mask[PLRU_Way_Visit] = ufp_wmask << ufp_addr[4:0];
    end else if (Sram_op == Miss_Replace) begin
      internal_data_array_write[PLRU_Way_Replace]  = dfp_rdata;
      internal_tag_array_write[PLRU_Way_Replace]   = {1'b0, curr_tag};
      internal_valid_array_write[PLRU_Way_Replace] = 1'b1;
      internal_data_array_mask[PLRU_Way_Replace]   = '1;
    end
  end

  // dfp:
  always_comb begin
    dfp_addr  = '0;
    dfp_wdata = '0;
    if (dfp_write) begin
      dfp_addr  = {internal_tag_array_read[PLRU_Way_Replace][22:0], curr_set, 5'b0};
      dfp_wdata = internal_data_array_read[PLRU_Way_Replace];
    end else if (dfp_read) begin
      dfp_addr = {curr_tag, curr_set, 5'b0};
    end
  end

  cachefsm cachefsm (
      .clk(clk),
      .rst(rst),
      .ufp_Read(ufp_Read),
      .ufp_Write(ufp_Write),
      .Hit_Miss(Hit_Miss),
      .dfp_Resp(dfp_resp),
      .Sram_op(Sram_op),
      .ufp_Resp(ufp_resp),
      .dfp_Read(dfp_read),
      .dfp_Write(dfp_write)
  );

  logic [3:0] PLRU_Way_4;
  always_comb begin
    Hit_Miss = 'x;
    PLRU_Way_Visit = 'x;

    PLRU_Way_4[3] = (internal_tag_array_read[Way_A][22:0] == curr_tag) & internal_valid_array_read[Way_A];
    PLRU_Way_4[2] = (internal_tag_array_read[Way_B][22:0] == curr_tag) & internal_valid_array_read[Way_B];
    PLRU_Way_4[1] = (internal_tag_array_read[Way_C][22:0] == curr_tag) & internal_valid_array_read[Way_C];
    PLRU_Way_4[0] = (internal_tag_array_read[Way_D][22:0] == curr_tag) & internal_valid_array_read[Way_D];

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
      case (PLRU_Way_Replace)
        Way_A: begin
          if (internal_valid_array_read[Way_A] && internal_tag_array_read[Way_A][23]) begin
            Hit_Miss = Dirty_Miss;
          end else begin
            Hit_Miss = Clean_Miss;
          end
        end
        Way_B: begin
          if (internal_valid_array_read[Way_B] && internal_tag_array_read[Way_B][23]) begin
            Hit_Miss = Dirty_Miss;
          end else begin
            Hit_Miss = Clean_Miss;
          end
        end
        Way_C: begin
          if (internal_valid_array_read[Way_C] && internal_tag_array_read[Way_C][23]) begin
            Hit_Miss = Dirty_Miss;
          end else begin
            Hit_Miss = Clean_Miss;
          end
        end
        Way_D: begin
          if (internal_valid_array_read[Way_D] && internal_tag_array_read[Way_D][23]) begin
            Hit_Miss = Dirty_Miss;
          end else begin
            Hit_Miss = Clean_Miss;
          end
        end
      endcase
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
      mp_cache_data_array data_array (
          .clk0  (clk),
          .csb0  (csb0),
          .web0  (data_array_web0[i]),
          .wmask0(internal_data_array_mask[i]),
          .addr0 (curr_set),
          .din0  (internal_data_array_write[i]),
          .dout0 (internal_data_array_read[i])
      );
      mp_cache_tag_array tag_array (
          .clk0 (clk),
          .csb0 (csb0),
          .web0 (tag_array_web0[i]),
          .addr0(curr_set),
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
          .addr0(curr_set),
          .din0 (internal_valid_array_write[i]),
          .dout0(internal_valid_array_read[i])
      );

    end
  endgenerate

endmodule
