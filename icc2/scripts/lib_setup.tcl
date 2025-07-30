lappend search_path "../saed32nm/lib/stdcell_lvt/ndm"

set TECH_FILE "../saed32nm/lib/tech/milkyway/saed32nm_1p9m_mw.tf"

set REFERENCE_LIBRARY "saed32lvt_c.ndm"

# Check if MYLIB exists or not, if yes, delete it forcefully
if {[file isdirectory "MYLIB"]} {
    puts "MYLIB library exists. Deleting it..."
    file delete -force "MYLIB"
    puts "MYLIB library has been deleted. Recreating MYLIB..."
} else {
    puts "MYLIB library does not exist. Proceed to library creation..."
}

# Create MYLIB library
create_lib MYLIB -technology $TECH_FILE -ref_libs $REFERENCE_LIBRARY

set np [exec grep processor /proc/cpuinfo | wc -l]
if {$np > 8} { set np 8 }
set_host_options -max_cores $np

# Supress the following message:
#   "Warning: Virtual clock 'v_XXX' cannot be made propagated. (UIC-025)"
#     (generated when remove_propagated_clocks is applied)
#
suppress_message UIC-025

# Suppress messages related to setting/getting the routing_direction attribute:
suppress_message "ATTR-11 ATTR-12"