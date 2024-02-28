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

    logic [3:0] curr_set;
    always_comb begin 
        curr_set = ufp_addr[8:5];
    end 

    logic [255:0] internal_data_array[4];
    logic [23:0] internal_tag_array[4];

    generate for (genvar i = 0; i < 4; i++) begin : arrays
        mp_cache_data_array data_array (
            .clk0       (clk),
            .csb0       (),
            .web0       (),
            .wmask0     (),
            .addr0      (),
            .din0       (),
            .dout0      ()
        );
        mp_cache_tag_array tag_array (
            .clk0       (clk),
            .csb0       (),
            .web0       (),
            .addr0      (),
            .din0       (),
            .dout0      ()
        );
        ff_array #(.WIDTH(1)) valid_array (
            .clk0       (clk),
            .rst0       (),
            .csb0       (),
            .web0       (),
            .addr0      (),
            .din0       (),
            .dout0      ()
        );

    end endgenerate

endmodule
