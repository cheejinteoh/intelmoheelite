######################################################################
#        Note: Must Run this tcl at assignment/icc2 Directory        #
######################################################################

################################
#        Setup for ICC2        #
################################
source -echo -verbose ./scripts/lib_setup.tcl
lappend search_path "../saed32nm/lib/tech/star_rc"

printvar search_path
printvar REFERENCE_LIBRARY
report_host_options
print_suppressed_messages

##########################################
#        Read the Netlist from DC        #
##########################################
# netlist
read_verilog {../output/dc/MYTOP.v}
# link_block (auto done by ICC2)#

# read in timing constraints generated in DC
read_sdc {../output/dc/MYTOP.sdc}

list_blocks
current_block

# Save block
rename_block -to_block MYTOP/init_design
save_block

#################################################
#       Set Significant Figures for Reports		#
#################################################
set_app_var report_default_significant_digits 5
printvar report_default_significant_digits

#######################################################################
#        RC Parasitics, Placement Site and Routing Layer Setup        #
#######################################################################
# read in files for parasitics
read_parasitic_tech \
-layermap saed32nm_tf_itf_tluplus.map \
-tlup saed32nm_1p9m_Cmax.tluplus \
-name maxTLU

read_parasitic_tech \
-layermap saed32nm_tf_itf_tluplus.map \
-tlup saed32nm_1p9m_Cmin.tluplus \
-name minTLU

# Specify TLUplus module for the corner
# set_parasitic_parameters -corner default -early_spec maxTLU -late_spec maxTLU
# set_parasitic_parameters -corner default -early_spec minTLU -late_spec minTLU
set_parasitic_parameters -corner default -early_spec minTLU -late_spec maxTLU
# set_parasitic_parameters -corner default -early_spec maxTLU -late_spec minTLU

redirect -tee -file ../reports/icc2/lib_parasitic_tech.rpt {report_lib -parasitic_tech [current_lib]}

# Save block
rename_block -to_block MYTOP/pg_design
save_block

##############################
#        Floorplaning        #
##############################
#initialize floorplan
initialize_floorplan -side_ratio {1 1} -core_offset {20}

# Define voltage
set_voltage 0.95 -object_list VDD
set_voltage 0.00 -object_list VSS

# Define metal routing direction
set_attribute [get_site_defs unit] symmetry Y
get_attribute [get_site_defs unit] is_default
set_attribute [get_layers {M1 M3 M5 M7 M9}] routing_direction horizontal
set_attribute [get_layers {M2 M4 M6 M8}] routing_direction vertical

# Max routing layer M6 (tested to have better performance compared to M8/M9)
set_ignored_layers -max_routing_layer M6
report_ignored_layers

# Place I/O pins
set_block_pin_constraints -self -allowed_layers {M3 M4 M5 M6}
place_pins -self

# Source file to create PG mesh
# Remove previous PG mesh (if any)
remove_pg_strategies -all
remove_pg_patterns -all
remove_pg_regions -all
remove_pg_via_master_rules -all
remove_pg_strategy_via_rules -all
remove_routes -net_types {power ground} -ring -stripe -macro_pin_connect -lib_cell_pin_connect > /dev/null

connect_pg_net

# Improve performance using via
set_pg_via_master_rule pgvia_8x10 -via_array_dimension {8 10}

################################################################################
# Build the main power mesh.  Consisting of:
# * a coarse mesh on M7/M8
# * a finer mesh on M2 - vertical only - to connect to the std cell rails
#

# From the tf file:
# width M7/M8: pitch=1.216, min_spacing=0.056, min_width=0.056; M7: 2*1.216 - 4*0.056
create_pg_mesh_pattern P_top_two \
	-layers { \
		{ {horizontal_layer: M7} {width: 1.104} {spacing: interleaving} {pitch: 13.376} {offset: 0.856} {trim : true} } \
		{ {vertical_layer: M8}   {width: 4.64 } {spacing: interleaving} {pitch: 19.456} {offset: 6.08}  {trim : true} } \
		} \
	-via_rule { {intersection: adjacent} {via_master : pgvia_8x10} }

# M2 pitch=0.152; 0.152*48=7.296
create_pg_mesh_pattern P_m2_triple \
	-layers { \
		{ {vertical_layer: M2}  {track_alignment : track} {width: 0.44 0.192 0.192} {spacing: 2.724 3.456} {pitch: 9.728} {offset: 1.216} {trim : true} } \
		}

# To solve the open net for VDD and VSS
# --> top mesh - M7/M8
set_pg_strategy S_default_vddvss \
	-core \
	-pattern   { {name: P_top_two} {nets:{VSS VDD}} {offset_start: {20 20}} } \
	-extension { {{stop:design_boundary_and_generate_pin}} }

# --> bottom mesh - M2
set_pg_strategy S_m2_vddvss \
	-core \
	-pattern   { {name: P_m2_triple} {nets: {VDD VSS VSS}} {offset_start: {20 0}} } \
	-extension { {{direction:BT} {stop:design_boundary_and_generate_pin}} }

