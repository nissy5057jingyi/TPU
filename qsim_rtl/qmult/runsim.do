##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/qmult/qmult.v 
vlog +acc -incr test_qmult.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_qmult
do waveformat.do   
run -all
