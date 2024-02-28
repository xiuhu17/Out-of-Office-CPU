module CONVERT_READ(
    input logic [255:0] din_256,
    input logic [31:0] ufp_addr,
    input logic [3:0] rmask,
    output logic [31:0] dout_32
);

    logic [31:0] four_byte_group;
    always_comb begin
        four_byte_group = din_256[32 * ufp_addr[4:2] +: 32];
        dout_32 = {8{rmask[3]}, 8{rmask[2]}, 8{rmask[1]}, 8{rmask[0]}} & four_byte_group;
    end
endmodule

module CONVERT_WRITE(
    input logic [31:0] din_32,
    input logic [255:0] din_256,
    input logic [31:0] ufp_addr,
    input logic [3:0] wmask,
    output logic [255:0] dout_256
);

    always_comb begin 
        dout_256 = din_256;
        if (wmask[0]) begin 
            dout_256[32 * ufp_addr[4:2] +: 8] = din_32[7 : 0];
        end
        if (wmask[1]) begin 
            dout_256[8 + 32 * ufp_addr[4:2] +: 8] = din_32[15 : 8];
        end
        if (wmask[2]) begin 
            dout_256[16 + 32 * ufp_addr[4:2] +: 8] = din_32[23 : 16];
        end
        if (wmask[3]) begin 
            dout_256[24 + 32 * ufp_addr[4:2] +: 8] = din_32[31 : 24];
        end
    end 

endmodule