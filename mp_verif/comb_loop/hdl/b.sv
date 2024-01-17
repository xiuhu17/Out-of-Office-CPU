module b(
    input   logic           clk,
    input   logic           rst,
    output  logic           req,
    output  logic   [3:0]   req_key,
    input   logic           ack
);

            logic   [3:0]   internal_counter;
            logic   [3:0]   internal_counter_next;

    always_ff @(posedge clk) begin
        if (rst) begin
            internal_counter <= '0;
        end else begin
            internal_counter <= internal_counter_next;
        end
    end

    always_comb begin
        if (ack) begin
            internal_counter_next = internal_counter + 4'd1;
        end else begin
            internal_counter_next = internal_counter;
        end
    end

    assign req = 1'b1;
    assign req_key = internal_counter_next;

endmodule
