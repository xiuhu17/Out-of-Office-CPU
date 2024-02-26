module CACHEFSM(
    input logic clk,
    input logic rst,
    input logic SRAM_Read,
    input logic SRAM_Write,
    input logic Dirty_Miss,
    input logic Clean_Miss,
    input logic Mem_Resp,
    output Sram_op_t Sram_op
);


enum logic[2:0] {Idle, Compare_Tag_Rd, Write_Back_Rd, Allocate_Rd, Compare_Tag_Wr, Write_Back_Wr, Allocate_Wr} curr_state, next_state;

always_ff @ (posedge clk) begin 
    if (rst) begin 
        curr_state <= Idle;
    end else begin 
        curr_state <= next_state;
    end     
end 

always_comb begin 
    next_state = curr_state;

    case(curr_state) 
        Idle: begin 
            if (SRAM_Read) begin 
                next_state = Compare_Tag;
            end
        end
        Compare_Tag: begin 
            if (Dirty_Miss) begin 
                next_state = Write_Back;
            end else if (Clean_Miss) begin 
                next_state = Allocate;
            end 
        end 
        Write_Back: begin 
            if (Mem_Resp) begin 
                next_state = ALlocate;
            end 
        end 
        Allocate: begin 
            if (Mem_Resp) begin 
                next_state = Compare_Tag; 
            end 
        end 

    endcase
end 

endmodule