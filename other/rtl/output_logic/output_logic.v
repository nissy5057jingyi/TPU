`define DWIDTH 8

//This is the size of the matrix multiplier unit. In this design, we have a systolic
//matrix multiplication unit that can multiply 16x16 matrix with a 16x16 matrix.
`define DESIGN_SIZE 16
`define LOG2_DESIGN_SIZE 5
`define MAT_MUL_SIZE 16
`define MASK_WIDTH 16
`define LOG2_MAT_MUL_SIZE 5

//This it the size of the address bus, or the depth of the RAM. Each location of 
//the RAM is DWIDTH * MAT_MUL_SIZE wide. So, in this design, we use a total of
//1024 * 16 bytes of memory (i.e. 16 KB).
`define AWIDTH 10

//This is the number of clock cycles spent in the mac block
`define NUM_CYCLES_IN_MAC 3

//This defines the latency of accessing data from a block ram
`define MEM_ACCESS_LATENCY 1

//Data width and address width of the APB interface for registers
`define REG_DATAWIDTH 32
`define REG_ADDRWIDTH 8

//Width of the stride for each column in the matrices (same as ram address width)
`define ADDR_STRIDE_WIDTH 16

//Number of bits to specify the pooling window. We support 3 sizes.
`define MAX_BITS_POOL 3

/////////////////////////////////////////////////
// Register specification
/////////////////////////////////////////////////

//---------------------------------------
//Addr 0 : Register with enables for various blocks. 
//Includes mode of operation (convolution or fully_connected)
//---------------------------------------
`define REG_ENABLES_ADDR 32'h0
//Bit 0: enable_matmul
//Bit 1: enable_norm
//Bit 2: enable_pool
//Bit 3: enable_activation
//Bit 31: enable_conv_mode

//---------------------------------------
//Addr 4: Register that triggers the whole TPU
//---------------------------------------
`define REG_STDN_TPU_ADDR 32'h4
//Bit 0: start_tpu
//Bit 31: done_tpu

//---------------------------------------
//Addr 8: Register that stores the mean of the values
//---------------------------------------
`define REG_MEAN_ADDR 32'h8
//Bit 7:0: mean

//---------------------------------------
//Addr A: Register that stores the inverse variance of the values
//---------------------------------------
`define REG_INV_VAR_ADDR 32'hA
//Bit 7:0: inv_var

//---------------------------------------
//Addr E: Register that stores the starting address of matrix A in BRAM A.
//In fully-connected mode, this register should be programmed with the
//address of the matrix being currently multiplied. That is, the 
//address of the matrix of the matmul. So, this register will be
//programmed every time the matmul is kicked off during accumulation stages.
//Use the STRIDE registers to tell the matmul to increment addresses.
//In convolution mode, this register should be programmed with the 
//address of the input activation matrix. No need to configure
//this every time the matmul is kicked off for accmulation. Just program it 
//once it the beginning. Address increments are handled automatically .
//---------------------------------------
`define REG_MATRIX_A_ADDR 32'he
//Bit `AWIDTH-1:0 address_mat_a

//---------------------------------------
//Addr 12: Register that stores the starting address of matrix B in BRAM B.
//See detailed note on the usage of this register in REG_MATRIX_A_ADDR.
//---------------------------------------
`define REG_MATRIX_B_ADDR 32'h12
//Bit `AWIDTH-1:0 address_mat_b

//---------------------------------------
//Addr 16: Register that stores the starting address of matrix C in BRAM C.
//See detailed note on the usage of this register in REG_MATRIX_A_ADDR.
//---------------------------------------
`define REG_MATRIX_C_ADDR 32'h16
//Bit `AWIDTH-1:0 address_mat_c

//---------------------------------------
//Addr 24: Register that controls the accumulation logic
//---------------------------------------
`define REG_ACCUM_ACTIONS_ADDR 32'h24
//Bit 0 save_output_to_accumulator
//Bit 1 add_accumulator_to_output

//---------------------------------------
//(Only applicable in fully-connected mode)
//Addr 28: Register that stores the stride that should be taken to address
//elements in matrix A, after every MAT_MUL_SIZE worth of data has been fetched.
//See the diagram in "Meeting-16" notes in the EE382V project Onenote notebook.
//This stride is applied when incrementing addresses for matrix A in the vertical
//direction.
//---------------------------------------
`define REG_MATRIX_A_STRIDE_ADDR 32'h28
//Bit `ADDR_STRIDE_WIDTH-1:0 address_stride_a

//---------------------------------------
//(Only applicable in fully-connected mode)
//Addr 32: Register that stores the stride that should be taken to address
//elements in matrix B, after every MAT_MUL_SIZE worth of data has been fetched.
//See the diagram in "Meeting-16" notes in the EE382V project Onenote notebook.
//This stride is applied when incrementing addresses for matrix B in the horizontal
//direction.
//---------------------------------------
`define REG_MATRIX_B_STRIDE_ADDR 32'h32
//Bit `ADDR_STRIDE_WIDTH-1:0 address_stride_b

//---------------------------------------
//(Only applicable in fully-connected mode)
//Addr 36: Register that stores the stride that should be taken to address
//elements in matrix C, after every MAT_MUL_SIZE worth of data has been fetched.
//See the diagram in "Meeting-16" notes in the EE382V project Onenote notebook.
//This stride is applied when incrementing addresses for matrix C in the vertical
//direction (this is generally same as address_stride_a).
//---------------------------------------
`define REG_MATRIX_C_STRIDE_ADDR 32'h36
//Bit `ADDR_STRIDE_WIDTH-1:0 address_stride_c

