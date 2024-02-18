module cpu
import rv32i_types::*;
(
    input   logic           clk,
    input   logic           rst,

    output  logic   [31:0]  imem_addr,
    output  logic   [3:0]   imem_rmask,
    input   logic   [31:0]  imem_rdata,
    input   logic           imem_resp,

    output  logic   [31:0]  dmem_addr,
    output  logic   [3:0]   dmem_rmask,
    output  logic   [3:0]   dmem_wmask,
    input   logic   [31:0]  dmem_rdata,
    output  logic   [31:0]  dmem_wdata,
    input   logic           dmem_resp
);

    if_id_stage_reg_t   curr_if_id_stage_reg, next_if_id_stage_reg;
    id_ex_stage_reg_t   curr_id_ex_stage_reg, next_id_ex_stage_reg;
    ex_mem_stage_reg_t  curr_ex_mem_stage_reg, next_ex_mem_stage_reg;
    mem_wb_stage_reg_t  curr_mem_wb_stage_reg, next_mem_wb_stage_reg;
    logic               forwarding_stall;
    logic [4:0]         wb_rd_s;
    logic [31:0]        wb_rd_v;
    logic               wb_regf_we;
    id_rs1_forward_sel_t         id_rs1_forward_sel;
    id_rs2_forward_sel_t         id_rs2_forward_sel;
    ex_rs1_forward_sel_t         ex_rs1_forward_sel;
    ex_rs2_forward_sel_t         ex_rs2_forward_sel;
    logic  [4:0]    id_rs1_s;
    logic  [4:0]    id_rs2_s;
    logic  branch_flush;
    logic  [31:0]  target_pc;

    logic branch_flush_delay;
    logic imem_rqst;
    logic dmem_rqst;
    logic move_pipeline;

    STALLFSM stallfsm(
        .clk(clk),
        .rst(rst),
        .imem_rqst(imem_rqst),
        .dmem_rqst(dmem_rqst),
        .imem_resp(imem_resp),
        .dmem_resp(dmem_resp),
        .move_pipeline(move_pipeline)
    ); 

    FLUSHFSM flushfsm(
        .clk(clk),
        .rst(rst),
        .branch_flush(branch_flush),
        .branch_flush_delay(branch_flush_delay),
        .move_pipeline(move_pipeline)
    );

    Forwarding forwarding(
        .id_rs1_s(id_rs1_s),
        .id_rs2_s(id_rs2_s),
        .id_ex_stage_reg(curr_id_ex_stage_reg),
        .ex_mem_stage_reg(curr_ex_mem_stage_reg),
        .mem_wb_stage_reg(curr_mem_wb_stage_reg),
        .forwarding_stall(forwarding_stall),
        .id_rs1_forward_sel(id_rs1_forward_sel),
        .id_rs2_forward_sel(id_rs2_forward_sel),
        .ex_rs1_forward_sel(ex_rs1_forward_sel),
        .ex_rs2_forward_sel(ex_rs2_forward_sel)
    );

    IF_Stage if_stage(
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_rmask(imem_rmask),
        .forwarding_stall(forwarding_stall),
        .if_id_stage_reg(next_if_id_stage_reg),
        .branch_flush(branch_flush),
        .target_pc(target_pc),
        .move_pipeline(move_pipeline),
        .imem_rqst(imem_rqst)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_if_id_stage_reg <= '0;
        end else if (~forwarding_stall) begin 
            if (move_pipeline) begin 
                curr_if_id_stage_reg <= next_if_id_stage_reg;
            end 
        end 
    end 

    ID_Stage id_stage(
        .clk(clk),
        .rst(rst),
        .if_id_stage_reg(curr_if_id_stage_reg),
        .id_ex_stage_reg(next_id_ex_stage_reg),
        .imem_resp(imem_resp),
        .imem_rdata(imem_rdata),
        .wb_rd_s(wb_rd_s),
        .wb_rd_v(wb_rd_v),
        .wb_regf_we(wb_regf_we),
        .forwarding_stall(forwarding_stall),
        .id_rs1_s(id_rs1_s),
        .id_rs2_s(id_rs2_s),
        .id_rs1_forward_sel(id_rs1_forward_sel),
        .id_rs2_forward_sel(id_rs2_forward_sel),
        .branch_flush(branch_flush),
        .move_pipeline(move_pipeline),
        .branch_flush_delay(branch_flush_delay)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_id_ex_stage_reg <= '0;
        end else if (move_pipeline) begin 
            curr_id_ex_stage_reg <= next_id_ex_stage_reg;
        end 
    end

    EX_Stage ex_stage(
        .id_ex_stage_reg(curr_id_ex_stage_reg),
        .ex_mem_stage_reg(next_ex_mem_stage_reg),
        .ex_mem_stage_reg_curr(curr_ex_mem_stage_reg),
        .wb_rd_v(wb_rd_v),
        .ex_rs1_forward_sel(ex_rs1_forward_sel),
        .ex_rs2_forward_sel(ex_rs2_forward_sel),
        .branch_flush(branch_flush),
        .target_pc(target_pc)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_ex_mem_stage_reg <= '0;
        end else if (move_pipeline) begin 
            curr_ex_mem_stage_reg <= next_ex_mem_stage_reg;
        end 
    end

    MEM_Stage mem_stage(
        .dmem_addr(dmem_addr),
        .dmem_rmask(dmem_rmask),
        .dmem_wmask(dmem_wmask),
        .dmem_wdata(dmem_wdata),
        .ex_mem_stage_reg(curr_ex_mem_stage_reg),
        .mem_wb_stage_reg(next_mem_wb_stage_reg),
        .dmem_rqst(dmem_rqst),
        .move_pipeline(move_pipeline)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_mem_wb_stage_reg <= '0;
        end else if (move_pipeline) begin 
            curr_mem_wb_stage_reg <= next_mem_wb_stage_reg;
        end 
    end

    WB_Stage wb_stage(
        .clk(clk),
        .rst(rst),
        .mem_wb_stage_reg(curr_mem_wb_stage_reg),
        .dmem_resp(dmem_resp),
        .dmem_rdata(dmem_rdata),
        .wb_rd_s(wb_rd_s),
        .wb_rd_v(wb_rd_v),
        .wb_regf_we(wb_regf_we),
        .move_pipeline(move_pipeline)
    );


endmodule : cpu
