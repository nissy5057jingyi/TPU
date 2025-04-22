##################################################
#  Modelsim do file to run simuilation
#  MS 7/2015
##################################################

vlib work 
vmap work work

# Include Netlist and Testbench
vlog +acc -incr ../../rtl/seq_mac/seq_mac.v 
vlog +acc -incr ../../rtl/qmult/qmult.v 
vlog +acc -incr ../../rtl/qadd/qadd.v 
vlog +acc -incr test_seq_mac.v 

# Run Simulator 
vsim +acc -t ps -lib work tb_seq_mac
do waveformat.do   
run -all