compile_pg -strategies {S_default_vddvss S_m2_vddvss} 

################################################################################
# Build the standard cell rails

create_pg_std_cell_conn_pattern P_std_cell_rail

set_pg_strategy S_std_cell_rail_VSS_VDD \
	-core \
	-pattern {{pattern: P_std_cell_rail}{nets: {VSS VDD}}} \
	-extension {{stop: outermost_ring}{direction: L B R T }}

set_pg_strategy_via_rule S_via_stdcellrail \
        -via_rule {{intersection: adjacent}{via_master: default}}

compile_pg -strategies {S_std_cell_rail_VSS_VDD S_std_cell_rail_VDDH} -via_rule {S_via_stdcellrail}

# For this design, macro is not applicable
check_pg_missing_vias
check_pg_drc -ignore_std_cells
check_pg_connectivity -check_std_cell_pins none

# create_pg_special_pattern pt1 -insert_channel_straps { \
#       {layer: M4} {direction: vertical} {width: 0.2}
#       {channel_between_objects: macro} {channel_threshold: 5} }

# set_pg_strategy st1 \
#   -core \
#   -pattern {{name: pt1} {nets: VDD VSS}}

compile_pg -strategies {st1} -tag channel_straps

redirect -tee -file ../reports/icc2/check_mv_design_floorplan.rpt {check_mv_design}
redirect -tee -file ../reports/icc2/congestion_floorplan.rpt {report_congestion}
redirect -tee -file ../reports/icc2/clock_qor_floorplan.rpt {report_clock_qor}
redirect -tee -file ../reports/icc2/qor_floorplan.rpt {report_qor}
redirect -tee -file ../reports/icc2/qor_summary_floorplan.rpt {report_qor -summary}
redirect -tee -file ../reports/icc2/timing_setup_floorplan.rpt {report_timing -delay_type max}
redirect -tee -file ../reports/icc2/timing_hold_floorplan.rpt {report_timing -delay_type min}
redirect -tee -file ../reports/icc2/constraint_floorplan.rpt {report_constraints}
redirect -tee -file ../reports/icc2/constraint_DRC_floorplan.rpt {report_constraints -all_violators -min_capacitance -max_capacitance -max_transition}
redirect -tee -file ../reports/icc2/design_physical_floorplan.rpt {report_design -physical}
redirect -tee -file ../reports/icc2/design_floorplan.rpt {report_design}
redirect -tee -file ../reports/icc2/congestion_floorplan.rpt {report_congestion}

# Save block
rename_block -to_block MYTOP/floorplan
save_block

########################################
#        Placement Optimization        #
########################################

check_design -checks pre_placement_stage
check_design -checks physical_constraints

mark_clock_trees

set_app_options -name opt.tie_cell.max_fanout -value 8

# Placement legalizer and run without scandef
#set_app_options -name place.legalize.enable_advanced_legalizer -value true
set_app_options -name place.coarse.continue_on_missing_scandef -value true

# Placement optimization
place_opt

# Do a series of checkings
check_legality
check_mv_design
check_pg_drc
check_pg_connectivity
check_placement_constraints
check_physical_constraints

redirect -tee -file ../reports/icc2/clock_qor_placement.rpt {report_clock_qor}
redirect -tee -file ../reports/icc2/qor_placement.rpt {report_qor}
redirect -tee -file ../reports/icc2/qor_summary_placement.rpt {report_qor -summary}
redirect -tee -file ../reports/icc2/timing_setup_placement.rpt {report_timing -delay_type max}
redirect -tee -file ../reports/icc2/timing_hold_placement.rpt {report_timing -delay_type min}
redirect -tee -file ../reports/icc2/constraint_placement.rpt {report_constraints}
redirect -tee -file ../reports/icc2/constraint_DRC_placement.rpt {report_constraints -all_violators -min_capacitance -max_capacitance -max_transition}
redirect -tee -file ../reports/icc2/design_physical_placement.rpt {report_design -physical}
redirect -tee -file ../reports/icc2/design_placement.rpt {report_design}
redirect -tee -file ../reports/icc2/congestion_placement.rpt {report_congestion}

rename_block -to_block MYTOP/place_opt
save_block

######################################################
#			Clock Tree Synthesis Optimization        #
######################################################
# Perform CTS (2% of clock period)
# Applicable for MCMM design, however this design is single scenario ONLY
set_max_transition 0.10 -clock_path [get_clocks] -corners [all_corners]

# Clock optimization
set CTS_CELLS [get_lib_cells "*/NBUFF*LVT */INVX*_LVT */CGL* */*DFF*"]
set_dont_touch $CTS_CELLS false
set_lib_cell_purpose -exclude cts [get_lib_cells]
set_lib_cell_purpose -include cts $CTS_CELLS
set_app_options -list {time.remove_clock_reconvergence_pessimism true}
set_app_options -name cts.compile.enable_global_route -value true		
set_app_options -name clock_opt.flow.enable_ccd -value false		 	; # disable CCD
set_app_options -name cts.compile.enable_local_skew -value true			; # enable clock skew CTS
set_app_options -name cts.optimize.enable_local_skew -value true

