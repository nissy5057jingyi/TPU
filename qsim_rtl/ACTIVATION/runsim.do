##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/activation/activation.v 
vlog +acc -incr test_activation.v 

# Run Simulator 
vsim +acc -t ps -lib work activation_tb
do waveformat.do   
run -all
