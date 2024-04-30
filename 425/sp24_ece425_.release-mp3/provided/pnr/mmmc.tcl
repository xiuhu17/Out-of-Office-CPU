create_constraint_mode -name constraint_default -sdc_files ../synth/outputs/$design_toplevel.sdc

create_library_set -name typLib -timing ../stdcells.lib
create_delay_corner -name typDC -library_set typLib
create_analysis_view -name typView -constraint_mode constraint_default -delay_corner typDC

set_analysis_view -setup {typView} -hold {typView}
