module CONVERT_WRITE(
    input logic [31:0] ufp_addr,
    input logic [31:0] din_32,
    input logic [3:0] wmask_4,
    output logic [255:0] dout_256,
    output logic [31:0] wmask_32
);

    always_comb begin 
        dout_256 = '0;

        if (wmask_4[0]) begin 
            dout_256[32 * ufp_addr[4:2] +: 8] = din_32[7 : 0];
        end
        if (wmask_4[1]) begin 
            dout_256[8 + 32 * ufp_addr[4:2] +: 8] = din_32[15 : 8];
        end
        if (wmask_4[2]) begin 
            dout_256[16 + 32 * ufp_addr[4:2] +: 8] = din_32[23 : 16];
        end
        if (wmask_4[3]) begin 
            dout_256[24 + 32 * ufp_addr[4:2] +: 8] = din_32[31 : 24];
        end

        wmask_32 = wmask_4 << ufp_addr[4:0];
    end 

endmodule