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
    output  logic   [31:0]  dmem_wdata
);


    if_id_stage_reg_t  curr_if_id_stage_reg, next_if_id_stage_reg;
    id_ex_stage_reg_t  curr_id_ex_stage_reg, next_id_ex_stage_reg;
    ex_mem_stage_reg_t curr_ex_mem_stage_reg, next_ex_mem_stage_reg;
    mem_wb_stage_reg_t curr_mem_wb_stage_reg, next_mem_wb_stage_reg;
    logic              not_stall;
    assign             not_stall = 1'b1;
    logic [4:0]     wb_rd_s;
    logic [31:0]    wb_rd_v;
    logic           wb_regf_we;

    IF_Stage if_stage(
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_rmask(imem_rmask),
        .imem_rdata(imem_rdata),
        .imem_resp(imem_resp),
        .pc_en(not_stall),
        .if_id_stage_reg(next_if_id_stage_reg)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_if_id_stage_reg <= '0;
        end else if (not_stall) begin 
            curr_if_id_stage_reg <= next_if_id_stage_reg;
        end 
    end 

    ID_Stage id_stage(
        .clk(clk),
        .rst(rst),
        .if_id_stage_reg(curr_if_id_stage_reg),
        .id_ex_stage_reg(next_id_ex_stage_reg),
        .wb_rd_s(wb_rd_s),
        .wb_rd_v(wb_rd_v),
        .wb_regf_we(wb_regf_we)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_id_ex_stage_reg <= '0;
        end else begin 
            curr_id_ex_stage_reg <= next_id_ex_stage_reg;
        end 
    end

    EX_Stage ex_stage(
        .id_ex_stage_reg(curr_id_ex_stage_reg),
        .ex_mem_stage_reg(next_ex_mem_stage_reg)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_ex_mem_stage_reg <= '0;
        end else begin 
            curr_ex_mem_stage_reg <= next_ex_mem_stage_reg;
        end 
    end

    MEM_Stage mem_stage(
        .dmem_addr(dmem_addr),
        .dmem_rmask(dmem_rmask),
        .dmem_wmask(dmem_wmask),
        .dmem_rdata(dmem_rdata),
        .dmem_wdata(dmem_wdata),
        .ex_mem_stage_reg(curr_ex_mem_stage_reg),
        .mem_wb_stage_reg(next_mem_wb_stage_reg)
    );

    always_ff @ (posedge clk ) begin 
        if (rst) begin 
            curr_mem_wb_stage_reg <= '0;
        end else begin 
            curr_mem_wb_stage_reg <= next_mem_wb_stage_reg;
        end 
    end

    WB_Stage wb_stage(
        .mem_wb_stage_reg(curr_mem_wb_stage_reg),
        .wb_rd_s(wb_rd_s),
        .wb_rd_v(wb_rd_v),
        .wb_regf_we(wb_regf_we)
    );


endmodule : cpu