//---------------------------------------
//Addr 3A: Register that controls the activation block. Currently, the available 
//settings are the selector of activation function that will be used. There are
//two options: ReLU and TanH. To use ReLU, clear the LSB of this register. To
//use TanH, set the LSB of this register.
//---------------------------------------
`define REG_ACTIVATION_CSR_ADDR 32'h3A

//---------------------------------------
//Addr 3E: Register defining pooling window size
//---------------------------------------
`define REG_POOL_WINDOW_ADDR 32'h3E
//Bit `MAX_BITS_POOL-1:0 pool window size

//---------------------------------------
//Addr 40: Register defining convolution parameters - 1
//----------------------------------------
`define REG_CONV_PARAMS_1_ADDR 32'h40
//Bits filter_height (R) 3:0
//Bits filter width (S)  7:4
//Bits stride_horizontal 11:8
//Bits stride_vertical 15:12
//Bits pad_left 19:16
//Bits pad_right 23:20
//Bits pad_top 27:24
//Bits pad_bottom 31:28

//---------------------------------------
//Addr 44: Register defining convolution parameters - 2
//----------------------------------------
`define REG_CONV_PARAMS_2_ADDR 32'h44
//Bits num_channels_input (C) 15:0
//Bits num_channels_output (K) 31:16

//---------------------------------------
//Addr 48: Register defining convolution parameters - 3
//----------------------------------------
`define REG_CONV_PARAMS_3_ADDR 32'h48
//Bits input_image_height (H) 15:0
//Bits input_image_width (W) 31:16

//---------------------------------------
//Addr 4C: Register defining convolution parameters - 4
//----------------------------------------
`define REG_CONV_PARAMS_4_ADDR 32'h4C
//Bits output_image_height (P) 15:0
//Bits output_image_width (Q) 31:16

//---------------------------------------
//Addr 50: Register defining batch size
//----------------------------------------
`define REG_BATCH_SIZE_ADDR 32'h50
//Bits 31:0 batch_size (number of images, N)

//---------------------------------------
//Addresses 54,58,5C: Registers that stores the mask of which parts of the matrices are valid.
//
//Some examples where this is useful:
//1. Input matrix is smaller than the matmul. 
//   Say we want to multiply a 6x6 using an 8x8 matmul.
//   The matmul still operates on the whole 8x8 part, so we need
//   to ensure that there are 0s in the BRAMs in the invalid parts.
//   But the mask is used by the blocks other than matmul. For ex,
//   norm block will use the mask to avoid applying mean and variance 
//   to invalid parts (so tha they stay 0). 
//2. When we start with large matrices, the size of the matrices can
//   reduce to something less than the matmul size because of pooling.
//   In that case for the next layer, we need to tell blocks like norm,
//   what is valid and what is not.
//
//Note: This masks is applied to both x and y directions and also
//applied to both input matrices - A and B.
//---------------------------------------
`define REG_VALID_MASK_A_ROWS_ADDR 32'h20
`define REG_VALID_MASK_A_COLS_ADDR 32'h54
`define REG_VALID_MASK_B_ROWS_ADDR 32'h5c
`define REG_VALID_MASK_B_COLS_ADDR 32'h58
//Bit `MASK_WIDTH-1:0 validity_mask

