onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /tb_dpram_original/clk
add wave -noupdate -radix decimal /tb_dpram_original/address_a
add wave -noupdate -radix decimal /tb_dpram_original/address_b
add wave -noupdate /tb_dpram_original/wren_a
add wave -noupdate /tb_dpram_original/wren_b
add wave -noupdate -radix decimal /tb_dpram_original/data_a
add wave -noupdate -radix decimal /tb_dpram_original/data_b
add wave -noupdate -radix decimal -color "yellow" /tb_dpram_original/out_a
add wave -noupdate -color "lime" -radix decimal  /tb_dpram_original/out_b

add wave -noupdate -color "lime" -radix decimal /tb_dpram_original/uut/ram
add wave -noupdate -radix decimal /tb_dpram_original/write_addr
add wave -noupdate -radix decimal /tb_dpram_original/read_addr
add wave -noupdate -radix decimal /tb_dpram_original/write_data_a
add wave -noupdate -radix decimal /tb_dpram_original/write_data_b

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


