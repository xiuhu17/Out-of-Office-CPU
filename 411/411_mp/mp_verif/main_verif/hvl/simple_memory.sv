module simple_memory
#(
    parameter MEMFILE = "memory.lst",
    parameter DELAY   = 3
)(
    mem_itf.mem itf
);

    timeunit 1ns;
    timeprecision 1ns;

    logic [31:0] internal_memory_array [logic [31:2]];

    always @(posedge itf.clk) begin
        if (itf.rst === 1'b0) begin
            if ($isunknown(itf.read) || $isunknown(itf.write) || $isunknown(itf.wmask)) begin
                $error("Memory Error: Control containes 1'bx");
                itf.error <= 1'b1;
            end
            if (itf.read === 1'b1 && itf.write === 1'b1) begin
                $error("Memory Error: Simultaneous memory read and write");
                itf.error <= 1'b1;
            end
            if (itf.read === 1'b1 || itf.write === 1'b1) begin
                if ($isunknown(itf.addr)) begin
                    $error("Memory Error: Address contained 'x");
                    itf.error <= 1'b1;
                end
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
                itf.rdata <= internal_memory_array[itf.addr[31:2]];
                itf.resp <= 1'b1;
                @(posedge itf.clk);
                itf.resp <= 1'b0;
                disable f;
            end
        join
    endtask

    task automatic memwrite();
        logic [31:0] cached_addr;
        logic [3:0] cached_mask;
        cached_addr = itf.addr;
        cached_mask = itf.wmask;
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
                    if (itf.wmask != cached_mask) begin
                        $error("Memory Error: Mask changed");
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
                for (int i = 0; i < 4; i++) begin
                    if (itf.wmask[i]) begin
                        internal_memory_array[itf.addr[31:2]][i*8 +: 8] = itf.wdata[i*8 +: 8];
                    end
                end
                itf.resp <= 1'b0;
                disable f;
            end
        join
    endtask

endmodule : simple_memory
