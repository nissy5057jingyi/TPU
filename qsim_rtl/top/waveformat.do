onerror {resume}
quietly WaveActivateNextPane {} 0

add wave -noupdate  /tb_top/clk
add wave -noupdate  /tb_top/clk_mem
add wave -noupdate  /tb_top/reset
add wave -noupdate  /tb_top/resetn
add wave -noupdate -radix decimal /tb_top/PADDR
add wave -noupdate -radix decimal /tb_top/PWRITE
add wave -noupdate -radix decimal /tb_top/PSEL
add wave -noupdate -radix decimal /tb_top/PENABLE
add wave -noupdate -radix decimal /tb_top/PWDATA
add wave -noupdate -radix decimal /tb_top/bram_addr_a_ext
add wave -noupdate -radix decimal /tb_top/bram_wdata_a_ext
add wave -noupdate -radix decimal /tb_top/bram_we_a_ext
add wave -noupdate -radix decimal /tb_top/bram_addr_b_ext
add wave -noupdate -radix decimal /tb_top/bram_wdata_b_ext
add wave -noupdate -radix decimal /tb_top/bram_we_b_ext

add wave -noupdate -color "gold" -radix decimal /tb_top/bram_we_b_ext
add wave -noupdate -color "gold" -radix decimal /tb_top/bram_rdata_a_ext
add wave -noupdate -color "gold" -radix decimal /tb_top/PRDATA
add wave -noupdate -color "gold" -radix decimal /tb_top/PREADY

add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_addr_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_stride_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_mat_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_addr_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_stride_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_mat_b

add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_addr_a_for_reading
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_addr_a_for_writing
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_rdata_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_wdata_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_we_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_en_a

add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_rdata_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_wdata_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_we_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_en_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_a_wdata_available
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/bram_addr_c_NC
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/start_tpu
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/done_tpu

add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/enable_matmul
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/start_mat_mul
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/done_mat_mul
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/enable_norm
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_norm/mean_applied_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_norm/variance_applied_data 
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/norm_out_data_available
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/done_norm
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/enable_pool
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/pool_out_data_available
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/done_pool
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/enable_activation
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/activation_out_data_available
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/done_activation




add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/matmul_c_data_out
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/norm_data_out
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/pool_data_out
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/activation_data_out
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/matmul_c_data_available
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/a_data_out_NC
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/b_data_out_NC
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/a_data_in_NC
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/b_data_in_NC
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/mean
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/inv_var
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_mat_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_mat_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_mat_c
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/validity_mask_a_rows
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/validity_mask_a_cols
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/validity_mask_b_rows
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/validity_mask_b_cols
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/save_output_to_accum
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/add_accum_to_output
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_stride_a
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_stride_b
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/address_stride_c
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/pool_window_size
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/activation_type
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_filter_height
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_filter_width
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_stride_horiz
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_stride_verti
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_padding_left
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_padding_right
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_padding_top
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/conv_padding_bottom
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/num_channels_inp
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/num_channels_out
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/inp_img_height
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/inp_img_width
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/out_img_height
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/out_img_width
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/batch_size
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/enable_conv_mode
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/pe_reset

add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[0]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[1]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[2]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[3]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[4]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[5]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[6]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[7]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[8]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[9]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[10]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[11]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[12]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[13]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[14]/dp1/ram
add wave -noupdate -color "green" -radix decimal /tb_top/uut/matrix_A/genblk1[15]/dp1/ram

add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[0]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[1]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[2]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[3]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[4]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[5]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[6]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[7]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[8]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[9]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[10]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[11]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[12]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[13]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[14]/dp1/ram
add wave -noupdate -color "pink" -radix decimal /tb_top/uut/matrix_B/genblk1[15]/dp1/ram

add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/matrixC0_0
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_1
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_2
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_3
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_4
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_5
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_6
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_7
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_8
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_9
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_10
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_11
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_12
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_13
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_14
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/matrixC15_15

add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/u_output_logic/condition_to_start_shifting_output
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/u_output_logic/row_latch_en 
add wave -noupdate -color "cyan" -radix decimal /tb_top/uut/u_matmul/u_output_logic/done_mat_mul
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_control/state

add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a0_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a1_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a2_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a3_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a4_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a5_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a6_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a7_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a8_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a9_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a10_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a11_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a12_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a13_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a14_data
add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/a15_data

add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b0_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b1_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b2_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b3_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b4_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b5_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b6_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b7_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b8_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b9_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b10_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b11_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b12_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b13_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b14_data
add wave -noupdate -color "green" -radix decimal /tb_top/uut/u_matmul/u_systolic_data_setup/b15_data

add wave -noupdate -color "yellow" -radix decimal /tb_top/uut/u_pool/cycle_count

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


