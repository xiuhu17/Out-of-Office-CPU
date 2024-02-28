// [way A][way B][way C][way D]
// [3]    [2]    [1]    [0] 
module HITMISS(
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

    logic [3:0] PLRU_Way_4;
    always_comb begin 
        Hit_Miss = 'x;
        PLRU_Way_Visit = 'x;

        PLRU_Way_4[3] = (dirty_tag_A[22:0] == curr_tag) && valid_A;
        PLRU_Way_4[2] = (dirty_tag_B[22:0] == curr_tag) && valid_B;
        PLRU_Way_4[1] = (dirty_tag_C[22:0] == curr_tag) && valid_C;
        PLRU_Way_4[0] = (dirty_tag_D[22:0] == curr_tag) && valid_D;

        if (PLRU_Way_4) begin
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
                Way_A: begin // valid and dirty 
                    if (valid_A && dirty_tag_A[23]) begin 
                        Hit_Miss = Dirty_Miss;
                    end else begin
                        Hit_Miss = Clean_Miss;
                    end 
                end 
                Way_B: begin
                    if (valid_B && dirty_tag_B[23]) begin
                        Hit_Miss = Dirty_Miss;
                    end else begin
                        Hit_Miss = Clean_Miss;
                    end 
                end
                Way_C: begin 
                    if (valid_C && dirty_tag_C[23]) begin
                        Hit_Miss = Dirty_Miss;
                    end else begin
                        Hit_Miss = Clean_Miss;
                    end 
                end
                Way_D: begin 
                    if (valid_D && dirty_tag_D[23]) begin
                        Hit_Miss = Dirty_Miss;
                    end else begin
                        Hit_Miss = Clean_Miss;
                    end
                end
            endcase 
        end 
    end 

endmodule