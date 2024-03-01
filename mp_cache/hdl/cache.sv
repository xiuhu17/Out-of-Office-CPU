module cache (
    input   logic           clk,
    input   logic           rst,

    // cpu side signals, ufp -> upward facing port
    input   logic   [31:0]  ufp_addr,
    input   logic   [3:0]   ufp_rmask,
    input   logic   [3:0]   ufp_wmask,
    output  logic   [31:0]  ufp_rdata,
    input   logic   [31:0]  ufp_wdata,
    output  logic           ufp_resp,

    // memory side signals, dfp -> downward facing port
    output  logic   [31:0]  dfp_addr,
    output  logic           dfp_read,
    output  logic           dfp_write,
    input   logic   [255:0] dfp_rdata,
    output  logic   [255:0] dfp_wdata,
    input   logic           dfp_resp
);

    logic [255:0] internal_data_array_read[4];
    logic [255:0] internal_data_array_write[4];
    logic [23:0] internal_tag_array_read[4];
    logic [23:0] internal_tag_array_write[4];
    logic internal_valid_array_read[4];
    logic internal_valid_array_write[4];
    logic data_array_web0[4];
    logic tag_array_web0[4];
    logic valid_array_web0[4];

    logic [3:0] curr_set;
    logic [22:0] curr_tag;
    logic ufp_Read;
    logic ufp_Write;
    logic [1:0] Hit_Miss;
    logic [1:0] Sram_op;
    logic [1:0] PLRU_Way_Replace;
    logic [1:0] PLRU_Way_Visit;

    // hit read
    always_comb begin
        ufp_rdata = '0;
        if (Sram_op == Hit_Read_Clean) begin
            case (PLRU_Way_Visit)
                Way_A: begin 
                    ufp_rdata = internal_data_array_read[Way_A];
                end 
                Way_B: begin 
                    ufp_rdata = internal_data_array_read[Way_B];
                end 
                Way_C: begin 
                    ufp_rdata = internal_data_array_read[Way_C];
                end
                Way_D: begin 
                    ufp_rdata = internal_data_array_read[Way_D];
                end
            endcase
        end 
    end 

    // web0: hit dirty write or miss replace write
    always_comb begin 
        for (int i = 0; i < 4; i ++) begin 
            data_array_web0[i] = '1;
            tag_array_web0[i] = '1;
            valid_array_web0[i] = '1;
        end 
        if (Sram_op == Hit_Write_Dirty) begin 
            data_array_web0[PLRU_Way_Visit] = 1'b0;
            tag_array_web0[PLRU_Way_Visit] = 1'b0;
            valid_array_web0[PLRU_Way_Visit] = 1'b0;
        end else if (Sram_op == Miss_Replace) begin 
            data_array_web0[PLRU_Way_Replace] = 1'b0;
            tag_array_web0[PLRU_Way_Replace] = 1'b0;
            valid_array_web0[PLRU_Way_Replace] = 1'b0;
        end 
    end 

    // data write: hit dirty write or miss replace write
    always_comb begin 
        for (int i = 0; i < 4; i ++) begin 
            internal_data_array_write[i] = '0;
            internal_tag_array_write[i] = '0;
            internal_valid_array_write[i] = '0;
        end
        if (Sram_op == Hit_Write_Dirty) begin 
            internal_data_array_write[PLRU_Way_Visit] = 
            internal_tag_array_write[PLRU_Way_Visit] = 
            internal_valid_array_write[PLRU_Way_Visit] = 
        end else if (Sram_op == Miss_Replace) begin 

        end 
    end 

    // dfp:
    
    always_comb begin 
        curr_set = ufp_addr[8:5];
        curr_tag = ufp_addr[31:9];
        ufp_Read = '0;
        ufp_Write = '0;
        if (ufp_rmask) begin 
            ufp_Read = '1;
        end 
        if (ufp_wmask) begin
            ufp_Write = '1;
        end 
    end 

    CACHEFSM cachefsm(
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

    HITMISS misshit(
        .dirty_tag_A(internal_tag_array_read[Way_A]),
        .dirty_tag_B(internal_tag_array_read[Way_B]),
        .dirty_tag_C(internal_tag_array_read[Way_C]),
        .dirty_tag_D(internal_tag_array_read[Way_D]),
        .valid_A(internal_valid_array_read[Way_A]),
        .valid_B(internal_valid_array_read[Way_B]),
        .valid_C(internal_valid_array_read[Way_C]),
        .valid_D(internal_valid_array_read[Way_D]),
        .curr_tag(curr_tag),
        .Hit_Miss(Hit_Miss),
        .PLRU_Way_Replace(PLRU_Way_Replace),
        .PLRU_Way_Visit(PLRU_Way_Visit)
    );

    PLRU plru(
        .clk(clk),
        .rst(rst),
        .ufp_Resp(ufp_resp),
        .curr_set(curr_set),
        .PLRU_Way_Visit(PLRU_Way_Visit), 
        .PLRU_Way_Replace(PLRU_Way_Replace)
    );

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (),
            .wmask0     (),
            .addr0      (curr_set),
            .din0       (),
            .dout0      ()
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (1'b0),
            .web0       (),
            .addr0      (curr_set),
            .din0       (),
            .dout0      ()
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (rst),
            .csb0       (1'b0),
            .web0       (),
            .addr0      (curr_set),
            .din0       (),
            .dout0      ()
        );

    end endgenerate

endmodule
