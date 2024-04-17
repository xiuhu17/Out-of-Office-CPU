// SDRAM timing model
// Based on MT48LC64M4A2-75, modified for ECE411
// Limitations:
//   No refresh support
//   No auto precharge / Open page only

module banked_memory
#(
    parameter     MEMFILE                       = "memory.lst",
    parameter int DRAM_TIMMING_CL               = 20,   // In ns, aka tCAS, column access time
    parameter int DRAM_TIMMING_tRCD             = 20,   // in ns, active to r/w delay
    parameter int DRAM_TIMMING_tRP              = 20,   // in ns, precharge time
    parameter int DRAM_TIMMING_tRAS             = 44,   // in ns, active to precharge delay
    parameter int DRAM_TIMMING_tRC              = 66,   // in ns, active to active delay
    parameter int DRAM_TIMMING_tRRD             = 15,   // in ns, different bank active delay
    parameter int DRAM_TIMMING_tWR              = 15,   // in ns, write recovery time
    parameter int DRAM_PARAM_BA_WIDTH           = 4,    // in bits
    parameter int DRAM_PARAM_RA_WIDTH           = 20,   // in bits
    parameter int DRAM_PARAM_CA_WIDTH           = 3,    // in bits // artificially nerfed
    parameter int DRAM_PARAM_BUS_WIDTH          = 64,   // in bits
    parameter int DRAM_PARAM_BURST_LEN          = 4,    // in bursts
    parameter int DRAM_PARAM_QUEUE_SIZE         = 16,   // in requests
    parameter bit DRAM_RETURN_0_ON_X            = 0     // return 0 instead of x on rdata
)(
    banked_mem_itf.mem itf
);

    timeunit 1ns;
    timeprecision 1ns;

    localparam int DRAM_PARAM_NUM_BANKS         = 2**DRAM_PARAM_BA_WIDTH;
    localparam int DRAM_PARAM_ACCESS_WIDTH      = DRAM_PARAM_BUS_WIDTH * DRAM_PARAM_BURST_LEN;
    localparam int DRAM_PARAM_OFFSET_WIDTH      = $clog2(DRAM_PARAM_ACCESS_WIDTH / 8);
    localparam int DRAM_PARAM_ACCESS_ADDR_WIDTH = DRAM_PARAM_BA_WIDTH + DRAM_PARAM_RA_WIDTH + DRAM_PARAM_CA_WIDTH;
    localparam int DRAM_PARAM_TOTAL_ADDR_WIDTH  = DRAM_PARAM_ACCESS_ADDR_WIDTH + DRAM_PARAM_OFFSET_WIDTH;

    function logic [DRAM_PARAM_OFFSET_WIDTH-1:0]        get_offset  (logic [DRAM_PARAM_TOTAL_ADDR_WIDTH:0] addr);
        return addr[ 0                       +:  DRAM_PARAM_OFFSET_WIDTH];
    endfunction

    function logic [DRAM_PARAM_CA_WIDTH-1:0]            get_col     (logic [DRAM_PARAM_TOTAL_ADDR_WIDTH:0] addr);
        return addr[ DRAM_PARAM_OFFSET_WIDTH +:  DRAM_PARAM_CA_WIDTH];
    endfunction

    function logic [DRAM_PARAM_BA_WIDTH-1:0]            get_bank    (logic [DRAM_PARAM_TOTAL_ADDR_WIDTH:0] addr);
        return addr[(DRAM_PARAM_OFFSET_WIDTH +   DRAM_PARAM_CA_WIDTH) +: DRAM_PARAM_BA_WIDTH];
    endfunction

    function logic [DRAM_PARAM_RA_WIDTH-1:0]            get_row     (logic [DRAM_PARAM_TOTAL_ADDR_WIDTH:0] addr);
        return addr[(DRAM_PARAM_OFFSET_WIDTH +   DRAM_PARAM_CA_WIDTH  +  DRAM_PARAM_BA_WIDTH) +: DRAM_PARAM_RA_WIDTH];
    endfunction

    function logic [DRAM_PARAM_ACCESS_ADDR_WIDTH-1:0]   get_access  (logic [DRAM_PARAM_TOTAL_ADDR_WIDTH:0] addr);
        return addr[ DRAM_PARAM_OFFSET_WIDTH +: (DRAM_PARAM_CA_WIDTH  +  DRAM_PARAM_BA_WIDTH  +  DRAM_PARAM_RA_WIDTH)];
    endfunction

    logic [DRAM_PARAM_ACCESS_WIDTH-1:0] internal_memory_array [logic [DRAM_PARAM_ACCESS_ADDR_WIDTH-1:0]];

    int signed active_row   [DRAM_PARAM_NUM_BANKS];
    int signed tRAS_counter [DRAM_PARAM_NUM_BANKS];
    int signed tRC_counter  [DRAM_PARAM_NUM_BANKS];
    int signed tRRD_counter;

    typedef struct packed {
        logic   [DRAM_PARAM_TOTAL_ADDR_WIDTH-1:0]   addr;
        logic   [DRAM_PARAM_ACCESS_WIDTH-1:0]       wdata;
        logic                                       read;
    } in_queue_t;

    typedef struct packed {
        logic   [DRAM_PARAM_TOTAL_ADDR_WIDTH-1:0]   raddr;
        logic   [DRAM_PARAM_ACCESS_WIDTH-1:0]       rdata;
        logic                                       read;
    } out_queue_t;

    in_queue_t  in_queue [$:DRAM_PARAM_QUEUE_SIZE];
    out_queue_t out_queue[$];

    initial itf.ready = 1'b1;
    initial itf.rvalid = 1'b0;

    task automatic reset();
        internal_memory_array.delete();
        $readmemh(MEMFILE, internal_memory_array);
        tRRD_counter = 0;
        for (int i = 0; i < DRAM_PARAM_NUM_BANKS; i++) begin
            active_row[i] = -1;
            tRAS_counter[i] = 0;
            tRC_counter[i] = 0;
        end
        itf.ready <= 1'b1;
        itf.rvalid <= 1'b0;
        in_queue.delete();
        out_queue.delete();
    endtask

    always @(posedge itf.clk iff itf.rst) begin
        reset();
    end

    always begin
        #1;
        if (tRRD_counter > 0) begin
            tRRD_counter -= 1;
        end
        for (int i = 0; i < DRAM_PARAM_NUM_BANKS; i++) begin
            if (tRAS_counter[i] > 0) begin
                tRAS_counter[i] -= 1;
            end
            if (tRC_counter[i]  > 0) begin
                tRC_counter[i]  -= 1;
            end
        end
    end

    always @(posedge itf.clk iff !itf.rst) begin
        if ($isunknown(itf.read)) begin
            $error("Memory Error: read is 1'bx");
            itf.error <= 1'b1;
        end
        if ($isunknown(itf.write)) begin
            $error("Memory Error: write is 1'bx");
            itf.error <= 1'b1;
        end
        if (itf.read && itf.write) begin
            $error("Memory Error: Simultaneous read and write");
            itf.error <= 1'b1;
        end
        if (itf.read || itf.write) begin
            if ($isunknown(itf.addr)) begin
                $error("Memory Error: address contains 'x");
                itf.error <= 1'b1;
            end
            if (get_offset(itf.addr) != '0) begin
                $error("Memory Error: address not aligned");
                itf.error <= 1'b1;
            end
        end
    end

    always @(posedge itf.clk iff !itf.rst) begin
        automatic in_queue_t in_request;
        if ((itf.read || itf.write) && itf.ready) begin
            if (itf.write) begin
                in_request.wdata[0 +: DRAM_PARAM_BUS_WIDTH] = itf.wdata;
                for (int j = 1; j < DRAM_PARAM_BURST_LEN; j++) begin
                    @(posedge itf.clk iff itf.ready);
                    in_request.wdata[j*DRAM_PARAM_BUS_WIDTH +: DRAM_PARAM_BUS_WIDTH] = itf.wdata;
                end
            end else begin
                in_request.wdata = 'x;
            end
            in_request.addr = itf.addr;
            in_request.read = itf.read;
            in_queue.push_front(in_request);
        end
    end

    always @(posedge itf.clk iff !itf.rst) begin
        if (in_queue.size() < DRAM_PARAM_QUEUE_SIZE) begin
            itf.ready <= 1'b1;
        end else begin
            itf.ready <= 1'b0;
        end
    end

    generate for (genvar bank = 0; bank < DRAM_PARAM_NUM_BANKS; bank++) begin : banks
        always @(posedge itf.clk iff !itf.rst) begin
            automatic in_queue_t request;
            automatic int request_index = -1;
            automatic out_queue_t result;
            automatic bit found = 1'b0;
            for (int i = 0; i < in_queue.size(); i++) begin
                if (int'(get_bank(in_queue[i].addr)) === bank) begin
                    if (!(found && (get_row(request.addr) === DRAM_PARAM_RA_WIDTH'(active_row[bank])) && (get_row(in_queue[i].addr) !== DRAM_PARAM_RA_WIDTH'(active_row[bank])))) begin
                        request = in_queue[i];
                        request_index = i;
                        found = 1'b1;
                    end
                end
            end
            if (found) begin
                in_queue.delete(request_index);
                if (request.read) begin
                    mem_delay(request.addr, 1'b1);
                    result.raddr = request.addr;
                    result.rdata = internal_memory_array[get_access(request.addr)];
                    result.read  = request.read;
                    if (DRAM_RETURN_0_ON_X) begin
                        for (int i = 0; i < DRAM_PARAM_ACCESS_WIDTH; i++) begin
                            if ($isunknown(result.rdata[i])) begin
                                result.rdata[i] = 1'b0;
                            end
                        end
                    end
                end else begin
                    mem_delay(request.addr, 1'b0);
                    internal_memory_array[get_access(request.addr)] = request.wdata;
                    result.raddr = request.addr;
                    result.rdata = 'x;
                    result.read  = request.read;
                end
                out_queue.push_front(result);
            end
        end
    end endgenerate

    always @(posedge itf.clk iff !itf.rst) begin
        automatic out_queue_t result;
        if (out_queue.size() > 0) begin
            result = out_queue.pop_back();
            if (result.read) begin
                itf.raddr <= result.raddr;
                for (int j = 0; j < DRAM_PARAM_BURST_LEN; j++) begin
                    itf.rvalid <= 1'b1;
                    itf.rdata <= result.rdata[j * DRAM_PARAM_BUS_WIDTH +: DRAM_PARAM_BUS_WIDTH];
                    @(posedge itf.clk);
                end
                itf.raddr <= 'x;
                itf.rdata <= 'x;
                itf.rvalid <= 1'b0;
            end
        end
    end

    task automatic mem_delay(logic [DRAM_PARAM_TOTAL_ADDR_WIDTH:0] addr, bit read_nwrite);
        begin
            // prechage
            if (active_row[get_bank(addr)] !== int'(get_row(addr)) && active_row[get_bank(addr)] >= 0) begin
                // waiting for active to precharge delay
                while (tRAS_counter[get_bank(addr)] != 0) begin
                    #1;
                end
                #(DRAM_TIMMING_tRP);
            end
            // active
            if (active_row[get_bank(addr)] !== int'(get_row(addr))) begin
                // waiting for active delay, both in bank and cross bank;
                while (tRRD_counter != 0 || tRC_counter[get_bank(addr)] != 0) begin
                    #1;
                end
                tRAS_counter[get_bank(addr)] = DRAM_TIMMING_tRAS;
                tRRD_counter = DRAM_TIMMING_tRRD;
                tRC_counter[get_bank(addr)] = DRAM_TIMMING_tRC;
                #(DRAM_TIMMING_tRCD);
                active_row[get_bank(addr)] = int'(get_row(addr));
            end
            // access column
            if (read_nwrite) begin
                #(DRAM_TIMMING_CL);
            end else begin
                #(DRAM_TIMMING_tWR);
            end
            @(posedge itf.clk);
        end
    endtask

endmodule