# To improve the slack performance in setup and hold timing
remove_clock_uncertainty [get_clocks clk]

#clock_opt
clock_opt -to route_clock

redirect -tee -file ../reports/icc2/clock_qor_pre_cts.rpt {report_clock_qor}
redirect -tee -file ../reports/icc2/qor_pre_cts.rpt {report_qor -summary}

#report_timing
clock_opt -to final_opto

redirect -tee -file ../reports/icc2/clock_qor_post_cts.rpt {report_clock_qor}
redirect -tee -file ../reports/icc2/qor_post_cts.rpt {report_qor}
redirect -tee -file ../reports/icc2/qor_summary_post_cts.rpt {report_qor -summary}
redirect -tee -file ../reports/icc2/timing_setup_post_cts.rpt {report_timing -delay_type max}
redirect -tee -file ../reports/icc2/timing_hold_post_cts.rpt {report_timing -delay_type min}
redirect -tee -file ../reports/icc2/constraint_post_cts.rpt {report_constraints}
redirect -tee -file ../reports/icc2/constraint_DRC_post_cts.rpt {report_constraints -all_violators -min_capacitance -max_capacitance -max_transition}
redirect -tee -file ../reports/icc2/design_physical_post_cts.rpt {report_design -physical}
redirect -tee -file ../reports/icc2/design_post_cts.rpt {report_design}
redirect -tee -file ../reports/icc2/congestion_post_cts.rpt {report_congestion}

# Save block
rename_block -to_block MYTOP/clock_opt
save_block

######################################
#        Routing Optimization        #
######################################

# --------- Pre-routing Setup -------- #
# Sets the verbosity level for the routing log file to 1
set_app_options -name route.common.verbose_level -value 1

#Perform routing
check_design -checks pre_route_stage

set_app_options -name route.global.timing_driven -value true
set_app_option -name route.track.timing_driven -value true
set_app_option -name route.detail.timing_driven -value true
set_app_option -name route.global.timing_driven_effort_level -value high

set_app_options -name route.global.crosstalk_driven -value false
set_app_options -name route.track.crosstalk_driven -value true

# -------- Routing -------- #
route_auto
route_opt
group_path -name CAP -weight 5 -critical 0.2 -from [get_cells {U1* U6* in* H*}]

set_app_options -name time.pba_optimization_mode -value path
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

# Increase accuracy and better align with PT
set_app_options -name time.enable_ccs_rcv_cap -value true
set_app_options -name time.delay_calc_waveform_analysis_mode -value full_design
set_app_options -name time.awp_compatibility_mode -value false
set_app_option -name time.enable_si_timing_windows -value true

route_auto
route_opt

# Controls the use of path-based analysis during post-route optimization
set_app_options -name time.pba_optimization_mode -value path

# Soft-rule-based timing optimization during ECO routing
set_app_options -name route.detail.eco_route_use_soft_spacing_for_timing_optimization -value false

route_opt

# Check LVS and DRC
report_timing
check_lvs
check_routes

# Save final block
rename_block -to_block MYTOP/route_opt
save_block
save_lib

##########################################################
#        Save All The Reports in Report Directory        #
##########################################################
redirect -tee -file ../reports/icc2/timing_final_setup_post_route.rpt {report_timing -delay_type max}
redirect -tee -file ../reports/icc2/timing_final_hold_post_route.rpt {report_timing -delay_type min}
redirect -tee -file ../reports/icc2/constraint_final_post_route.rpt {report_constraints}
redirect -tee -file ../reports/icc2/constraint_final_DRC_post_route.rpt {report_constraints -all_violators -min_capacitance -max_capacitance -max_transition}
redirect -tee -file ../reports/icc2/qor_post_route.rpt {report_qor}
redirect -tee -file ../reports/icc2/qor_summary_post_route.rpt {report_qor -summary}
redirect -tee -file ../reports/icc2/design_physical_post_route.rpt {report_design -physical}
redirect -tee -file ../reports/icc2/design_post_route.rpt {report_design}
redirect -tee -file ../reports/icc2/congestion_post_route.rpt {report_congestion}
redirect -tee -file ../reports/icc2/check_lvs.rpt {check_lvs}
redirect -tee -file ../reports/icc2/check_route.rpt {check_route}

#################################################################
#        Send the PnR Results to Output Directory for PT        #	
#################################################################
write_verilog ../output/icc2/MYTOP.v
write_sdc -output ../output/icc2/MYTOP.sdc
write_parasitics -output ../output/icc2/MYTOP.spef

###############################
#       Exit ICC2 Shell       #
###############################
exit