####################################################################
#        Note: Must Run this tcl at assignment/dc Directory        #
####################################################################

###############################################################
#        Read, Link and Check RTL Designs from Verilog        #
###############################################################
read_file -f verilog [glob ../source/*.v]
set design_name "MYTOP"
current_design $design_name
link
check_design

#################################################
#       Set Significant Figures for Reports		#
#################################################
set_app_var report_default_significant_digits 5
printvar report_default_significant_digits

source -echo -verbose ./scripts/dc.con

##########################################
#       Changes to the RTL Designs       #
##########################################
# Insert buffers for all multiple-port nets - eliminate assign
set_fix_multiple_port_nets -all -buffer_constants

# Delay is the most important cost
set_cost_priority -delay

# Convert tri to wire - eliminate assign 
set verilogout_no_tri true 

############################################################
#       Run compile_ultra by changing the registers        #
############################################################
compile_ultra -retime

# Eliminate special characters in the netlist and constraint file
change_name -rules verilog -hierarchy  

###################################################
#       Save the Reports With Cost Priority       #
###################################################
redirect -tee -file ../reports/dc/timing_final_setup.rpt {report_timing -delay_type max}
redirect -tee -file ../reports/dc/timing_final_hold.rpt {report_timing -delay_type min}
redirect -tee -file ../reports/dc/constraint_final.rpt {report_constraints}
redirect -tee -file ../reports/dc/constraint_final_DRC.rpt {report_constraints -all_violators -min_capacitance -max_capacitance -max_transition}
redirect -tee -file ../reports/dc/qor_final.rpt {report_qor}

######################################################################
#       Send the Synthesis Results to Output Directory for ICC2      #
######################################################################
write_sdc ../output/dc/${design_name}.sdc
write_file -format ddc -hier -output ../output/dc/${design_name}.ddc
write_file -format verilog -hier -output ../output/dc/${design_name}.v

#############################
#       Exit DC Shell       #
#############################
exit