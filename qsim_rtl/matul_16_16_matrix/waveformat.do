onerror {resume}
quietly WaveActivateNextPane {} 0
\
add wave -noupdate /tb_matmul_16_16/clk
add wave -noupdate /tb_matmul_16_16/reset
add wave -noupdate /tb_matmul_16_16/pe_reset
add wave -noupdate /tb_matmul_16_16/start_mat_mul
add wave -noupdate /tb_matmul_16_16/done_mat_mul
add wave -noupdate /tb_matmul_16_16/address_stride_a
add wave -noupdate /tb_matmul_16_16/ address_stride_b
add wave -noupdate /tb_matmul_16_16/ address_stride_c

add wave -noupdate radix -signed/tb_matmul_16_16/ a_data
add wave -noupdate radix -signed/tb_matmul_16_16/ b_data
add wave -noupdate radix -signed/tb_matmul_16_16/ c_data_out

add wave -noupdate radix -signed/tb_matmul_16_16/ a_data_out
add wave -noupdate radix -signed/tb_matmul_16_16/ b_data_out
add wave -noupdate /tb_matmul_16_16/ a_addr
add wave -noupdate /tb_matmul_16_16/ b_addr
add wave -noupdate /tb_matmul_16_16/ c_addr
add wave -noupdate /tb_matmul_16_16/ c_data_available

add wave -noupdate /tb_matmul_16_16/ validity_mask_a_rows
add wave -noupdate /tb_matmul_16_16/ validity_mask_a_cols
add wave -noupdate /tb_matmul_16_16/ validity_mask_b_rows
add wave -noupdate /tb_matmul_16_16/ validity_mask_b_cols

add wave -noupdate /tb_matmul_16_16/ final_mat_mul_size
add wave -noupdate /tb_matmul_16_16/ a_loc
add wave -noupdate /tb_matmul_16_16/ b_loc

add wave -noupdate /tb_matmul_16_16/uut/matrixC0_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC0_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC1_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC1_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC2_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC2_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC3_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC3_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC4_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC4_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC5_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC5_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC6_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC6_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC7_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC7_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC8_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC8_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC9_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC9_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC10_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC10_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC11_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC11_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC12_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC12_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC13_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC13_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC14_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC14_15

add wave -noupdate /tb_matmul_16_16/uut/matrixC15_0
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_1
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_2
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_3
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_4
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_5
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_6
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_7
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_8
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_9
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_10
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_11
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_12
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_13
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_14
add wave -noupdate /tb_matmul_16_16/uut/matrixC15_15

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


