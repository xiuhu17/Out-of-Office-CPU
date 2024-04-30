# set the top level module name (used elsewhere in the scripts)
set design_toplevel control

# tell DC to put temp file in a sub folder
define_design_lib WORK -path ./work

# creating variables that point to the required libraries
set symbol_library [list generic.sdb]
set synthetic_library [list dw_foundation.sldb]
# the standard cell library, environment variable is set inside the Makefile
set target_library [getenv STD_CELL_LIB]

# actual variable that lists all of the libraries
# when you add your regfile lib, it will need to be added here
set link_library [list "*" $target_library $synthetic_library]

# telling DC what is clock and reset
set design_clock_pin clk
set design_reset_pin rst

# analyzing all the Verilog files
set modules [split [getenv HDL_SRCS] " "]
foreach module $modules {
   analyze -library WORK -format sverilog "${module}"
}

# elaborating the design
elaborate $design_toplevel

current_design $design_toplevel
link

# compiling the design
compile

current_design $design_toplevel

# write the DC save file so DV can open it later
write_file -format ddc -hierarchy -output outputs/synth.ddc

# writing out the netlist for pnr
write_file -format verilog -hierarchy -output [format "outputs/%s.v" $design_toplevel]

# writing out the sdc file, used for timing information
# in this class this file will be empty
# in reality, this will contain actual contraints created eariler in this script
write_sdc [format "outputs/%s.sdc" $design_toplevel]
