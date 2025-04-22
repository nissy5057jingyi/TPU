##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/matmul_16_16_systolic/matmul_16_16_systolic.v 

vlog +acc -incr ../../rtl/output_logic/output_logic.v 
vlog +acc -incr ../../rtl/systolic_data_setup/systolic_data_setup.v 
vlog +acc -incr ../../rtl/systolic_pe_matrix/systolic_pe_matrix.v 
vlog +acc -incr ../../rtl/processing_element_bottom_edge/processing_element_bottom_edge.v 
vlog +acc -incr ../../rtl/processing_element_top_edge/processing_element_top_edge.v 
vlog +acc -incr ../../rtl/processing_element/processing_element.v 
vlog +acc -incr ../../rtl/seq_mac/seq_mac.v 
vlog +acc -incr ../../rtl/qmult/qmult.v 
vlog +acc -incr ../../rtl/qadd/qadd.v 
vlog +acc -incr test_matmul_16_16_matrix.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_matmul_16_16
do waveformat.do   
run -all
