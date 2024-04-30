# You requested %d cores. However, load on host %s is %0.2y
suppress_message UIO-231

if {[getenv ECE411_MIN_POWER] eq "1"} {
   set power_enable_minpower true
}
set hdlin_ff_always_sync_set_reset true
set hdlin_ff_always_async_set_reset true
set hdlin_infer_multibit default_all
set hdlin_check_no_latch true
set hdlin_while_loop_iterations 2000000000
set_host_options -max_cores 4
set_app_var report_default_significant_digits 6
set design_toplevel cpu

# output port '%s' is connected directly to output port '%s'
suppress_message LINT-31
# In design '%s', output port '%s' is connected directly to '%s'.
suppress_message LINT-52
# '%s' is not connected to any nets
suppress_message LINT-28
# output port '%s' is connected directly to output port '%s'
suppress_message LINT-29
# a pin on submodule '%s' is connected to logic 1 or logic 0
suppress_message LINT-32
# the same net is connected to more than one pin on submodule '%s'
suppress_message LINT-33
# '%s' is not connected to any nets
suppress_message LINT-28
# In design '%s', cell '%s' does not drive any nets.
suppress_message LINT-1
# There are %d potential problems in your design. Please run 'check_design' for more information.
suppress_message LINT-99
# In design '%s', net '%s' driven by pin '%s' has no loads.
suppress_message LINT-2
# The register '' is a constant and will be removed.
suppress_message OPT-1206
# The register '' will be removed.
suppress_message OPT-1207
# Can't read link_library file '%s'
suppress_message UID-3
# Design '%s' contains %d high-fanout nets.
suppress_message TIM-134
# The trip points for the library named %s differ from those in the library named %s.
suppress_message TIM-164
# Design has unannotated black box outputs.
suppress_message PWR-428
# Skipping clock gating on design %s, since there are no registers.
suppress_message PWR-806
# Ungrouping hierarchy %s before Pass 1.
suppress_message OPT-776
# Changed wire name %s to %s in module %s.
suppress_message VO-2
# Verilog 'assign' or 'tran' statements are written out.
suppress_message VO-4
# Verilog writer has added %d nets to module %s using %s as prefix.
suppress_message VO-11
# In the design %s,net '%s' is connecting multiple ports.
suppress_message UCN-1
# The replacement character (%c) is conflicting with the allowed or restricted character.
suppress_message UCN-4
# Design '%s' was renamed to '%s' to avoid a conflict with another design that has the same name but different parameters.
suppress_message LINK-17

# There are buffer or inverter cells in the clock tree. The clock tree has to be recreated after retiming.
suppress_message RTDC-47
# The design contains the following cellswhich have no influence on the design's function but cannot be removed (e.g. becauseadont_touchattributehas been setset on them). Retiming will ignore these cells in order toachieve good results: %s
suppress_message RTDC-60
# The following cells only drive asynchronous pins of sequential cells which have no timing  constraint.  Therefore  retiming will not optimize delay through them
suppress_message RTDC-115
# Unable  to  maintain nets '%s' and '%s' as separate entities.
suppress_message OPT-153
# The unannotated net '%s' is driven by a primary input port.
suppress_message PWR-429
# The unannotated net '%s' is driven by a black box output.
suppress_message PWR-416
# %s SV Assertions are ignored for synthesis since %s is not set to true.
suppress_message ELAB-33

# %s DEFAULT branch of CASE statement cannot be reached.
suppress_message ELAB-311
# Netlist for always_ff block does not contain a flip-flop.
suppress_message ELAB-976
# Netlist for always_comb block is empty.
suppress_message ELAB-982
# Netlist for always_ff block is empty.
suppress_message ELAB-984
# Netlist for always block is empty.
suppress_message ELAB-985

define_design_lib WORK -path ./work
set alib_library_analysis_path [getenv STD_CELL_ALIB]

set symbol_library [list generic.sdb]
set synthetic_library [list dw_foundation.sldb]
set target_library [getenv STD_CELL_LIB]
set sram_library [getenv SRAM_LIB]

if {$sram_library eq ""} {
   set link_library [list "*" $target_library $synthetic_library]
} else {
   set link_library [list "*" $target_library $synthetic_library $sram_library]
}

set design_clock_pin clk
set design_reset_pin rst

analyze -library WORK -format sverilog [getenv PKG_SRCS]

set modules [split [getenv HDL_SRCS] " "]
foreach module $modules {
   analyze -library WORK -format sverilog "${module}"
}

elaborate $design_toplevel
current_design $design_toplevel

change_names -rules verilog -hierarchy

check_design

set_wire_load_model -name "5K_hvratio_1_1"
set_wire_load_mode enclosed

set clk_name $design_clock_pin
set clk_period [expr [getenv ECE411_CLOCK_PERIOD_PS] / 1000.0]
create_clock -period $clk_period -name my_clk $clk_name
set_fix_hold [get_clocks my_clk]

set_input_delay 0.5 [all_inputs] -clock my_clk
set_output_delay 0.5 [all_outputs] -clock my_clk
set_load 0.1 [all_outputs]
set_max_fanout 1 [all_inputs]
set_fanout_load 8 [all_outputs]

link

eval [getenv ECE411_COMPILE_CMD]

current_design $design_toplevel

report_area -hier > reports/area.rpt
report_timing -delay max > reports/timing.rpt
check_design > reports/check.rpt

write_file -format ddc -hierarchy -output outputs/synth.ddc
write_file -format verilog -hierarchy -output [format "outputs/%s.gate.v" $design_toplevel]

exit
