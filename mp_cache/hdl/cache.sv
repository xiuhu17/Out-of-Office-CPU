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

    logic [255:0] internal_data_array[4];
    logic [23:0] internal_tag_array[4];
    logic internal_valid_array[4];
    logic [3:0] curr_set;
    logic [22:0] curr_tag;
    logic [31:0] dfp_rdata_convert_32;
    logic [255:0] ufp_wdata_convert_256;
    logic [31:0] ufp_wmask_convert_32;
    logic ufp_Read;
    logic ufp_Write;
    logic [1:0] Hit_Miss;
    logic [1:0] Sram_op;
    logic [1:0] PLRU_Way_Replace,
    logic [1:0] PLRU_Way_Visit

    CONVERT_READ convert_read(
        .ufp_addr(ufp_addr),
        .din_256(dfp_rdata),
        .rmask_4(ufp_rmask),
        .dout_32(internal_dfp_rdata_32)
    );

    CONVERT_WRITE convert_write(
        .ufp_addr(ufp_addr),
        .din_32(ufp_wdata),
        .wmask_4(ufp_wmask),
        .dout_256(ufp_wdata_convert_256),
        .wmask_32(ufp_wmask_convert_32)
    );

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
        .dirty_tag_A(internal_tag_array[Way_A]),
        .dirty_tag_B(internal_tag_array[Way_B]),
        .dirty_tag_C(internal_tag_array[Way_C]),
        .dirty_tag_D(internal_tag_array[Way_D]),
        .valid_A(internal_valid_array[Way_A]),
        .valid_B(internal_valid_array[Way_B]),
        .valid_C(internal_valid_array[Way_C]),
        .valid_D(internal_valid_array[Way_D]),
        .curr_tag(curr_tag),
        .PLRU_Way_Replace(PLRU_Way_Replace),
        .Hit_Miss(Hit_Miss),
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
