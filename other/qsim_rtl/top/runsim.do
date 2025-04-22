##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################
exec python3 gen_matrix.py


vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/top/top.v 

vlog +acc -incr ../../rtl/ram/ram.v 
vlog +acc -incr ../../rtl/dpram_original/dpram_original.v 


vlog +acc -incr ../../rtl/control/control.v
vlog +acc -incr ../../rtl/cfg/cfg.v

vlog +acc -incr ../../rtl/matmul_16_16_systolic/matmul_16_16_systolic.v
vlog +acc -incr ../../rtl/systolic_data_setup/systolic_data_setup.v
vlog +acc -incr ../../rtl/output_logic/output_logic.v
vlog +acc -incr ../../rtl/systolic_pe_matrix/systolic_pe_matrix.v
vlog +acc -incr ../../rtl/processing_element/processing_element.v
vlog +acc -incr ../../rtl/processing_element_bottom_edge/processing_element_bottom_edge.v
vlog +acc -incr ../../rtl/processing_element_top_edge/processing_element_top_edge.v
vlog +acc -incr ../../rtl/seq_mac/seq_mac.v
vlog +acc -incr ../../rtl/qadd/qadd.v 
vlog +acc -incr ../../rtl/qmult/qmult.v 
vlog +acc -incr ../../rtl/norm/norm.v 
vlog +acc -incr ../../rtl/pool/pool.v 
vlog +acc -incr ../../rtl/activation/activation.v 

vlog +acc -incr test_top.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_top
do waveformat.do   
run -all
