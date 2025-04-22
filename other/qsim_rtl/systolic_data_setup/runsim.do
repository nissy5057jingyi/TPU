##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/processing_element/processing_element.v 
vlog +acc -incr ../../rtl/seq_mac/seq_mac.v 
vlog +acc -incr ../../rtl/qmult/qmult.v 
vlog +acc -incr ../../rtl/qadd/qadd.v 
vlog +acc -incr test_processing_element.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_processing_element
do waveformat.do   
run -all
