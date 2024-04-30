read_file -type verilog $env(PKG_SRCS) $env(HDL_SRCS)
read_file -type gateslibdb $env(SRAM_LIB)
read_file -type awl lint.awl

set_option top cache
set_option enable_gateslib_autocompile yes
set_option language_mode verilog
set_option enableSV09 yes
set_option enable_save_restore no

current_goal Design_Read -top cache

current_goal lint/lint_turbo_rtl -top cache

set_parameter checkfullstruct true

run_goal

# help -rules STARC05-2.11.3.1
