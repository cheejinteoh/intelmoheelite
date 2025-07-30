set LIB_ROOT ../saed32nm/lib

set LVT_LIB "saed32lvt_ss0p95v125c.db"

set search_path "$search_path . \
                 $LIB_ROOT/stdcell_lvt/db_nldm \
		         ./scripts"
set_app_var target_library "$LVT_LIB"
set_app_var link_library "* $target_library"
set_app_var link_path "* $target_library"

set mw_design_library MY_MW_LIB
set mw_reference_library "$LIB_ROOT/stdcell_lvt/milkyway/saed32nm_lvt_1p9m"