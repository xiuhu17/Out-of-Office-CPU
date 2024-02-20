module simple_memory
#(
    parameter MEMFILE = "memory.lst",
    parameter DELAY   = 10
)(
    mem_itf.mem itf
);

    timeunit 1ns;
    timeprecision 1ns;

    logic [255:0] internal_memory_array [logic [31:5]];

    always @(posedge itf.clk iff !itf.rst) begin
        if (itf.read && itf.write) begin
            $error("Memory Error: Simultaneous read and write");
            itf.error <= 1'b1;
        end
        if ($isunknown(itf.read)) begin
            $error("Memory Error: read is 1'bx");
            itf.error <= 1'b1;
        end
        if ($isunknown(itf.write)) begin
            $error("Memory Error: write is 1'bx");
            itf.error <= 1'b1;
        end
        if (itf.read || itf.write) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: address contains 'x");
                itf.error <= 1'b1;
            end
        end
    end

    always @(posedge itf.clk) begin
        casez ({itf.rst, itf.read, itf.write})
            3'b1??: reset();
            3'b010: memread();
            3'b001: memwrite();
        endcase
    end

    initial itf.resp = 1'b0;

    task automatic reset();
        internal_memory_array.delete();
        $readmemh(MEMFILE, internal_memory_array);
        itf.resp <= 1'b0;
    endtask

    task automatic memread();
        logic [31:0] cached_addr;
        cached_addr = itf.addr;
        fork : f
            begin : error_check
                forever @(posedge itf.clk) begin
                    if (!itf.read) begin
                        $error("Memory Error: Read deasserted early");
                        itf.error <= 1'b1;
                        disable f;
                        break;
                    end
                    if (itf.write) begin
                        $error("Memory Error: Write asserted during read");
                        itf.error <= 1'b1;
                        disable f;
                        break;
                    end
                    if (itf.addr != cached_addr) begin
                        $error("Memory Error: Address changed");
                        itf.error <= 1'b1;
                        disable f;
                        break;
                    end
                end
            end
            begin : memreader
                repeat (DELAY) @(posedge itf.clk);
                itf.rdata <= internal_memory_array[itf.addr[31:5]];
                itf.resp <= 1'b1;
                @(posedge itf.clk);
                itf.resp <= 1'b0;
                disable f;
            end
        join
    endtask

    task automatic memwrite();
        logic [31:0] cached_addr;
        cached_addr = itf.addr;
        fork : f
            begin : error_check
                forever @(posedge itf.clk) begin
                    if (!itf.write) begin
                        $error("Memory Error: Write deasserted early");
                        itf.error <= 1'b1;
                        disable f;
                        break;
                    end
                    if (itf.read) begin
                        $error("Memory Error: Read asserted during Write");
                        itf.error <= 1'b1;
                        disable f;
                        break;
                    end
                    if (itf.addr != cached_addr) begin
                        $error("Memory Error: Address changed");
                        itf.error <= 1'b1;
                        disable f;
                        break;
                    end
                end
            end
            begin : memwrite
                repeat (DELAY) @(posedge itf.clk);
                itf.resp <= 1'b1;
                @(posedge itf.clk);
                internal_memory_array[itf.addr[31:5]] = itf.wdata;
                itf.resp <= 1'b0;
                disable f;
            end
        join
    endtask

endmodule : simple_memory
