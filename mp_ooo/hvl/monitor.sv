module monitor (
    mon_itf itf
);

    logic [7:0] rvfi_valid;
    logic [511:0] rvfi_order;
    logic [255:0] rvfi_insn;
    logic [7:0] rvfi_trap;
    logic [7:0] rvfi_halt;
    logic [7:0] rvfi_intr;
    logic [15:0] rvfi_mode;
    logic [39:0] rvfi_rs1_addr;
    logic [39:0] rvfi_rs2_addr;
    logic [255:0] rvfi_rs1_rdata;
    logic [255:0] rvfi_rs2_rdata;
    logic [39:0] rvfi_rd_addr;
    logic [255:0] rvfi_rd_wdata;
    logic [255:0] rvfi_pc_rdata;
    logic [255:0] rvfi_pc_wdata;
    logic [255:0] rvfi_mem_addr;
    logic [31:0] rvfi_mem_rmask;
    logic [31:0] rvfi_mem_wmask;
    logic [255:0] rvfi_mem_rdata;
    logic [255:0] rvfi_mem_wdata;
    logic [7:0] rvfi_mem_extamo;

    logic [15:0] errcode;

    assign rvfi_trap = '0;
    assign rvfi_intr = '0;
    assign rvfi_mode = '0;
    assign rvfi_mem_extamo = '0;
    generate
        for (genvar channel=0; channel < 8; ++channel) begin
            assign rvfi_valid[channel*$bits(itf.valid[channel]) +: $bits(itf.valid[channel])] = itf.valid[channel];
            assign rvfi_order[channel*$bits(itf.order[channel]) +: $bits(itf.order[channel])] = itf.order[channel];
            assign rvfi_insn[channel*$bits(itf.inst[channel]) +: $bits(itf.inst[channel])] = itf.inst[channel];
            assign rvfi_halt[channel*$bits(itf.halt[channel]) +: $bits(itf.halt[channel])] = itf.halt[channel];
            assign rvfi_rs1_addr[channel*$bits(itf.rs1_addr[channel]) +: $bits(itf.rs1_addr[channel])] = itf.rs1_addr[channel];
            assign rvfi_rs2_addr[channel*$bits(itf.rs2_addr[channel]) +: $bits(itf.rs2_addr[channel])] = itf.rs2_addr[channel];
            assign rvfi_rs1_rdata[channel*$bits(itf.rs1_rdata[channel]) +: $bits(itf.rs1_rdata[channel])] = (|itf.rs1_addr[channel]) ? itf.rs1_rdata[channel] : '0;
            assign rvfi_rs2_rdata[channel*$bits(itf.rs2_rdata[channel]) +: $bits(itf.rs2_rdata[channel])] = (|itf.rs2_addr[channel]) ? itf.rs2_rdata[channel] : '0;
            assign rvfi_rd_addr[channel*$bits(itf.rd_addr[channel]) +: $bits(itf.rd_addr[channel])] = itf.rd_addr[channel];
            assign rvfi_rd_wdata[channel*$bits(itf.rd_wdata[channel]) +: $bits(itf.rd_wdata[channel])] = (|itf.rd_addr[channel]) ? itf.rd_wdata[channel] : '0;
            assign rvfi_pc_rdata[channel*$bits(itf.pc_rdata[channel]) +: $bits(itf.pc_rdata[channel])] = itf.pc_rdata[channel];
            assign rvfi_pc_wdata[channel*$bits(itf.pc_wdata[channel]) +: $bits(itf.pc_wdata[channel])] = itf.pc_wdata[channel];
            assign rvfi_mem_addr[channel*$bits(itf.mem_addr[channel]) +: $bits(itf.mem_addr[channel])] = {itf.mem_addr[channel][31:2], 2'b00};
            assign rvfi_mem_rmask[channel*$bits(itf.mem_rmask[channel]) +: $bits(itf.mem_rmask[channel])] = itf.mem_rmask[channel];
            assign rvfi_mem_wmask[channel*$bits(itf.mem_wmask[channel]) +: $bits(itf.mem_wmask[channel])] = itf.mem_wmask[channel];
            assign rvfi_mem_rdata[channel*$bits(itf.mem_rdata[channel]) +: $bits(itf.mem_rdata[channel])] = itf.mem_rdata[channel];
            assign rvfi_mem_wdata[channel*$bits(itf.mem_wdata[channel]) +: $bits(itf.mem_wdata[channel])] = itf.mem_wdata[channel];
        end
    endgenerate

    always @(posedge itf.clk iff !itf.rst) begin
        for (int unsigned channel=0; channel < 8; ++channel) begin
            if ($isunknown(itf.valid[channel])) begin
                $error("RVFI Interface Error: valid is 1'bx");
                itf.error <= 1'b1;
            end
        end
    end

    generate
        for (genvar channel=0; channel < 8; ++channel) begin
            always @(posedge itf.clk iff (!itf.rst && itf.valid[channel])) begin
                if ($isunknown(itf.order[channel])) begin
                    $error("RVFI Interface Error: order contains 'x");
                    itf.error <= 1'b1;
                end
                if ($isunknown(itf.inst[channel])) begin
                    $error("RVFI Interface Error: inst contains 'x");
                    itf.error <= 1'b1;
                end
                if ($isunknown(itf.rs1_addr[channel])) begin
                    $error("RVFI Interface Error: rs1_addr contains 'x");
                    itf.error <= 1'b1;
                end
                if ($isunknown(itf.rs2_addr[channel])) begin
                    $error("RVFI Interface Error: rs2_addr contains 'x");
                    itf.error <= 1'b1;
                end
                if (itf.rs1_addr[channel] != '0) begin
                    if ($isunknown(itf.rs1_rdata[channel])) begin
                        $error("RVFI Interface Error: rs1_rdata contains 'x");
                        itf.error <= 1'b1;
                    end
                end
                if (itf.rs2_addr[channel] != '0) begin
                    if ($isunknown(itf.rs2_rdata[channel])) begin
                        $error("RVFI Interface Error: rs2_rdata contains 'x");
                        itf.error <= 1'b1;
                    end
                end
                if ($isunknown(itf.rd_addr[channel])) begin
                    $error("RVFI Interface Error: rd_addr contains 'x");
                    itf.error <= 1'b1;
                end
                if (itf.rd_addr[channel]) begin
                    if ($isunknown(itf.rd_wdata[channel])) begin
                        $error("RVFI Interface Error: rd_wdata contains 'x");
                        itf.error <= 1'b1;
                    end
                end
                if ($isunknown(itf.pc_rdata[channel])) begin
                    $error("RVFI Interface Error: pc_rdata contains 'x");
                    itf.error <= 1'b1;
                end
                if ($isunknown(itf.pc_wdata[channel])) begin
                    $error("RVFI Interface Error: pc_wdata contains 'x");
                    itf.error <= 1'b1;
                end
                if ($isunknown(itf.mem_rmask[channel])) begin
                    $error("RVFI Interface Error: mem_rmask contains 'x");
                    itf.error <= 1'b1;
                end
                if ($isunknown(itf.mem_wmask[channel])) begin
                    $error("RVFI Interface Error: mem_wmask contains 'x");
                    itf.error <= 1'b1;
                end
                if (|itf.mem_rmask[channel] || |itf.mem_wmask[channel]) begin
                    if ($isunknown(itf.mem_addr[channel])) begin
                        $error("RVFI Interface Error: mem_addr contains 'x");
                        itf.error <= 1'b1;
                    end
                end
                if (|itf.mem_rmask[channel]) begin
                    for (int i = 0; i < 4; i++) begin
                        if (itf.mem_rmask[channel][i]) begin
                            if ($isunknown(itf.mem_rdata[channel][i*8 +: 8])) begin
                                $error("RVFI Interface Error: mem_rdata contains 'x");
                                itf.error <= 1'b1;
                            end
                        end
                    end
                end
                if (|itf.mem_wmask[channel]) begin
                    for (int i = 0; i < 4; i++) begin
                        if (itf.mem_wmask[channel][i]) begin
                            if ($isunknown(itf.mem_wdata[channel][i*8 +: 8])) begin
                                $error("RVFI Interface Error: mem_wdata contains 'x");
                                itf.error <= 1'b1;
                            end
                        end
                    end 
                end 
            end
        end
    endgenerate

    

    initial begin
        for (int unsigned channel=0; channel < 8; ++channel) begin
            itf.halt[channel] = '0;
        end
    end
    always @(posedge itf.clk) begin
        for (int unsigned channel=0; channel < 8; ++channel) begin
            if ((!itf.rst && itf.valid[channel]) && ((itf.pc_rdata[channel] == itf.pc_wdata[channel]) || (itf.inst[channel] == 32'h00000063) || (itf.inst[channel] == 32'h0000006f) || (itf.inst[channel] == 32'hF0002013))) begin
                itf.halt[channel] <= 1'b1;
            end
        end
    end

    always @(posedge itf.clk) begin
        if (errcode != 0) begin
            $error("RVFI Monitor Error");
            itf.error <= 1'b1;
        end
    end

    longint inst_count = longint'(0);
    longint cycle_count = longint'(0);
    longint start_time = longint'(0);
    longint total_time = longint'(0);
    bit done_print_ipc = 1'b0;
    real ipc = real'(0);
    always @(posedge itf.clk) begin
        cycle_count += longint'(1);
        for (int unsigned channel=0; channel < 8; ++channel) begin
            if ((!itf.rst && itf.valid[channel]) && (itf.inst[channel] == 32'h00102013)) begin
                inst_count = longint'(0);
                cycle_count = longint'(0);
                start_time = $time;
                $display("Monitor: Segment Start time is %t",$time); 
            end else begin
                if (!itf.rst && itf.valid[channel]) begin
                    inst_count += longint'(1);
                end
            end
            if ((!itf.rst && itf.valid[channel]) && (itf.inst[channel] == 32'h00202013)) begin
                $display("Monitor: Segment Stop time is %t",$time); 
                done_print_ipc = 1'b1;
                ipc = real'(inst_count) / cycle_count;
                total_time = $time - start_time;
                $display("Monitor: Segment IPC: %f", ipc);
                $display("Monitor: Segment Time: %t", total_time);
            end
        end
    end

    final begin
        if (!done_print_ipc) begin
            ipc = real'(inst_count) / cycle_count;
            total_time = $time - start_time;
            $display("Monitor: Total IPC: %f", ipc);
            $display("Monitor: Total Time: %t", total_time);
        end
    end

    riscv_formal_monitor_rv32imc monitor(
        .clock              (itf.clk),
        .reset              (itf.rst),
        .rvfi_valid         (rvfi_valid),
        .rvfi_order         (rvfi_order),
        .rvfi_insn          (rvfi_insn),
        .rvfi_trap          (rvfi_trap),
        .rvfi_halt          (rvfi_halt),
        .rvfi_intr          (rvfi_intr),
        .rvfi_mode          (rvfi_mode),
        .rvfi_rs1_addr      (rvfi_rs1_addr),
        .rvfi_rs2_addr      (rvfi_rs2_addr),
        .rvfi_rs1_rdata     (rvfi_rs1_rdata),
        .rvfi_rs2_rdata     (rvfi_rs2_rdata),
        .rvfi_rd_addr       (rvfi_rd_addr),
        .rvfi_rd_wdata      (rvfi_rd_wdata),
        .rvfi_pc_rdata      (rvfi_pc_rdata),
        .rvfi_pc_wdata      (rvfi_pc_wdata),
        .rvfi_mem_addr      (rvfi_mem_addr),
        .rvfi_mem_rmask     (rvfi_mem_rmask),
        .rvfi_mem_wmask     (rvfi_mem_wmask),
        .rvfi_mem_rdata     (rvfi_mem_rdata),
        .rvfi_mem_wdata     (rvfi_mem_wdata),
        .rvfi_mem_extamo    (rvfi_mem_extamo),
        .errcode            (errcode)
    );

    int fd;
    initial fd = $fopen("./commit.log", "w");
    final $fclose(fd);

    always @ (posedge itf.clk) begin
        for (int unsigned channel=0; channel < 8; ++channel) begin
            if(itf.valid[channel]) begin
                if (itf.order[channel] % 1000 == 0) begin
                    $display("dut commit No.%d, rd_s: x%02d, rd: 0x%h", itf.order[channel], itf.rd_addr[channel], itf.rd_addr[channel] ? itf.rd_wdata[channel] : 5'd0);
                end
                if (itf.inst[channel][1:0] == 2'b11) begin
                    $fwrite(fd, "core   0: 3 0x%h (0x%h)", itf.pc_rdata[channel], itf.inst[channel]);
                end else begin
                    $fwrite(fd, "core   0: 3 0x%h (0x%h)", itf.pc_rdata[channel], itf.inst[channel][15:0]);
                end
                if (itf.rd_addr[channel] != 0) begin
                    if (itf.rd_addr[channel] < 10)
                        $fwrite(fd, " x%0d  ", itf.rd_addr[channel]);
                    else
                        $fwrite(fd, " x%0d ", itf.rd_addr[channel]);
                    $fwrite(fd, "0x%h", itf.rd_wdata[channel]);
                end
                if (itf.mem_rmask[channel] != 0) begin
                    automatic int first_1 = 0;
                    for(int i = 0; i < 4; i++) begin
                        if(itf.mem_rmask[channel][i]) begin
                            first_1 = i;
                            break;
                        end
                    end
                    $fwrite(fd, " mem 0x%h", {itf.mem_addr[channel][31:2], 2'b0} + first_1);
                end
                if (itf.mem_wmask[channel] != 0) begin
                    automatic int amount_o_1 = 0;
                    automatic int first_1 = 0;
                    for(int i = 0; i < 4; i++) begin
                        if(itf.mem_wmask[channel][i]) begin
                            amount_o_1 += 1;
                        end
                    end
                    for(int i = 0; i < 4; i++) begin
                        if(itf.mem_wmask[channel][i]) begin
                            first_1 = i;
                            break;
                        end
                    end
                    $fwrite(fd, " mem 0x%h", {itf.mem_addr[channel][31:2], 2'b0} + first_1);
                    case (amount_o_1)
                        1: begin
                            automatic logic[7:0] wdata_byte = itf.mem_wdata[channel][8*first_1 +: 8];
                            $fwrite(fd, " 0x%h", wdata_byte);
                        end
                        2: begin
                            automatic logic[15:0] wdata_half = itf.mem_wdata[channel][8*first_1 +: 16];
                            $fwrite(fd, " 0x%h", wdata_half);
                        end
                        4:
                            $fwrite(fd, " 0x%h", itf.mem_wdata[channel]);
                    endcase
                end
                $fwrite(fd, "\n");
            end
        end
    end

endmodule
