create_clock -period [expr [getenv ECE411_CLOCK_PERIOD_PS] / 1000.0] -name my_clk clk
set_fix_hold [get_clocks my_clk]

set_input_delay  1.8 [get_ports ufp_addr]  -clock my_clk
set_input_delay  1.8 [get_ports ufp_rmask] -clock my_clk
set_input_delay  1.8 [get_ports ufp_wmask] -clock my_clk
set_input_delay  1.8 [get_ports ufp_wdata] -clock my_clk
set_output_delay 0.5 [get_ports ufp_rdata] -clock my_clk
set_output_delay 0.5 [get_ports ufp_resp]  -clock my_clk

set_input_delay 1.5  [get_ports dfp_rdata] -clock my_clk
set_input_delay 1.5  [get_ports dfp_resp]  -clock my_clk
set_output_delay 0.2 [get_ports dfp_addr]  -clock my_clk
set_output_delay 0.2 [get_ports dfp_read]  -clock my_clk
set_output_delay 0.2 [get_ports dfp_write] -clock my_clk
set_output_delay 0.2 [get_ports dfp_wdata] -clock my_clk

set_load 0.1 [all_outputs]
set_max_fanout 1 [all_inputs]
set_fanout_load 8 [all_outputs]
