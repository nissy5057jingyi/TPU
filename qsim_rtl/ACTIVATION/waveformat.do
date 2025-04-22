onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /activation_tb/clk
add wave -noupdate /activation_tb/reset

add wave -noupdate -radix unsigned /activation_tb/activation_type
add wave -noupdate -radix unsigned /activation_tb/enable_activation
add wave -noupdate -radix unsigned /activation_tb/in_data_available
add wave -noupdate -radix decimal /activation_tb/inp_data
add wave -noupdate -radix decimal /activation_tb/out_data 
add wave -noupdate -radix unsigned /activation_tb/out_data_available
add wave -noupdate -radix unsigned /activation_tb/validity_mask
add wave -noupdate -radix unsigned /activation_tb/done_activation
add wave -noupdate -radix unsigned /uut/done_activation_internal
add wave -noupdate -radix unsigned /uut/out_data_available_internal
add wave -noupdate -radix decimal /uut/out_data_internal
add wave -noupdate -radix unsigned /uut/slope_applied_data_internal
add wave -noupdate -radix unsigned /uut/intercept_applied_data_internal
add wave -noupdate -radix unsigned /uut/relu_applied_data_internal
add wave -noupdate -radix unsigned /uut/i
add wave -noupdate -radix unsigned /uut/cycle_count
add wave -noupdate -radix unsigned /uut/activation_in_progress
add wave -noupdate -radix unsigned /uut/address
add wave -noupdate -radix unsigned /uut/data_slope
add wave -noupdate -radix unsigned /uut/data_slope_flopped
add wave -noupdate -radix unsigned /uut/data_intercept
add wave -noupdate -radix unsigned /uut/data_intercept_delayed
add wave -noupdate -radix unsigned /uut/data_intercept_flopped
add wave -noupdate -radix unsigned /uut/in_data_available_flopped
add wave -noupdate -radix unsigned /uut/inp_data_flopped





TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3 ns} 0}
quietly wave cursor active 1

configure wave -namecolwidth 223
configure wave -valuecolwidth 89
configure wave -justifyvalue left
configure wave -signalnamewidth 0
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {0 ns} {12 ns}


