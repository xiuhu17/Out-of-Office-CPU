module cpu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,
    output  logic   [31:0]  mem_addr,
    output  logic           mem_read,
    output  logic           mem_write,
    output  logic   [3:0]   mem_wmask,
    input   logic   [31:0]  mem_rdata,
    output  logic   [31:0]  mem_wdata,
    input   logic           mem_resp
);

    enum int unsigned {
        s_halt, s_reset, s_fetch, s_decode,
        s_lui, s_aupic, s_jal, s_jalr, s_br,
        s_load, s_store, s_ri, s_rr
    } state, state_next;

            logic   [63:0]  order;

            logic           commit;
            logic   [31:0]  pc;
            logic   [31:0]  pc_next;

            logic           load_ir;
            logic   [31:0]  inst;
            logic   [2:0]   funct3;
            logic   [6:0]   funct7;
            logic   [6:0]   opcode;
            logic   [31:0]  i_imm;
            logic   [31:0]  s_imm;
            logic   [31:0]  b_imm;
            logic   [31:0]  u_imm;
            logic   [31:0]  j_imm;
            logic   [4:0]   rs1_s;
            logic   [4:0]   rs2_s;
            logic   [4:0]   rd_s;

            logic           regf_we;
            logic   [31:0]  rs1_v;
            logic   [31:0]  rs2_v;
            logic   [31:0]  rd_v;

            logic   [31:0]  a;
            logic   [31:0]  b;

            logic   [2:0]   aluop;
            logic   [2:0]   cmpop;

            logic   [31:0]  aluout;
            logic           br_en;

            logic   [3:0]   mem_rmask;

    ir ir (
        .in(mem_rdata),
        .out(inst),
        .*
    );

    regfile regfile(
        .*
    );

    alu alu(
        .f(aluout),
        .*
    );

    cmp cmp(
        .*
    );

    always_ff @( posedge clk ) begin
        if (rst) begin
            state <= s_reset;
            pc <= 32'h40000000;
            order <= '0;
        end else begin
            state <= state_next;
            pc <= pc_next;
            if (commit) begin
                order <= order + 'd1;
            end
        end
    end

    always_comb begin
        state_next = state;
        commit = 1'b0;
        pc_next = pc;
        mem_addr = 'x;
        mem_read = 1'b0;
        mem_write = 1'b0;
        mem_wmask = '0;
        mem_rmask = '0;
        mem_wdata = 'x;
        rd_v = 'x;
        load_ir = 1'b0;
        regf_we = 1'b0;
        a = 'x;
        b = 'x;
        aluop = 'x;
        cmpop = 'x;
        unique case (state)
            s_halt: begin
                pc_next = pc;
                commit = 1'b1;
            end
            s_reset: begin
                state_next = s_fetch;
            end
            s_fetch: begin
                mem_addr = pc;
                mem_read = 1'b1;
                if (mem_resp) begin
                   load_ir = 1'b1;
                   state_next = s_decode;
                end
            end
            s_decode: begin
                unique case (opcode)
                    op_lui   : state_next = s_lui;
                    op_auipc : state_next = s_aupic;
                    op_jal   : state_next = s_jal;
                    op_jalr  : state_next = s_jalr;
                    op_br    : state_next = s_br;
                    op_load  : state_next = s_load;
                    op_store : state_next = s_store;
                    op_imm   : state_next = s_ri;
                    op_reg   : state_next = s_rr;
                    default  : state_next = s_halt;
                endcase
            end
            s_lui: begin
                rd_v = u_imm;
                regf_we = 1'b1;
                pc_next = pc + 'd4;
                commit = 1'b1;
                state_next = s_fetch;
            end
            s_aupic: begin
                rd_v = pc + u_imm;
                regf_we = 1'b1;
                pc_next = pc + 'd4;
                commit = 1'b1;
                state_next = s_fetch;
            end
            s_jal: begin
                rd_v = pc + 'd4;
                regf_we = 1'b1;
                pc_next = pc + j_imm;
                commit = 1'b1;
                state_next = s_fetch;
            end
            s_jalr: begin
                rd_v = pc + 'd4;
                regf_we = 1'b1;
                pc_next = (rs1_v + i_imm) & 32'hfffffffe;
                commit = 1'b1;
                state_next = s_fetch;
            end
            s_br: begin
                cmpop = funct3;
                a = rs1_v;
                b = rs2_v;
                if (br_en) begin
                    pc_next = pc + b_imm;
                end else begin
                    pc_next = pc + 'd4;
                end
                commit = 1'b1;
                state_next = s_fetch;
            end
            s_load: begin
                mem_addr = i_imm + rs1_v;
                mem_read = 1'b1;
                unique case (funct3)
                    lb, lbu: mem_rmask = 4'b0001 << mem_addr[1:0];
                    lh, lhu: mem_rmask = 4'b0011 << mem_addr[1:0];
                    lw:      mem_rmask = 4'b1111;
                    default: mem_rmask = 'x;
                endcase
                if (mem_resp) begin
                    regf_we = 1'b1;
                    unique case (funct3)
                        lb : rd_v = {{24{mem_rdata[7 +8 *mem_addr[1:0]]}}, mem_rdata[8 *mem_addr[1:0] +: 8 ]};
                        lbu: rd_v = {{24{1'b0}}                          , mem_rdata[8 *mem_addr[1:0] +: 8 ]};
                        lh : rd_v = {{16{mem_rdata[15+16*mem_addr[1]  ]}}, mem_rdata[16*mem_addr[1]   +: 16]};
                        lhu: rd_v = {{16{1'b0}}                          , mem_rdata[16*mem_addr[1]   +: 16]};
                        lw : rd_v = mem_rdata;
                        default: rd_v = 'x;
                    endcase
                    pc_next = pc + 'd4;
                    commit = 1'b1;
                    state_next = s_fetch;
                end
            end
            s_store: begin
                mem_addr = rs1_v + s_imm;
                mem_write = 1'b1;
                unique case (funct3)
                    sb: mem_wmask = 4'b0001 << mem_addr[1:0];
                    sh: mem_wmask = 4'b0011 << mem_addr[1:0];
                    sw: mem_wmask = 4'b1111;
                    default: mem_wmask = 'x;
                endcase
                unique case (funct3)
                    sb: mem_wdata[8 *mem_addr[1:0] +: 8 ] = rs2_v[7 :0];
                    sh: mem_wdata[16*mem_addr[1]   +: 16] = rs2_v[15:0];
                    sw: mem_wdata = rs2_v;
                    default: mem_wdata = 'x;
                endcase
                if (mem_resp) begin
                    pc_next = pc + 'd4;
                    commit = 1'b1;
                    state_next = s_fetch;
                end
            end
            s_ri: begin
                a = rs1_v;
                b = i_imm;
                unique case (funct3)
                    slt: begin
                        cmpop = blt;
                        rd_v = {31'd0, br_en};
                    end
                    sltu: begin
                        cmpop = bltu;
                        rd_v = {31'd0, br_en};
                    end
                    sr: begin
                        if (funct7[5]) begin
                            aluop = alu_sra;
                        end else begin
                            aluop = alu_srl;
                        end
                        rd_v = aluout;
                    end
                    default: begin
                        aluop = funct3;
                        rd_v = aluout;
                    end
                endcase
                regf_we = 1'b1;
                pc_next = pc + 'd4;
                commit = 1'b1;
                state_next = s_fetch;
            end
            s_rr: begin
                a = rs1_v;
                b = rs2_v;
                unique case (funct3)
                    slt: begin
                        cmpop = blt;
                        rd_v = {31'd0, br_en};
                    end
                    sltu: begin
                        cmpop = bltu;
                        rd_v = {31'd0, br_en};
                    end
                    sr: begin
                        if (funct7[5]) begin
                            aluop = alu_sra;
                        end else begin
                            aluop = alu_srl;
                        end
                        rd_v = aluout;
                    end
                    add: begin
                        if (funct7[5]) begin
                            aluop = alu_sub;
                        end else begin
                            aluop = alu_add;
                        end
                        rd_v = aluout;
                    end
                    default: begin
                        aluop = funct3;
                        rd_v = aluout;
                    end
                endcase
                regf_we = 1'b1;
                pc_next = pc + 'd4;
                commit = 1'b1;
                state_next = s_fetch;
            end
            default: begin
                state_next = s_halt;
            end
        endcase
    end

            logic           monitor_valid;
            logic   [63:0]  monitor_order;
            logic   [31:0]  monitor_inst;
            logic   [4:0]   monitor_rs1_addr;
            logic   [4:0]   monitor_rs2_addr;
            logic   [31:0]  monitor_rs1_rdata;
            logic   [31:0]  monitor_rs2_rdata;
            logic           monitor_regf_we;
            logic   [4:0]   monitor_rd_addr;
            logic   [31:0]  monitor_rd_wdata;
            logic   [31:0]  monitor_pc_rdata;
            logic   [31:0]  monitor_pc_wdata;
            logic   [31:0]  monitor_mem_addr;
            logic   [3:0]   monitor_mem_rmask;
            logic   [3:0]   monitor_mem_wmask;
            logic   [31:0]  monitor_mem_rdata;
            logic   [31:0]  monitor_mem_wdata;

    // Fill this out
    assign monitor_valid     = commit;
    assign monitor_order     = order;
    assign monitor_inst      = inst;
    assign monitor_rs1_addr  = rs1_s;
    assign monitor_rs2_addr  = rs2_s;
    assign monitor_rs1_rdata = rs1_v;
    assign monitor_rs2_rdata = rs2_v;
    assign monitor_rd_addr   = regf_we ? rd_s : 5'd0;
    assign monitor_rd_wdata  = rd_v;
    assign monitor_pc_rdata  = pc;
    assign monitor_pc_wdata  = pc_next;
    assign monitor_mem_addr  = mem_addr;
    assign monitor_mem_rmask = mem_rmask;
    assign monitor_mem_wmask = mem_wmask;
    assign monitor_mem_rdata = mem_rdata;
    assign monitor_mem_wdata = mem_wdata;

endmodule : cpu