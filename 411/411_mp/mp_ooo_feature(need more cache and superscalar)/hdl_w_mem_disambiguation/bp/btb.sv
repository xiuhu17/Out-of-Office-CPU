module btb
  import rv32i_types::*;
#(
    parameter BTB_DEPTH = 3
) (
    input logic clk,
    input logic rst,

    // update; only use [31:2] bit as index
    input logic rob_pop,
    input logic take_branch,
    input logic [6:0] commit_opcode,
    input logic [31:0] commit_pc,
    input logic [31:0] commit_pc_next,

    // fetch stage, current pc
    input logic gshare_take,
    input logic [31:0] fetch_pc,
    output logic [31:0] fetch_pc_next
);

  localparam BTB_NUM_ELEMENT = 2 ** BTB_DEPTH;

  // for store the lookup table
  logic br_valid_arr[BTB_NUM_ELEMENT];
  logic [31:0] br_pc_arr[BTB_NUM_ELEMENT];
  logic [31:0] br_target_pc_arr[BTB_NUM_ELEMENT];
  logic j_valid_arr[BTB_NUM_ELEMENT];
  logic [31:0] j_pc_arr[BTB_NUM_ELEMENT];
  logic [31:0] j_target_pc_arr[BTB_NUM_ELEMENT];


  // counter: no insert, no update 
  // insert: insert an invalid slot 
  // update: update the target pc
  logic br_update;
  logic br_insert;
  logic [BTB_DEPTH-1:0] br_update_index;
  logic [BTB_DEPTH-1:0] br_insert_index;
  logic [BTB_DEPTH-1:0] br_counter;

  logic j_update;
  logic j_insert;
  logic [BTB_DEPTH-1:0] j_update_index;
  logic [BTB_DEPTH-1:0] j_insert_index;
  logic [BTB_DEPTH-1:0] j_counter;

  always_ff @(posedge clk) begin
    if (rst) begin
      br_counter <= '0;
      j_counter  <= '0;
      for (int i = 0; i < BTB_NUM_ELEMENT; i++) begin
        br_valid_arr[i] <= '0;
        br_pc_arr[i] <= '0;
        br_target_pc_arr[i] <= '0;
        j_valid_arr[i] <= '0;
        j_pc_arr[i] <= '0;
        j_target_pc_arr[i] <= '0;
      end
    end else begin
      if (rob_pop && take_branch) begin
        if (commit_opcode == br_opcode) begin
          if (br_update) begin
            br_pc_arr[br_update_index] <= commit_pc;
            br_target_pc_arr[br_update_index] <= commit_pc_next;
          end else if (br_insert) begin
            br_valid_arr[br_insert_index] <= '1;
            br_pc_arr[br_insert_index] <= commit_pc;
            br_target_pc_arr[br_insert_index] <= commit_pc_next;
          end else begin
            br_pc_arr[br_counter] <= commit_pc;
            br_target_pc_arr[br_counter] <= commit_pc_next;
            br_counter <= br_counter + 1'b1;
          end
        end else begin
          if (j_update) begin
            j_pc_arr[j_update_index] <= commit_pc;
            j_target_pc_arr[j_update_index] <= commit_pc_next;
          end else if (j_insert) begin
            j_valid_arr[j_insert_index] <= '1;
            j_pc_arr[j_insert_index] <= commit_pc;
            j_target_pc_arr[j_insert_index] <= commit_pc_next;
          end else begin
            j_pc_arr[j_counter] <= commit_pc;
            j_target_pc_arr[j_counter] <= commit_pc_next;
            j_counter <= j_counter + 1'b1;
          end
        end
      end
    end
  end

  always_comb begin
    br_update = '0;
    br_insert = '0;
    br_update_index = '0;
    br_insert_index = '0;
    j_update = '0;
    j_insert = '0;
    j_update_index = '0;
    j_insert_index = '0;

    if (commit_opcode == br_opcode || commit_opcode == jal_opcode || commit_opcode == jalr_opcode) begin
      for (int unsigned i = 0; i < BTB_NUM_ELEMENT; i++) begin
        if (commit_opcode == br_opcode) begin
          if (br_valid_arr[i] && (br_pc_arr[i] == commit_pc)) begin
            br_update = '1;
            br_update_index = (BTB_DEPTH)'(i);
          end
          if (!br_valid_arr[i]) begin
            br_insert = '1;
            br_insert_index = (BTB_DEPTH)'(i);
          end
        end else begin
          if (j_valid_arr[i] && (j_pc_arr[i] == commit_pc)) begin
            j_update = '1;
            j_update_index = (BTB_DEPTH)'(i);
          end
          if (!j_valid_arr[i]) begin
            j_insert = '1;
            j_insert_index = (BTB_DEPTH)'(i);
          end
        end
      end
    end
  end

  // for output
  always_comb begin
    fetch_pc_next = fetch_pc + 32'h4;
    for (int i = 0; i < BTB_NUM_ELEMENT; i++) begin
      if (gshare_take && br_valid_arr[i] && (br_pc_arr[i] == fetch_pc)) begin
        fetch_pc_next = br_target_pc_arr[i];
        break;
      end
      if (j_valid_arr[i] && (j_pc_arr[i] == fetch_pc)) begin
        fetch_pc_next = j_target_pc_arr[i];
        break;
      end
    end
  end
endmodule
