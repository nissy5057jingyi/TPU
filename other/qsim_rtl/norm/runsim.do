##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/qadd/qadd.v 
vlog +acc -incr test_qadd.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_qadd
do waveformat.do   
run -all
