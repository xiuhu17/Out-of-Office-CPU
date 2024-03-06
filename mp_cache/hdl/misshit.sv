module HitMiss
import cache_types::*;  
(
    input logic [23:0] dirty_tag_A,
    input logic [23:0] dirty_tag_B,
    input logic [23:0] dirty_tag_C,
    input logic [23:0] dirty_tag_D,
    input logic valid_A,
    input logic valid_B,
    input logic valid_C,
    input logic valid_D,
    input logic [22:0] curr_tag,
    input  logic [1:0] PLRU_Way_Replace,
    output logic [1:0] Hit_Miss,
    output logic [1:0] PLRU_Way_Visit
);

    
endmodule