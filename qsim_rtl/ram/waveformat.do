onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -radix decimal /tb_ram/clk
add wave -noupdate -radix decimal /tb_ram/q1
add wave -noupdate -radix decimal /tb_ram/q0
add wave -noupdate -radix decimal /tb_ram/we1
add wave -noupdate -radix decimal /tb_ram/we0
add wave -noupdate -radix decimal /tb_ram/d1
add wave -noupdate -radix decimal /tb_ram/d0
add wave -noupdate -radix decimal /tb_ram/addr1
add wave -noupdate -radix decimal /tb_ram/addr0

add wave -noupdate -radix decimal /tb_ram/uut/genblk1[0]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[1]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[2]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[3]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[4]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[5]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[6]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[7]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[8]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[9]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[10]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[11]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[12]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[13]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[14]/dp1/ram
add wave -noupdate -radix decimal /tb_ram/uut/genblk1[15]/dp1/ram




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


