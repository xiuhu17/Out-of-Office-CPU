final begin
  if (cg_inst.get_coverage != 100.0) begin
    display_colored("[FAILED] testbench coverage", "red");
  end else begin
    display_colored("[PASSED] testbench coverage", "green");
  end
end
