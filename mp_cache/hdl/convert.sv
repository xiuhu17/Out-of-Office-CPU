module convert(
    input logic [255:0] din,
    input logic [4:0] low_bit,
    input logic [3:0] mask,
    output logic [31:0] dout
);

    logic [63:0] four_byte_group;
    assign four_byte_group = din[32 * low_bit[4:2] +: 32];
    assign dout = {8{mask[3]}, 8{mask[2]}, 8{mask[1]}, 8{mask[0]}} & four_byte_group;
endmodule