module magic_dual_port #(
    parameter MEMFILE = "memory.lst"
)(
    mem_itf.mem itf_i,
    mem_itf.mem itf_d
);

    logic [31:0] internal_memory_array [logic [31:2]];

    always @(posedge itf_i.clk iff itf_i.rst) begin
        internal_memory_array.delete();
        $readmemh(MEMFILE, internal_memory_array);
    end

    always @(posedge itf_d.clk iff itf_d.rst) begin
        internal_memory_array.delete();
        $readmemh(MEMFILE, internal_memory_array);
    end

    always @(posedge itf_i.clk iff !itf_i.rst) begin
        if ($isunknown(itf_i.rmask)) begin
            $error("Magic Memory I-Port Error: rmask contains 'x");
            itf_i.error <= 1'b1;
        end
        if (|itf_i.rmask) begin
            if ($isunknown(itf_i.addr)) begin
                $error("Magic Memory I-Port Error: address contains 'x");
                itf_i.error <= 1'b1;
            end
            if (itf_i.addr[1:0] != 2'b00) begin
                $error("Magic Memory I-Port Error: address is not 32-bit aligned");
                itf_i.error <= 1'b1;
            end
        end
        // if ((|itf_i.rmask) && itf_i.resp) begin
        //     if ($isunknown(itf_i.rdata)) begin
        //         $warning("Magic Memory I-Port Warning: rdata contains 'x");
        //     end
        // end
    end

    always @(posedge itf_d.clk iff !itf_d.rst) begin
        if ($isunknown(itf_d.rmask)) begin
            $error("Magic Memory D-Port Error: rmask contains 'x");
            itf_d.error <= 1'b1;
        end
        if ($isunknown(itf_d.wmask)) begin
            $error("Magic Memory D-Port Error: wmask contains 'x");
            itf_d.error <= 1'b1;
        end
        if ((|itf_d.rmask) && (|itf_d.wmask)) begin
            $error("Magic Memory D-Port Error: Simultaneous read and write");
            itf_d.error <= 1'b1;
        end
        if ((|itf_d.rmask) || (|itf_d.wmask)) begin
            if ($isunknown(itf_d.addr)) begin
                $error("Magic Memory D-Port Error: address contains 'x");
                itf_d.error <= 1'b1;
            end
            if (itf_d.addr[1:0] != 2'b00) begin
                $error("Magic Memory D-Port Error: address is not 32-bit aligned");
                itf_d.error <= 1'b1;
            end
        end
    end

    always_ff @(posedge itf_i.clk) begin
        if (itf_i.rst) begin
            itf_i.rdata <= 'x;
            itf_i.resp <= 1'b0;
        end else if (|itf_i.rmask) begin
            for (int i = 0; i < 4; i++) begin
                if (itf_i.rmask[i]) begin
                    itf_i.rdata[i*8+:8] <= internal_memory_array[itf_i.addr[31:2]][i*8+:8];
                end else begin
                    itf_i.rdata[i*8+:8] <= 'x;
                end
            end
            itf_i.resp <= 1'b1;
        end else begin
            itf_i.rdata <= 'x;
            itf_i.resp <= 1'b0;
        end
    end

    always_ff @(posedge itf_d.clk) begin
        if (itf_d.rst) begin
            itf_d.rdata <= 'x;
            itf_d.resp <= 1'b0;
        end else if (|itf_d.rmask) begin
            for (int i = 0; i < 4; i++) begin
                if (itf_d.rmask[i]) begin
                    itf_d.rdata[i*8+:8] <= internal_memory_array[itf_d.addr[31:2]][i*8+:8];
                end else begin
                    itf_d.rdata[i*8+:8] <= 'x;
                end
            end
            itf_d.resp <= 1'b1;
        end else if (|itf_d.wmask) begin
            for (int i = 0; i < 4; i++) begin
                if (itf_d.wmask[i]) begin
                    internal_memory_array[itf_d.addr[31:2]][i*8+:8] = itf_d.wdata[i*8+:8];
                end
            end
            itf_d.resp <= 1'b1;
        end else begin
            itf_d.rdata <= 'x;
            itf_d.resp <= 1'b0;
        end
    end

endmodule