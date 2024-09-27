module STALLFSM
import rv32i_types::*;
(   
    input logic clk,
    input logic rst,
    input logic imem_rqst,
    input logic dmem_rqst,
    input logic imem_resp,
    input logic dmem_resp,
    output logic move_pipeline
);

    enum logic[1:0] {Start, IMEM_STALL, DMEM_STALL, IMEM_DMEM_STALL} curr_state, next_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            curr_state <= Start;
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin 
        next_state = curr_state;
        move_pipeline = '0;
        
        // fsm state change
        case (curr_state) 
            Start: begin 
                if (imem_rqst == '1 && dmem_rqst == '1) begin 
                    next_state = IMEM_DMEM_STALL;
                end else if (imem_rqst == '1) begin 
                    next_state = IMEM_STALL;
                end else if (dmem_rqst == '1) begin 
                    next_state = DMEM_STALL;
                end else begin 
                    next_state = Start;
                end
            end 
            IMEM_STALL: begin 
                if (imem_resp == '1) begin 
                    if (imem_rqst == '1 && dmem_rqst == '1) begin 
                        next_state = IMEM_DMEM_STALL;
                    end else if (imem_rqst == '1) begin 
                        next_state = IMEM_STALL;
                    end else if (dmem_rqst == '1) begin 
                        next_state = DMEM_STALL;
                    end else begin 
                        next_state = Start;
                    end 
                end
            end 
            DMEM_STALL: begin 
                if (dmem_resp == '1) begin 
                    if (imem_rqst == '1 && dmem_rqst == '1) begin 
                        next_state = IMEM_DMEM_STALL;
                    end else if (imem_rqst == '1) begin 
                        next_state = IMEM_STALL;
                    end else if (dmem_rqst == '1) begin 
                        next_state = DMEM_STALL;
                    end else begin 
                        next_state = Start;
                    end
                end
            end 
            IMEM_DMEM_STALL: begin 
                if (imem_resp == '1 && dmem_resp == '1) begin 
                    if (imem_rqst == '1 && dmem_rqst == '1) begin 
                        next_state = IMEM_DMEM_STALL;
                    end else if (imem_rqst == '1) begin 
                        next_state = IMEM_STALL;
                    end else if (dmem_rqst == '1) begin 
                        next_state = DMEM_STALL;
                    end else begin 
                        next_state = Start;
                    end
                end else if (imem_resp == '1) begin 
                    next_state = DMEM_STALL;
                end else if (dmem_resp == '1) begin 
                    next_state = IMEM_STALL;
                end 
            end
        endcase

        // control signal
        case (curr_state) 
            Start: begin
                move_pipeline = '1;
            end 
            IMEM_STALL: begin 
                if (imem_resp == '1) begin 
                    move_pipeline = '1;
                end
            end
            DMEM_STALL: begin 
                if (dmem_resp == '1) begin 
                    move_pipeline = '1;
                end
            end
            IMEM_DMEM_STALL: begin 
                if (imem_resp == '1 && dmem_resp == '1) begin 
                    move_pipeline = '1;
                end 
            end
        endcase
    end 
endmodule

module FLUSHFSM
import rv32i_types::*;
(
    input logic clk,
    input logic rst,
    
    input logic branch_flush,
    input logic move_pipeline,
    output logic branch_flush_delay
);
    enum logic {Start, FLUSH_DELAY} curr_state, next_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            curr_state <= Start;
        end else begin
            curr_state <= next_state;
        end
    end

    always_comb begin 
        next_state = curr_state;
        branch_flush_delay = '0;
        
        case (curr_state)
            Start: begin 
                if (move_pipeline == '1) begin 
                    if (branch_flush == '1) begin
                        next_state = FLUSH_DELAY;
                    end else begin
                        next_state = Start;
                    end
                end 
            end 
            FLUSH_DELAY: begin 
                if (move_pipeline == '1) begin 
                    if (branch_flush == '1) begin
                        next_state = FLUSH_DELAY;
                    end else begin
                        next_state = Start;
                    end
                end 
            end 
        endcase 
        
        case (curr_state)
            Start: begin 
                branch_flush_delay = '0;
            end 
            FLUSH_DELAY: begin 
                branch_flush_delay = '1;
            end 
        endcase
    end 

endmodule
