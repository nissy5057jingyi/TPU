onerror {resume}
quietly WaveActivateNextPane {} 0
\
add wave -noupdate radix -signed /tb_seq_mac/a
add wave -noupdate radix -signed /tb_seq_mac/b
add wave -noupdate /tb_seq_mac/reset
add wave -noupdate /tb_seq_mac/clk
add wave -noupdate radix -signed /tb_seq_mac/out
add wave -noupdate radix -signed /tb_seq_mac/expected_result
add wave -noupdate radix -signed /uut/a_flopped
add wave -noupdate radix -signed /uut/b_flopped
add wave -noupdate radix -signed /uut/mul_out_temp 
add wave -noupdate radix -signed /uut/mul_out_temp_reg
add wave -noupdate radix -signed /uut/out_temp
add wave -noupdate radix /tb_seq_mac/correct

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


