##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/dpram_original/dpram_original.v 
vlog +acc -incr test_dpram_original.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_dpram_original
do waveformat.do   
run -all