//This used to be a normal signal, but changing it to a `define.
//That's because it's not required to be a variable in this design.
//And ODIN doesn't seem to propagate constants properly.
`define final_mat_mul_size 16


module output_logic(
	start_mat_mul,
	done_mat_mul,
	address_mat_c,
	address_stride_c,
	c_data_in,
	c_data_out, //Data values going out to next matmul - systolic shifting
	c_addr,
	c_data_available,
	clk_cnt,
	row_latch_en,
	final_mat_mul_size,
	matrixC0_0,
	matrixC0_1,
	matrixC0_2,
	matrixC0_3,
	matrixC0_4,
	matrixC0_5,
	matrixC0_6,
	matrixC0_7,
	matrixC0_8,
	matrixC0_9,
	matrixC0_10,
	matrixC0_11,
	matrixC0_12,
	matrixC0_13,
	matrixC0_14,
	matrixC0_15,
	matrixC1_0,
	matrixC1_1,
	matrixC1_2,
	matrixC1_3,
	matrixC1_4,
	matrixC1_5,
	matrixC1_6,
	matrixC1_7,
	matrixC1_8,
	matrixC1_9,
	matrixC1_10,
	matrixC1_11,
	matrixC1_12,
	matrixC1_13,
	matrixC1_14,
	matrixC1_15,
	matrixC2_0,
	matrixC2_1,
	matrixC2_2,
	matrixC2_3,
	matrixC2_4,
	matrixC2_5,
	matrixC2_6,
	matrixC2_7,
	matrixC2_8,
	matrixC2_9,
	matrixC2_10,
	matrixC2_11,
	matrixC2_12,
	matrixC2_13,
	matrixC2_14,
	matrixC2_15,
	matrixC3_0,
	matrixC3_1,
	matrixC3_2,
	matrixC3_3,
	matrixC3_4,
	matrixC3_5,
	matrixC3_6,
	matrixC3_7,
	matrixC3_8,
	matrixC3_9,
	matrixC3_10,
	matrixC3_11,
	matrixC3_12,
	matrixC3_13,
	matrixC3_14,
	matrixC3_15,
	matrixC4_0,
	matrixC4_1,
	matrixC4_2,
	matrixC4_3,
	matrixC4_4,
	matrixC4_5,
	matrixC4_6,
	matrixC4_7,
	matrixC4_8,
	matrixC4_9,
	matrixC4_10,
	matrixC4_11,
	matrixC4_12,
	matrixC4_13,
	matrixC4_14,
	matrixC4_15,
	matrixC5_0,
	matrixC5_1,
	matrixC5_2,
	matrixC5_3,
	matrixC5_4,
	matrixC5_5,
	matrixC5_6,
	matrixC5_7,
	matrixC5_8,
	matrixC5_9,
	matrixC5_10,
	matrixC5_11,
	matrixC5_12,
	matrixC5_13,
	matrixC5_14,
	matrixC5_15,
	matrixC6_0,
	matrixC6_1,
	matrixC6_2,
	matrixC6_3,
	matrixC6_4,
	matrixC6_5,
	matrixC6_6,
	matrixC6_7,
	matrixC6_8,
	matrixC6_9,
	matrixC6_10,
	matrixC6_11,
	matrixC6_12,
	matrixC6_13,
	matrixC6_14,
	matrixC6_15,
	matrixC7_0,
	matrixC7_1,
	matrixC7_2,
	matrixC7_3,
	matrixC7_4,
	matrixC7_5,
	matrixC7_6,
	matrixC7_7,
	matrixC7_8,
	matrixC7_9,
	matrixC7_10,
	matrixC7_11,
	matrixC7_12,
	matrixC7_13,
	matrixC7_14,
	matrixC7_15,
	matrixC8_0,
	matrixC8_1,
	matrixC8_2,
	matrixC8_3,
	matrixC8_4,
	matrixC8_5,
	matrixC8_6,
	matrixC8_7,
	matrixC8_8,
	matrixC8_9,
	matrixC8_10,
	matrixC8_11,
	matrixC8_12,
	matrixC8_13,
	matrixC8_14,
	matrixC8_15,
	matrixC9_0,
	matrixC9_1,
	matrixC9_2,
	matrixC9_3,
	matrixC9_4,
	matrixC9_5,
	matrixC9_6,
	matrixC9_7,
	matrixC9_8,
	matrixC9_9,
	matrixC9_10,
	matrixC9_11,
	matrixC9_12,
	matrixC9_13,
	matrixC9_14,
	matrixC9_15,
	matrixC10_0,
	matrixC10_1,
	matrixC10_2,
	matrixC10_3,
	matrixC10_4,
	matrixC10_5,
	matrixC10_6,
	matrixC10_7,
	matrixC10_8,
	matrixC10_9,
	matrixC10_10,
	matrixC10_11,
	matrixC10_12,
	matrixC10_13,
	matrixC10_14,
	matrixC10_15,
	matrixC11_0,
	matrixC11_1,
	matrixC11_2,
	matrixC11_3,
	matrixC11_4,
	matrixC11_5,
	matrixC11_6,
	matrixC11_7,
	matrixC11_8,
	matrixC11_9,
	matrixC11_10,
	matrixC11_11,
	matrixC11_12,
	matrixC11_13,
	matrixC11_14,
	matrixC11_15,
	matrixC12_0,
	matrixC12_1,
	matrixC12_2,
	matrixC12_3,
	matrixC12_4,
	matrixC12_5,
	matrixC12_6,
	matrixC12_7,
	matrixC12_8,
	matrixC12_9,
	matrixC12_10,
	matrixC12_11,
	matrixC12_12,
	matrixC12_13,
	matrixC12_14,
	matrixC12_15,
	matrixC13_0,
	matrixC13_1,
	matrixC13_2,
	matrixC13_3,
	matrixC13_4,
	matrixC13_5,
	matrixC13_6,
	matrixC13_7,
	matrixC13_8,
	matrixC13_9,
	matrixC13_10,
	matrixC13_11,
	matrixC13_12,
	matrixC13_13,
	matrixC13_14,
	matrixC13_15,
	matrixC14_0,
	matrixC14_1,
	matrixC14_2,
	matrixC14_3,
	matrixC14_4,
	matrixC14_5,
	matrixC14_6,
	matrixC14_7,
	matrixC14_8,
	matrixC14_9,
	matrixC14_10,
	matrixC14_11,
	matrixC14_12,
	matrixC14_13,
	matrixC14_14,
	matrixC14_15,
	matrixC15_0,
	matrixC15_1,
	matrixC15_2,
	matrixC15_3,
	matrixC15_4,
	matrixC15_5,
	matrixC15_6,
	matrixC15_7,
	matrixC15_8,
	matrixC15_9,
	matrixC15_10,
	matrixC15_11,
	matrixC15_12,
	matrixC15_13,
	matrixC15_14,
	matrixC15_15,
	
	clk,
	reset
	);
	
	input clk;
	input reset;
	input start_mat_mul;
	input done_mat_mul;
	input [`AWIDTH-1:0] address_mat_c;
	input [`ADDR_STRIDE_WIDTH-1:0] address_stride_c;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_in;
	input [7:0] clk_cnt;
	input [7:0] final_mat_mul_size;
	input [`DWIDTH-1:0] matrixC0_0;
	input [`DWIDTH-1:0] matrixC0_1;
	input [`DWIDTH-1:0] matrixC0_2;
	input [`DWIDTH-1:0] matrixC0_3;
	input [`DWIDTH-1:0] matrixC0_4;
	input [`DWIDTH-1:0] matrixC0_5;
	input [`DWIDTH-1:0] matrixC0_6;
	input [`DWIDTH-1:0] matrixC0_7;
	input [`DWIDTH-1:0] matrixC0_8;
	input [`DWIDTH-1:0] matrixC0_9;
	input [`DWIDTH-1:0] matrixC0_10;
	input [`DWIDTH-1:0] matrixC0_11;
	input [`DWIDTH-1:0] matrixC0_12;
	input [`DWIDTH-1:0] matrixC0_13;
	input [`DWIDTH-1:0] matrixC0_14;
	input [`DWIDTH-1:0] matrixC0_15;
	input [`DWIDTH-1:0] matrixC1_0;
	input [`DWIDTH-1:0] matrixC1_1;
	input [`DWIDTH-1:0] matrixC1_2;
	input [`DWIDTH-1:0] matrixC1_3;
	input [`DWIDTH-1:0] matrixC1_4;
	input [`DWIDTH-1:0] matrixC1_5;
	input [`DWIDTH-1:0] matrixC1_6;
	input [`DWIDTH-1:0] matrixC1_7;
	input [`DWIDTH-1:0] matrixC1_8;
	input [`DWIDTH-1:0] matrixC1_9;
	input [`DWIDTH-1:0] matrixC1_10;
	input [`DWIDTH-1:0] matrixC1_11;
	input [`DWIDTH-1:0] matrixC1_12;
	input [`DWIDTH-1:0] matrixC1_13;
	input [`DWIDTH-1:0] matrixC1_14;
	input [`DWIDTH-1:0] matrixC1_15;
	input [`DWIDTH-1:0] matrixC2_0;
	input [`DWIDTH-1:0] matrixC2_1;
	input [`DWIDTH-1:0] matrixC2_2;
	input [`DWIDTH-1:0] matrixC2_3;
	input [`DWIDTH-1:0] matrixC2_4;
	input [`DWIDTH-1:0] matrixC2_5;
	input [`DWIDTH-1:0] matrixC2_6;
	input [`DWIDTH-1:0] matrixC2_7;
	input [`DWIDTH-1:0] matrixC2_8;
	input [`DWIDTH-1:0] matrixC2_9;
	input [`DWIDTH-1:0] matrixC2_10;
	input [`DWIDTH-1:0] matrixC2_11;
	input [`DWIDTH-1:0] matrixC2_12;
	input [`DWIDTH-1:0] matrixC2_13;
	input [`DWIDTH-1:0] matrixC2_14;
	input [`DWIDTH-1:0] matrixC2_15;
	input [`DWIDTH-1:0] matrixC3_0;
	input [`DWIDTH-1:0] matrixC3_1;
	input [`DWIDTH-1:0] matrixC3_2;
	input [`DWIDTH-1:0] matrixC3_3;
	input [`DWIDTH-1:0] matrixC3_4;
	input [`DWIDTH-1:0] matrixC3_5;
	input [`DWIDTH-1:0] matrixC3_6;
	input [`DWIDTH-1:0] matrixC3_7;
	input [`DWIDTH-1:0] matrixC3_8;
	input [`DWIDTH-1:0] matrixC3_9;
	input [`DWIDTH-1:0] matrixC3_10;
	input [`DWIDTH-1:0] matrixC3_11;
	input [`DWIDTH-1:0] matrixC3_12;
	input [`DWIDTH-1:0] matrixC3_13;
	input [`DWIDTH-1:0] matrixC3_14;
	input [`DWIDTH-1:0] matrixC3_15;
	input [`DWIDTH-1:0] matrixC4_0;
	input [`DWIDTH-1:0] matrixC4_1;
	input [`DWIDTH-1:0] matrixC4_2;
	input [`DWIDTH-1:0] matrixC4_3;
	input [`DWIDTH-1:0] matrixC4_4;
	input [`DWIDTH-1:0] matrixC4_5;
	input [`DWIDTH-1:0] matrixC4_6;
	input [`DWIDTH-1:0] matrixC4_7;
	input [`DWIDTH-1:0] matrixC4_8;
	input [`DWIDTH-1:0] matrixC4_9;
	input [`DWIDTH-1:0] matrixC4_10;
	input [`DWIDTH-1:0] matrixC4_11;
	input [`DWIDTH-1:0] matrixC4_12;
	input [`DWIDTH-1:0] matrixC4_13;
	input [`DWIDTH-1:0] matrixC4_14;
	input [`DWIDTH-1:0] matrixC4_15;
	input [`DWIDTH-1:0] matrixC5_0;
	input [`DWIDTH-1:0] matrixC5_1;
	input [`DWIDTH-1:0] matrixC5_2;
	input [`DWIDTH-1:0] matrixC5_3;
	input [`DWIDTH-1:0] matrixC5_4;
	input [`DWIDTH-1:0] matrixC5_5;
	input [`DWIDTH-1:0] matrixC5_6;
	input [`DWIDTH-1:0] matrixC5_7;
	input [`DWIDTH-1:0] matrixC5_8;
	input [`DWIDTH-1:0] matrixC5_9;
	input [`DWIDTH-1:0] matrixC5_10;
	input [`DWIDTH-1:0] matrixC5_11;
	input [`DWIDTH-1:0] matrixC5_12;
	input [`DWIDTH-1:0] matrixC5_13;
	input [`DWIDTH-1:0] matrixC5_14;
	input [`DWIDTH-1:0] matrixC5_15;
	input [`DWIDTH-1:0] matrixC6_0;
	input [`DWIDTH-1:0] matrixC6_1;
	input [`DWIDTH-1:0] matrixC6_2;
	input [`DWIDTH-1:0] matrixC6_3;
	input [`DWIDTH-1:0] matrixC6_4;
	input [`DWIDTH-1:0] matrixC6_5;
	input [`DWIDTH-1:0] matrixC6_6;
	input [`DWIDTH-1:0] matrixC6_7;
	input [`DWIDTH-1:0] matrixC6_8;
	input [`DWIDTH-1:0] matrixC6_9;
	input [`DWIDTH-1:0] matrixC6_10;
	input [`DWIDTH-1:0] matrixC6_11;
	input [`DWIDTH-1:0] matrixC6_12;
	input [`DWIDTH-1:0] matrixC6_13;
	input [`DWIDTH-1:0] matrixC6_14;
	input [`DWIDTH-1:0] matrixC6_15;
	input [`DWIDTH-1:0] matrixC7_0;
	input [`DWIDTH-1:0] matrixC7_1;
	input [`DWIDTH-1:0] matrixC7_2;
	input [`DWIDTH-1:0] matrixC7_3;
	input [`DWIDTH-1:0] matrixC7_4;
	input [`DWIDTH-1:0] matrixC7_5;
	input [`DWIDTH-1:0] matrixC7_6;
	input [`DWIDTH-1:0] matrixC7_7;
	input [`DWIDTH-1:0] matrixC7_8;
	input [`DWIDTH-1:0] matrixC7_9;
	input [`DWIDTH-1:0] matrixC7_10;
	input [`DWIDTH-1:0] matrixC7_11;
	input [`DWIDTH-1:0] matrixC7_12;
	input [`DWIDTH-1:0] matrixC7_13;
	input [`DWIDTH-1:0] matrixC7_14;
	input [`DWIDTH-1:0] matrixC7_15;
	input [`DWIDTH-1:0] matrixC8_0;
	input [`DWIDTH-1:0] matrixC8_1;
	input [`DWIDTH-1:0] matrixC8_2;
	input [`DWIDTH-1:0] matrixC8_3;
	input [`DWIDTH-1:0] matrixC8_4;
	input [`DWIDTH-1:0] matrixC8_5;
	input [`DWIDTH-1:0] matrixC8_6;
	input [`DWIDTH-1:0] matrixC8_7;
	input [`DWIDTH-1:0] matrixC8_8;
	input [`DWIDTH-1:0] matrixC8_9;
	input [`DWIDTH-1:0] matrixC8_10;
	input [`DWIDTH-1:0] matrixC8_11;
	input [`DWIDTH-1:0] matrixC8_12;
	input [`DWIDTH-1:0] matrixC8_13;
	input [`DWIDTH-1:0] matrixC8_14;
	input [`DWIDTH-1:0] matrixC8_15;
	input [`DWIDTH-1:0] matrixC9_0;
	input [`DWIDTH-1:0] matrixC9_1;
	input [`DWIDTH-1:0] matrixC9_2;
	input [`DWIDTH-1:0] matrixC9_3;
	input [`DWIDTH-1:0] matrixC9_4;
	input [`DWIDTH-1:0] matrixC9_5;
	input [`DWIDTH-1:0] matrixC9_6;
	input [`DWIDTH-1:0] matrixC9_7;
	input [`DWIDTH-1:0] matrixC9_8;
	input [`DWIDTH-1:0] matrixC9_9;
	input [`DWIDTH-1:0] matrixC9_10;
	input [`DWIDTH-1:0] matrixC9_11;
	input [`DWIDTH-1:0] matrixC9_12;
	input [`DWIDTH-1:0] matrixC9_13;
	input [`DWIDTH-1:0] matrixC9_14;
	input [`DWIDTH-1:0] matrixC9_15;
	input [`DWIDTH-1:0] matrixC10_0;
	input [`DWIDTH-1:0] matrixC10_1;
	input [`DWIDTH-1:0] matrixC10_2;
	input [`DWIDTH-1:0] matrixC10_3;
	input [`DWIDTH-1:0] matrixC10_4;
	input [`DWIDTH-1:0] matrixC10_5;
	input [`DWIDTH-1:0] matrixC10_6;
	input [`DWIDTH-1:0] matrixC10_7;
	input [`DWIDTH-1:0] matrixC10_8;
	input [`DWIDTH-1:0] matrixC10_9;
	input [`DWIDTH-1:0] matrixC10_10;
	input [`DWIDTH-1:0] matrixC10_11;
	input [`DWIDTH-1:0] matrixC10_12;
	input [`DWIDTH-1:0] matrixC10_13;
	input [`DWIDTH-1:0] matrixC10_14;
	input [`DWIDTH-1:0] matrixC10_15;
	input [`DWIDTH-1:0] matrixC11_0;
	input [`DWIDTH-1:0] matrixC11_1;
	input [`DWIDTH-1:0] matrixC11_2;
	input [`DWIDTH-1:0] matrixC11_3;
	input [`DWIDTH-1:0] matrixC11_4;
	input [`DWIDTH-1:0] matrixC11_5;
	input [`DWIDTH-1:0] matrixC11_6;
	input [`DWIDTH-1:0] matrixC11_7;
	input [`DWIDTH-1:0] matrixC11_8;
	input [`DWIDTH-1:0] matrixC11_9;
	input [`DWIDTH-1:0] matrixC11_10;
	input [`DWIDTH-1:0] matrixC11_11;
	input [`DWIDTH-1:0] matrixC11_12;
	input [`DWIDTH-1:0] matrixC11_13;
	input [`DWIDTH-1:0] matrixC11_14;
	input [`DWIDTH-1:0] matrixC11_15;
	input [`DWIDTH-1:0] matrixC12_0;
	input [`DWIDTH-1:0] matrixC12_1;
	input [`DWIDTH-1:0] matrixC12_2;
	input [`DWIDTH-1:0] matrixC12_3;
	input [`DWIDTH-1:0] matrixC12_4;
	input [`DWIDTH-1:0] matrixC12_5;
	input [`DWIDTH-1:0] matrixC12_6;
	input [`DWIDTH-1:0] matrixC12_7;
	input [`DWIDTH-1:0] matrixC12_8;
	input [`DWIDTH-1:0] matrixC12_9;
	input [`DWIDTH-1:0] matrixC12_10;
	input [`DWIDTH-1:0] matrixC12_11;
	input [`DWIDTH-1:0] matrixC12_12;
	input [`DWIDTH-1:0] matrixC12_13;
	input [`DWIDTH-1:0] matrixC12_14;
	input [`DWIDTH-1:0] matrixC12_15;
	input [`DWIDTH-1:0] matrixC13_0;
	input [`DWIDTH-1:0] matrixC13_1;
	input [`DWIDTH-1:0] matrixC13_2;
	input [`DWIDTH-1:0] matrixC13_3;
	input [`DWIDTH-1:0] matrixC13_4;
	input [`DWIDTH-1:0] matrixC13_5;
	input [`DWIDTH-1:0] matrixC13_6;
	input [`DWIDTH-1:0] matrixC13_7;
	input [`DWIDTH-1:0] matrixC13_8;
	input [`DWIDTH-1:0] matrixC13_9;
	input [`DWIDTH-1:0] matrixC13_10;
	input [`DWIDTH-1:0] matrixC13_11;
	input [`DWIDTH-1:0] matrixC13_12;
	input [`DWIDTH-1:0] matrixC13_13;
	input [`DWIDTH-1:0] matrixC13_14;
	input [`DWIDTH-1:0] matrixC13_15;
	input [`DWIDTH-1:0] matrixC14_0;
	input [`DWIDTH-1:0] matrixC14_1;
	input [`DWIDTH-1:0] matrixC14_2;
	input [`DWIDTH-1:0] matrixC14_3;
	input [`DWIDTH-1:0] matrixC14_4;
	input [`DWIDTH-1:0] matrixC14_5;
	input [`DWIDTH-1:0] matrixC14_6;
	input [`DWIDTH-1:0] matrixC14_7;
	input [`DWIDTH-1:0] matrixC14_8;
	input [`DWIDTH-1:0] matrixC14_9;
	input [`DWIDTH-1:0] matrixC14_10;
	input [`DWIDTH-1:0] matrixC14_11;
	input [`DWIDTH-1:0] matrixC14_12;
	input [`DWIDTH-1:0] matrixC14_13;
	input [`DWIDTH-1:0] matrixC14_14;
	input [`DWIDTH-1:0] matrixC14_15;
	input [`DWIDTH-1:0] matrixC15_0;
	input [`DWIDTH-1:0] matrixC15_1;
	input [`DWIDTH-1:0] matrixC15_2;
	input [`DWIDTH-1:0] matrixC15_3;
	input [`DWIDTH-1:0] matrixC15_4;
	input [`DWIDTH-1:0] matrixC15_5;
	input [`DWIDTH-1:0] matrixC15_6;
	input [`DWIDTH-1:0] matrixC15_7;
	input [`DWIDTH-1:0] matrixC15_8;
	input [`DWIDTH-1:0] matrixC15_9;
	input [`DWIDTH-1:0] matrixC15_10;
	input [`DWIDTH-1:0] matrixC15_11;
	input [`DWIDTH-1:0] matrixC15_12;
	input [`DWIDTH-1:0] matrixC15_13;
	input [`DWIDTH-1:0] matrixC15_14;
	input [`DWIDTH-1:0] matrixC15_15;
	

	
	output [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out;
	output [`AWIDTH-1:0] c_addr;
	output c_data_available;
	output row_latch_en;
	wire row_latch_en;
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to capture matrix C data from the PEs and shift it out
	//////////////////////////////////////////////////////////////////////////
	//assign row_latch_en = (clk_cnt==(`MAT_MUL_SIZE + (a_loc+b_loc) * `BB_MAT_MUL_SIZE + 10 +  `NUM_CYCLES_IN_MAC - 1));
	//Writing the line above to avoid multiplication:
	//assign row_latch_en = (clk_cnt==(`MAT_MUL_SIZE + ((a_loc+b_loc) << `LOG2_MAT_MUL_SIZE) + 10 +  `NUM_CYCLES_IN_MAC - 1));
	
	assign row_latch_en =  
						   ((clk_cnt == ((`final_mat_mul_size<<2) - `final_mat_mul_size - 1 +`NUM_CYCLES_IN_MAC)));
		
	reg c_data_available;
	reg [`AWIDTH-1:0] c_addr;
	reg start_capturing_c_data;
	integer counter;
	reg [16*`DWIDTH-1:0] c_data_out;
	reg [16*`DWIDTH-1:0] c_data_out_1;
	reg [16*`DWIDTH-1:0] c_data_out_2;
	reg [16*`DWIDTH-1:0] c_data_out_3;
	reg [16*`DWIDTH-1:0] c_data_out_4;
	reg [16*`DWIDTH-1:0] c_data_out_5;
	reg [16*`DWIDTH-1:0] c_data_out_6;
	reg [16*`DWIDTH-1:0] c_data_out_7;
	reg [16*`DWIDTH-1:0] c_data_out_8;
	reg [16*`DWIDTH-1:0] c_data_out_9;
	reg [16*`DWIDTH-1:0] c_data_out_10;
	reg [16*`DWIDTH-1:0] c_data_out_11;
	reg [16*`DWIDTH-1:0] c_data_out_12;
	reg [16*`DWIDTH-1:0] c_data_out_13;
	reg [16*`DWIDTH-1:0] c_data_out_14;
	reg [16*`DWIDTH-1:0] c_data_out_15;
	wire condition_to_start_shifting_output;
	assign condition_to_start_shifting_output = 
							  row_latch_en ;  
	
	  
	//For larger matmuls, this logic will have more entries in the case statement
	always @(posedge clk) begin
	  if (reset | ~start_mat_mul) begin
		start_capturing_c_data <= 1'b0;
		c_data_available <= 1'b0;
		c_addr <= address_mat_c + address_stride_c;
		c_data_out <= 0;
		counter <= 0;
	
		c_data_out_1 <= 0;
		c_data_out_2 <= 0;
		c_data_out_3 <= 0;
		c_data_out_4 <= 0;
		c_data_out_5 <= 0;
		c_data_out_6 <= 0;
		c_data_out_7 <= 0;
		c_data_out_8 <= 0;
		c_data_out_9 <= 0;
		c_data_out_10 <= 0;
		c_data_out_11 <= 0;
		c_data_out_12 <= 0;
		c_data_out_13 <= 0;
		c_data_out_14 <= 0;
		c_data_out_15 <= 0;
	  end else if (condition_to_start_shifting_output) begin
		start_capturing_c_data <= 1'b1;
		c_data_available <= 1'b1;
		c_addr <= c_addr - address_stride_c;
		c_data_out <= {matrixC15_15, matrixC14_15, matrixC13_15, matrixC12_15, matrixC11_15, matrixC10_15, matrixC9_15, matrixC8_15, matrixC7_15, matrixC6_15, matrixC5_15, matrixC4_15, matrixC3_15, matrixC2_15, matrixC1_15, matrixC0_15};
		  c_data_out_1 <= {matrixC15_14, matrixC14_14, matrixC13_14, matrixC12_14, matrixC11_14, matrixC10_14, matrixC9_14, matrixC8_14, matrixC7_14, matrixC6_14, matrixC5_14, matrixC4_14, matrixC3_14, matrixC2_14, matrixC1_14, matrixC0_14};
		  c_data_out_2 <= {matrixC15_13, matrixC14_13, matrixC13_13, matrixC12_13, matrixC11_13, matrixC10_13, matrixC9_13, matrixC8_13, matrixC7_13, matrixC6_13, matrixC5_13, matrixC4_13, matrixC3_13, matrixC2_13, matrixC1_13, matrixC0_13};
		  c_data_out_3 <= {matrixC15_12, matrixC14_12, matrixC13_12, matrixC12_12, matrixC11_12, matrixC10_12, matrixC9_12, matrixC8_12, matrixC7_12, matrixC6_12, matrixC5_12, matrixC4_12, matrixC3_12, matrixC2_12, matrixC1_12, matrixC0_12};
		  c_data_out_4 <= {matrixC15_11, matrixC14_11, matrixC13_11, matrixC12_11, matrixC11_11, matrixC10_11, matrixC9_11, matrixC8_11, matrixC7_11, matrixC6_11, matrixC5_11, matrixC4_11, matrixC3_11, matrixC2_11, matrixC1_11, matrixC0_11};
		  c_data_out_5 <= {matrixC15_10, matrixC14_10, matrixC13_10, matrixC12_10, matrixC11_10, matrixC10_10, matrixC9_10, matrixC8_10, matrixC7_10, matrixC6_10, matrixC5_10, matrixC4_10, matrixC3_10, matrixC2_10, matrixC1_10, matrixC0_10};
		  c_data_out_6 <= {matrixC15_9, matrixC14_9, matrixC13_9, matrixC12_9, matrixC11_9, matrixC10_9, matrixC9_9, matrixC8_9, matrixC7_9, matrixC6_9, matrixC5_9, matrixC4_9, matrixC3_9, matrixC2_9, matrixC1_9, matrixC0_9};
		  c_data_out_7 <= {matrixC15_8, matrixC14_8, matrixC13_8, matrixC12_8, matrixC11_8, matrixC10_8, matrixC9_8, matrixC8_8, matrixC7_8, matrixC6_8, matrixC5_8, matrixC4_8, matrixC3_8, matrixC2_8, matrixC1_8, matrixC0_8};
		  c_data_out_8 <= {matrixC15_7, matrixC14_7, matrixC13_7, matrixC12_7, matrixC11_7, matrixC10_7, matrixC9_7, matrixC8_7, matrixC7_7, matrixC6_7, matrixC5_7, matrixC4_7, matrixC3_7, matrixC2_7, matrixC1_7, matrixC0_7};
		  c_data_out_9 <= {matrixC15_6, matrixC14_6, matrixC13_6, matrixC12_6, matrixC11_6, matrixC10_6, matrixC9_6, matrixC8_6, matrixC7_6, matrixC6_6, matrixC5_6, matrixC4_6, matrixC3_6, matrixC2_6, matrixC1_6, matrixC0_6};
		  c_data_out_10 <= {matrixC15_5, matrixC14_5, matrixC13_5, matrixC12_5, matrixC11_5, matrixC10_5, matrixC9_5, matrixC8_5, matrixC7_5, matrixC6_5, matrixC5_5, matrixC4_5, matrixC3_5, matrixC2_5, matrixC1_5, matrixC0_5};
		  c_data_out_11 <= {matrixC15_4, matrixC14_4, matrixC13_4, matrixC12_4, matrixC11_4, matrixC10_4, matrixC9_4, matrixC8_4, matrixC7_4, matrixC6_4, matrixC5_4, matrixC4_4, matrixC3_4, matrixC2_4, matrixC1_4, matrixC0_4};
		  c_data_out_12 <= {matrixC15_3, matrixC14_3, matrixC13_3, matrixC12_3, matrixC11_3, matrixC10_3, matrixC9_3, matrixC8_3, matrixC7_3, matrixC6_3, matrixC5_3, matrixC4_3, matrixC3_3, matrixC2_3, matrixC1_3, matrixC0_3};
		  c_data_out_13 <= {matrixC15_2, matrixC14_2, matrixC13_2, matrixC12_2, matrixC11_2, matrixC10_2, matrixC9_2, matrixC8_2, matrixC7_2, matrixC6_2, matrixC5_2, matrixC4_2, matrixC3_2, matrixC2_2, matrixC1_2, matrixC0_2};
		  c_data_out_14 <= {matrixC15_1, matrixC14_1, matrixC13_1, matrixC12_1, matrixC11_1, matrixC10_1, matrixC9_1, matrixC8_1, matrixC7_1, matrixC6_1, matrixC5_1, matrixC4_1, matrixC3_1, matrixC2_1, matrixC1_1, matrixC0_1};
		  c_data_out_15 <= {matrixC15_0, matrixC14_0, matrixC13_0, matrixC12_0, matrixC11_0, matrixC10_0, matrixC9_0, matrixC8_0, matrixC7_0, matrixC6_0, matrixC5_0, matrixC4_0, matrixC3_0, matrixC2_0, matrixC1_0, matrixC0_0};
	
		counter <= counter + 1;
	  end else if (done_mat_mul) begin
		start_capturing_c_data <= 1'b0;
		c_data_available <= 1'b0;
		c_addr <= address_mat_c + address_stride_c;
		c_data_out <= 0;
	
		c_data_out_1 <= 0;
		c_data_out_2 <= 0;
		c_data_out_3 <= 0;
		c_data_out_4 <= 0;
		c_data_out_5 <= 0;
		c_data_out_6 <= 0;
		c_data_out_7 <= 0;
		c_data_out_8 <= 0;
		c_data_out_9 <= 0;
		c_data_out_10 <= 0;
		c_data_out_11 <= 0;
		c_data_out_12 <= 0;
		c_data_out_13 <= 0;
		c_data_out_14 <= 0;
		c_data_out_15 <= 0;
	  end 
	  else if (counter >= `MAT_MUL_SIZE) begin
		c_data_out <= c_data_out_1;
		c_addr <= c_addr - address_stride_c; 
	
		c_data_out_1 <= c_data_out_2;
		c_data_out_2 <= c_data_out_3;
		c_data_out_3 <= c_data_out_4;
		c_data_out_4 <= c_data_out_5;
		c_data_out_5 <= c_data_out_6;
		c_data_out_6 <= c_data_out_7;
		c_data_out_7 <= c_data_out_8;
		c_data_out_8 <= c_data_out_9;
		c_data_out_9 <= c_data_out_10;
		c_data_out_10 <= c_data_out_11;
		c_data_out_11 <= c_data_out_12;
		c_data_out_12 <= c_data_out_13;
		c_data_out_13 <= c_data_out_14;
		c_data_out_14 <= c_data_out_15;
		c_data_out_15 <= c_data_in;
	  end
	  else if (start_capturing_c_data) begin
		c_data_available <= 1'b1;
		c_addr <= c_addr - address_stride_c; 
		counter <= counter + 1;
		c_data_out <= c_data_out_1;
	
		c_data_out_1 <= c_data_out_2;
		c_data_out_2 <= c_data_out_3;
		c_data_out_3 <= c_data_out_4;
		c_data_out_4 <= c_data_out_5;
		c_data_out_5 <= c_data_out_6;
		c_data_out_6 <= c_data_out_7;
		c_data_out_7 <= c_data_out_8;
		c_data_out_8 <= c_data_out_9;
		c_data_out_9 <= c_data_out_10;
		c_data_out_10 <= c_data_out_11;
		c_data_out_11 <= c_data_out_12;
		c_data_out_12 <= c_data_out_13;
		c_data_out_13 <= c_data_out_14;
		c_data_out_14 <= c_data_out_15;
		c_data_out_15 <= c_data_in;
	  end
	end
	
	endmodule