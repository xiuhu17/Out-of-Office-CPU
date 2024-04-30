set symbol_library [list generic.sdb]
set synthetic_library [list dw_foundation.sldb]
set target_library [getenv STD_CELL_LIB]
set link_library   [list "*" $target_library $synthetic_library]

read_file -format ddc outputs/synth.ddc
