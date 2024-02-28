module CACHEFSM
import cache_types::*; 
(
    input logic clk,
    input logic rst,
    input logic ufp_Read,
    input logic ufp_Write,
    input Hit_Miss_t Hit_Miss, 
    input logic dfp_Resp,
    
    // signal
    output Sram_op_t Sram_op,
    output logic ufp_Resp,
    output logic dfp_Read,
    output logic dfp_Write
);


enum logic[1:0] {Idle, Compare_Tag, Write_Back, Allocate} curr_state, next_state;

always_ff @ (posedge clk) begin 
    if (rst) begin 
        curr_state <= Idle;
    end else begin 
        curr_state <= next_state;
    end     
end 

always_comb begin 
    next_state = curr_state;
    Sram_op = 'x;
    ufp_Resp = '0;
    dfp_Read = '0;
    dfp_Write = '0;

    case(curr_state)    
        Idle: begin 
            if (ufp_Read) begin 
                next_state = Compare_Tag;
            end else if (ufp_Write) begin 
                next_state = Compare_Tag;
            end 
        end 
        Compare_Tag: begin 
            case (Hit_Miss)
                Hit: begin 
                    next_state = Idle;
                end 
                Dirty_Miss: begin
                    next_state = Write_Back;
                end 
                Clean_Miss: begin 
                    next_state = Allocate;
                end 
            endcase
        end 
        Write_Back: begin 
            if (dfp_Resp) begin 
                next_state = Allocate;
            end
        end 
        Allocate: begin 
            if (dfp_Resp) begin 
                next_state = Idle;
            end 
        end
    endcase

    case (curr_state) 
        Compare_Tag: begin 
            if (Hit_Miss == Hit) begin 
                ufp_Resp = '1;
                if (ufp_Read) begin 
                    Sram_op = Hit_Read_Clean;
                end else if (ufp_Write) begin 
                    Sram_op = Hit_Write_Dirty;
                end 
            end 
        end 
        Write_Back: begin
            dfp_Write = '1;
        end 
        Allocate: begin
            dfp_Read = '1;
            if (dfp_Resp) begin 
                Sram_op = Miss_Replace;
            end 
        end 
    endcase 
end 

endmodule