module CACHEFSM(
    input logic clk,
    input logic rst,
    input logic CPU_Read,
    input logic CPU_Write,
    input logic Dirty_Miss,
    input logic Clean_Miss,
    input logic Hit,
    input logic Mem_Resp,
    
    // signal
    output Sram_op_t Sram_op,
    output logic Sram_resp,
    output logic dfp_read,
    output logic dfp_write
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
    Sram_resp = '0;
    dfp_read = '0;
    dfp_write = '0;

    case(curr_state)    
        Idle: begin 
            if (CPU_Read) begin 
                next_state = Compare_Tag;
            end else if (CPU_Write) begin 
                next_state = Compare_Tag;
            end 
        end 
        Compare_Tag: begin 
            if (Dirty_Miss) begin 
                next_state = Write_Back;
            end else if (Clean_Miss) begin 
                next_state = Allocate;
            end else if (Hit) begin 
                next_state = Idle;
            end 
        end 
        Write_Back: begin 
            if (Mem_Resp) begin 
                next_state = Allocate;
            end
        end 
        Allocate: begin 
            if (Mem_Resp) begin 
                next_state = Idle;
            end 
        end
    endcase

    case (curr_state) 
        Compare_Tag: begin 
            if (Hit) begin 
                Sram_resp = '1;
                if (CPU_Read) begin 
                    Sram_op = hit_read_clean;
                end else if (CPU_Write) begin 
                    Sram_op = hit_write_dirty;
                end 
            end 
        end 
        Write_Back: begin
            dfp_write = '1;
        end 
        Allocate: begin
            dfp_read = '1;
            if (Mem_Resp) begin 
                Sram_op = miss_replace;
            end 
        end 
    endcase 
end 

endmodule