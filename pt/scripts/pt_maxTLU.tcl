####################################################################
#        Note: Must Run this tcl at assignment/pt Directory        #
####################################################################

################################
#        Setup for PT        #
################################
source -echo -verbose ./scripts/pt_setup.tcl

###################################################
#        Read postlayout netlist from ICC2        #
###################################################
read_verilog ../output/icc2/MYTOP.v
current_design MYTOP
link_design -force
current_design

############################################
#        Load Libraries into Memory        #
############################################
get_libs
printvar link_path
printvar search_path

###########################################
#        Read Parasitics from ICC2        #
###########################################

# ONLY turn on min or max TLU at one time each the most bottom read_parasitics will override the above one
read_parasitics -format SPEF ../output/icc2/MYTOP.spef.maxTLU_125.spef
#read_parasitics -format SPEF ../output/icc2/MYTOP.spef.minTLU_125.spef
#read_parasitics -format SPEF ../output/icc2/MYTOP.spef.spef_scenario

report_annotated_parasitics 

# ----------------------------------------------------------------------
# Source constraints and check for correctness
# ----------------------------------------------------------------------
########################################
#        Source the Constraints        #
########################################

# Execute the constraints as they are read
read_sdc -echo ../output/icc2/MYTOP.sdc
check_timing -verbose  

#################################################
#       Set Significant Figures for Reports		#
#################################################
set_app_var report_default_significant_digits 5
printvar report_default_significant_digits

report_clock -skew -attribute	
report_port -verbose

report_design
report_exceptions -ignored
report_case_analysis

###########################################
#        Update Timing Information        #
###########################################
update_timing -full

##########################################################
#        Save All The Reports in Report Directory        #
##########################################################
redirect -tee -file ../reports/pt/parasitic_maxTLU.rpt {report_annotated_parasitics}
redirect -tee -file ../reports/pt/analysis_coverage_maxTLU.rpt {report_analysis_coverage}
redirect -tee -file ../reports/pt/analysis_coverage_untested_maxTLU.rpt {report_analysis_coverage -status_details untested}
redirect -tee -file ../reports/pt/constraint_final_maxTLU.rpt {report_constraints}
redirect -tee -file ../reports/pt/constraint_final_DRC_maxTLU.rpt {report_constraints -all_violators -min_capacitance -max_capacitance -max_transition}
redirect -tee -file ../reports/pt/timing_final_setup_maxTLU.rpt {report_timing -delay_type max}
redirect -tee -file ../reports/pt/timing_final_hold_maxTLU.rpt {report_timing -delay_type min}
redirect -tee -file ../reports/pt/qor_maxTLU.rpt {report_qor}
redirect -tee -file ../reports/pt/qor_summary_maxTLU.rpt {report_qor -summary}
redirect -tee -file ../reports/pt/global_timing_maxTLU.rpt {report_global_timing}

###########################################
#        Update Timing Information        #
###########################################
save_session MYTOP_maxTLU_SESSION

#############################
#       Exit PT Shell       #
#############################
quit