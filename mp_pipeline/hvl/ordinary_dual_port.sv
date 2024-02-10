module ordinary_dual_port #(
    parameter MEMFILE = "memory.lst"
)(
    mem_itf.mem itf_i,
    mem_itf.mem itf_d
);

    logic [31:0] internal_memory_array [logic [31:2]];

    logic [31:0] tag_i [logic [2:0]];
    logic [31:0] tag_d [logic [2:0]];

    int i_delay;
    int d_delay;

    always @(posedge itf_i.clk iff itf_i.rst) begin
        internal_memory_array.delete();
        for (int i = 0; i < 8; i++) begin
            tag_i[i] = '0;
        end
        $readmemh(MEMFILE, internal_memory_array);
    end

    always @(posedge itf_d.clk iff itf_d.rst) begin
        internal_memory_array.delete();
        for (int i = 0; i < 8; i++) begin
            tag_d[i] = '0;
        end
        $readmemh(MEMFILE, internal_memory_array);
    end

    always @(posedge itf_i.clk iff !itf_i.rst) begin
        if ($isunknown(itf_i.rmask)) begin
            $error("Memory I-Port Error: rmask contains 'x");
            itf_i.error <= 1'b1;
        end
        if (|itf_i.rmask) begin
            if ($isunknown(itf_i.addr)) begin
                $error("Memory I-Port Error: address contains 'x");
                itf_i.error <= 1'b1;
            end
            if (itf_i.addr[1:0] != 2'b00) begin
                $error("Memory I-Port Error: address is not 32-bit aligned");
                itf_i.error <= 1'b1;
            end
        end
        // if ((|itf_i.rmask) && itf_i.resp) begin
        //     if ($isunknown(itf_i.rdata)) begin
        //         $warning("Memory I-Port Warning: rdata contains 'x");
        //     end
        // end
    end

    always @(posedge itf_d.clk iff !itf_d.rst) begin
        if ($isunknown(itf_d.rmask)) begin
            $error("Memory D-Port Error: rmask contains 'x");
            itf_d.error <= 1'b1;
        end
        if ($isunknown(itf_d.wmask)) begin
            $error("Memory D-Port Error: wmask contains 'x");
            itf_d.error <= 1'b1;
        end
        if ((|itf_d.rmask) && (|itf_d.wmask)) begin
            $error("Memory D-Port Error: Simultaneous read and write");
            itf_d.error <= 1'b1;
        end
        if ((|itf_d.rmask) || (|itf_d.wmask)) begin
            if ($isunknown(itf_d.addr)) begin
                $error("Memory D-Port Error: address contains 'x");
                itf_d.error <= 1'b1;
            end
            if (itf_d.addr[1:0] != 2'b00) begin
                $error("Memory D-Port Error: address is not 32-bit aligned");
                itf_d.error <= 1'b1;
            end
        end
    end

    always @(posedge itf_i.clk) begin
        logic [31:0] i_cached_addr;
        logic [3:0] i_cached_rmask;
        i_cached_addr = itf_i.addr;
        i_cached_rmask = itf_i.rmask;
        if (itf_i.rst) begin
            itf_i.rdata <= 'x;
            itf_i.resp <= 1'b0;
        end else if (|i_cached_rmask) begin
            begin
                if (tag_i[i_cached_addr[4:2]] != i_cached_addr) begin
                    itf_i.resp <= 1'b0;
                    std::randomize(i_delay) with {
                        i_delay dist {
                            [5:7] := 80,
                            [8:15] := 20
                        };
                    };
                    repeat (i_delay) @(posedge itf_i.clk);
                    tag_i[i_cached_addr[4:2]] = i_cached_addr;
                end
                for (int i = 0; i < 4; i++) begin
                    if (i_cached_rmask[i]) begin
                        itf_i.rdata[i*8+:8] <= internal_memory_array[i_cached_addr[31:2]][i*8+:8];
                    end else begin
                        itf_i.rdata[i*8+:8] <= 'x;
                    end
                end
                itf_i.resp <= 1'b1;
            end
        end else begin
            itf_i.rdata <= 'x;
            itf_i.resp <= 1'b0;
        end
    end

    always @(posedge itf_d.clk) begin
        logic [31:0] d_cached_addr;
        logic [3:0] d_cached_rmask;
        logic [3:0] d_cached_wmask;
        logic [31:0] d_cached_wdata;
        d_cached_addr = itf_d.addr;
        d_cached_rmask = itf_d.rmask;
        d_cached_wmask = itf_d.wmask;
        d_cached_wdata = itf_d.wdata;
        if (itf_d.rst) begin
            itf_d.rdata <= 'x;
            itf_d.resp <= 1'b0;
        end else if (|d_cached_rmask) begin
            begin
                if (tag_d[d_cached_addr[4:2]] != d_cached_addr) begin
                    itf_d.resp <= 1'b0;
                    std::randomize(d_delay) with {
                        d_delay dist {
                            [5:7] := 80,
                            [8:15] := 20
                        };
                    };
                    repeat (d_delay) @(posedge itf_d.clk);
                    tag_d[d_cached_addr[4:2]] = d_cached_addr;
                end
                for (int i = 0; i < 4; i++) begin
                    if (d_cached_rmask[i]) begin
                        itf_d.rdata[i*8+:8] <= internal_memory_array[d_cached_addr[31:2]][i*8+:8];
                    end else begin
                        itf_d.rdata[i*8+:8] <= 'x;
                    end
                end
                itf_d.resp <= 1'b1;
            end
        end else if (|d_cached_wmask) begin
            begin
                for (int i = 0; i < 4; i++) begin
                    if (d_cached_wmask[i]) begin
                        internal_memory_array[d_cached_addr[31:2]][i*8+:8] = d_cached_wdata[i*8+:8];
                    end
                end
                itf_d.resp <= 1'b1;
            end
        end else begin
            itf_d.rdata <= 'x;
            itf_d.resp <= 1'b0;
        end
    end

endmodule