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


module matmul_16_16_systolic(
	clk,
	reset,
	pe_reset,
	start_mat_mul,
	done_mat_mul,
	address_mat_a,
	address_mat_b,
	address_mat_c,
	address_stride_a,
	address_stride_b,
	address_stride_c,
	a_data,
	b_data,
	a_data_in, //Data values coming in from previous matmul - systolic connections
	b_data_in,
	c_data_in, //Data values coming in from previous matmul - systolic shifting
	c_data_out, //Data values going out to next matmul - systolic shifting
	a_data_out,
	b_data_out,
	a_addr,
	b_addr,
	c_addr,
	c_data_available,
   
	validity_mask_a_rows,
	validity_mask_a_cols,
	validity_mask_b_rows,
	validity_mask_b_cols,
	 
	final_mat_mul_size,
	 
	a_loc,
	b_loc
   );
   
	input clk;
	input reset;
	input pe_reset;
	input start_mat_mul;
	input [`AWIDTH-1:0] address_mat_a;
	input [`AWIDTH-1:0] address_mat_b;
	input [`AWIDTH-1:0] address_mat_c;
	input [`ADDR_STRIDE_WIDTH-1:0] address_stride_a;
	input [`ADDR_STRIDE_WIDTH-1:0] address_stride_b;
	input [`ADDR_STRIDE_WIDTH-1:0] address_stride_c;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_in;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_in;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_in;
	input [`MASK_WIDTH-1:0] validity_mask_a_rows;
	input [`MASK_WIDTH-1:0] validity_mask_a_cols;
	input [`MASK_WIDTH-1:0] validity_mask_b_rows;
	input [`MASK_WIDTH-1:0] validity_mask_b_cols;
	input [7:0] final_mat_mul_size;
	input [7:0] a_loc;
	input [7:0] b_loc;

	output done_mat_mul;
	output [`MAT_MUL_SIZE*`DWIDTH-1:0] c_data_out;
	output [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data_out;
	output [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data_out;
	output [`AWIDTH-1:0] a_addr;
	output [`AWIDTH-1:0] b_addr;
	output [`AWIDTH-1:0] c_addr;
	output c_data_available;
   

   
   //7:0 is okay here. We aren't going to make a matmul larger than 128x128
   //In fact, these will get optimized out by the synthesis tool, because
   //we hardcode them at the instantiation level.

   
   //////////////////////////////////////////////////////////////////////////
   // Logic for clock counting and when to assert done
   //////////////////////////////////////////////////////////////////////////
   
   reg done_mat_mul;
   //This is 7 bits because the expectation is that clock count will be pretty
   //small. For large matmuls, this will need to increased to have more bits.
   //In general, a systolic multiplier takes 4*N-2+P cycles, where N is the size 
   //of the matmul and P is the number of pipleine stages in the MAC block.
   reg [7:0] clk_cnt;
   
   //Finding out number of cycles to assert matmul done.
   //When we have to save the outputs to accumulators, then we don't need to
   //shift out data. So, we can assert done_mat_mul early.
   //In the normal case, we have to include the time to shift out the results. 
   //Note: the count expression used to contain "4*final_mat_mul_size", but 
   //to avoid multiplication, we now use "final_mat_mul_size<<2"
   wire [7:0] clk_cnt_for_done;
   
   assign clk_cnt_for_done = 
							 ((`final_mat_mul_size<<2) - 2 + `NUM_CYCLES_IN_MAC);  
	   
   always @(posedge clk) begin
	 if (reset || ~start_mat_mul) begin
	   clk_cnt <= 0;
	   done_mat_mul <= 0;
	 end
	 else if (clk_cnt == clk_cnt_for_done) begin
	   done_mat_mul <= 1;
	   clk_cnt <= clk_cnt + 1;
   
	 end
	 else if (done_mat_mul == 0) begin
	   clk_cnt <= clk_cnt + 1;
   
	 end    
	 else begin
	   done_mat_mul <= 0;
	   clk_cnt <= clk_cnt + 1;
	 end
   end
   wire [`DWIDTH-1:0] a0_data;
   wire [`DWIDTH-1:0] a1_data;
   wire [`DWIDTH-1:0] a2_data;
   wire [`DWIDTH-1:0] a3_data;
   wire [`DWIDTH-1:0] a4_data;
   wire [`DWIDTH-1:0] a5_data;
   wire [`DWIDTH-1:0] a6_data;
   wire [`DWIDTH-1:0] a7_data;
   wire [`DWIDTH-1:0] a8_data;
   wire [`DWIDTH-1:0] a9_data;
   wire [`DWIDTH-1:0] a10_data;
   wire [`DWIDTH-1:0] a11_data;
   wire [`DWIDTH-1:0] a12_data;
   wire [`DWIDTH-1:0] a13_data;
   wire [`DWIDTH-1:0] a14_data;
   wire [`DWIDTH-1:0] a15_data;
   wire [`DWIDTH-1:0] b0_data;
   wire [`DWIDTH-1:0] b1_data;
   wire [`DWIDTH-1:0] b2_data;
   wire [`DWIDTH-1:0] b3_data;
   wire [`DWIDTH-1:0] b4_data;
   wire [`DWIDTH-1:0] b5_data;
   wire [`DWIDTH-1:0] b6_data;
   wire [`DWIDTH-1:0] b7_data;
   wire [`DWIDTH-1:0] b8_data;
   wire [`DWIDTH-1:0] b9_data;
   wire [`DWIDTH-1:0] b10_data;
   wire [`DWIDTH-1:0] b11_data;
   wire [`DWIDTH-1:0] b12_data;
   wire [`DWIDTH-1:0] b13_data;
   wire [`DWIDTH-1:0] b14_data;
   wire [`DWIDTH-1:0] b15_data;
   wire [`DWIDTH-1:0] a1_data_delayed_1;
   wire [`DWIDTH-1:0] a2_data_delayed_1;
   wire [`DWIDTH-1:0] a2_data_delayed_2;
   wire [`DWIDTH-1:0] a3_data_delayed_1;
   wire [`DWIDTH-1:0] a3_data_delayed_2;
   wire [`DWIDTH-1:0] a3_data_delayed_3;
   wire [`DWIDTH-1:0] a4_data_delayed_1;
   wire [`DWIDTH-1:0] a4_data_delayed_2;
   wire [`DWIDTH-1:0] a4_data_delayed_3;
   wire [`DWIDTH-1:0] a4_data_delayed_4;
   wire [`DWIDTH-1:0] a5_data_delayed_1;
   wire [`DWIDTH-1:0] a5_data_delayed_2;
   wire [`DWIDTH-1:0] a5_data_delayed_3;
   wire [`DWIDTH-1:0] a5_data_delayed_4;
   wire [`DWIDTH-1:0] a5_data_delayed_5;
   wire [`DWIDTH-1:0] a6_data_delayed_1;
   wire [`DWIDTH-1:0] a6_data_delayed_2;
   wire [`DWIDTH-1:0] a6_data_delayed_3;
   wire [`DWIDTH-1:0] a6_data_delayed_4;
   wire [`DWIDTH-1:0] a6_data_delayed_5;
   wire [`DWIDTH-1:0] a6_data_delayed_6;
   wire [`DWIDTH-1:0] a7_data_delayed_1;
   wire [`DWIDTH-1:0] a7_data_delayed_2;
   wire [`DWIDTH-1:0] a7_data_delayed_3;
   wire [`DWIDTH-1:0] a7_data_delayed_4;
   wire [`DWIDTH-1:0] a7_data_delayed_5;
   wire [`DWIDTH-1:0] a7_data_delayed_6;
   wire [`DWIDTH-1:0] a7_data_delayed_7;
   wire [`DWIDTH-1:0] a8_data_delayed_1;
   wire [`DWIDTH-1:0] a8_data_delayed_2;
   wire [`DWIDTH-1:0] a8_data_delayed_3;
   wire [`DWIDTH-1:0] a8_data_delayed_4;
   wire [`DWIDTH-1:0] a8_data_delayed_5;
   wire [`DWIDTH-1:0] a8_data_delayed_6;
   wire [`DWIDTH-1:0] a8_data_delayed_7;
   wire [`DWIDTH-1:0] a8_data_delayed_8;
   wire [`DWIDTH-1:0] a9_data_delayed_1;
   wire [`DWIDTH-1:0] a9_data_delayed_2;
   wire [`DWIDTH-1:0] a9_data_delayed_3;
   wire [`DWIDTH-1:0] a9_data_delayed_4;
   wire [`DWIDTH-1:0] a9_data_delayed_5;
   wire [`DWIDTH-1:0] a9_data_delayed_6;
   wire [`DWIDTH-1:0] a9_data_delayed_7;
   wire [`DWIDTH-1:0] a9_data_delayed_8;
   wire [`DWIDTH-1:0] a9_data_delayed_9;
   wire [`DWIDTH-1:0] a10_data_delayed_1;
   wire [`DWIDTH-1:0] a10_data_delayed_2;
   wire [`DWIDTH-1:0] a10_data_delayed_3;
   wire [`DWIDTH-1:0] a10_data_delayed_4;
   wire [`DWIDTH-1:0] a10_data_delayed_5;
   wire [`DWIDTH-1:0] a10_data_delayed_6;
   wire [`DWIDTH-1:0] a10_data_delayed_7;
   wire [`DWIDTH-1:0] a10_data_delayed_8;
   wire [`DWIDTH-1:0] a10_data_delayed_9;
   wire [`DWIDTH-1:0] a10_data_delayed_10;
   wire [`DWIDTH-1:0] a11_data_delayed_1;
   wire [`DWIDTH-1:0] a11_data_delayed_2;
   wire [`DWIDTH-1:0] a11_data_delayed_3;
   wire [`DWIDTH-1:0] a11_data_delayed_4;
   wire [`DWIDTH-1:0] a11_data_delayed_5;
   wire [`DWIDTH-1:0] a11_data_delayed_6;
   wire [`DWIDTH-1:0] a11_data_delayed_7;
   wire [`DWIDTH-1:0] a11_data_delayed_8;
   wire [`DWIDTH-1:0] a11_data_delayed_9;
   wire [`DWIDTH-1:0] a11_data_delayed_10;
   wire [`DWIDTH-1:0] a11_data_delayed_11;
   wire [`DWIDTH-1:0] a12_data_delayed_1;
   wire [`DWIDTH-1:0] a12_data_delayed_2;
   wire [`DWIDTH-1:0] a12_data_delayed_3;
   wire [`DWIDTH-1:0] a12_data_delayed_4;
   wire [`DWIDTH-1:0] a12_data_delayed_5;
   wire [`DWIDTH-1:0] a12_data_delayed_6;
   wire [`DWIDTH-1:0] a12_data_delayed_7;
   wire [`DWIDTH-1:0] a12_data_delayed_8;
   wire [`DWIDTH-1:0] a12_data_delayed_9;
   wire [`DWIDTH-1:0] a12_data_delayed_10;
   wire [`DWIDTH-1:0] a12_data_delayed_11;
   wire [`DWIDTH-1:0] a12_data_delayed_12;
   wire [`DWIDTH-1:0] a13_data_delayed_1;
   wire [`DWIDTH-1:0] a13_data_delayed_2;
   wire [`DWIDTH-1:0] a13_data_delayed_3;
   wire [`DWIDTH-1:0] a13_data_delayed_4;
   wire [`DWIDTH-1:0] a13_data_delayed_5;
   wire [`DWIDTH-1:0] a13_data_delayed_6;
   wire [`DWIDTH-1:0] a13_data_delayed_7;
   wire [`DWIDTH-1:0] a13_data_delayed_8;
   wire [`DWIDTH-1:0] a13_data_delayed_9;
   wire [`DWIDTH-1:0] a13_data_delayed_10;
   wire [`DWIDTH-1:0] a13_data_delayed_11;
   wire [`DWIDTH-1:0] a13_data_delayed_12;
   wire [`DWIDTH-1:0] a13_data_delayed_13;
   wire [`DWIDTH-1:0] a14_data_delayed_1;
   wire [`DWIDTH-1:0] a14_data_delayed_2;
   wire [`DWIDTH-1:0] a14_data_delayed_3;
   wire [`DWIDTH-1:0] a14_data_delayed_4;
   wire [`DWIDTH-1:0] a14_data_delayed_5;
   wire [`DWIDTH-1:0] a14_data_delayed_6;
   wire [`DWIDTH-1:0] a14_data_delayed_7;
   wire [`DWIDTH-1:0] a14_data_delayed_8;
   wire [`DWIDTH-1:0] a14_data_delayed_9;
   wire [`DWIDTH-1:0] a14_data_delayed_10;
   wire [`DWIDTH-1:0] a14_data_delayed_11;
   wire [`DWIDTH-1:0] a14_data_delayed_12;
   wire [`DWIDTH-1:0] a14_data_delayed_13;
   wire [`DWIDTH-1:0] a14_data_delayed_14;
   wire [`DWIDTH-1:0] a15_data_delayed_1;
   wire [`DWIDTH-1:0] a15_data_delayed_2;
   wire [`DWIDTH-1:0] a15_data_delayed_3;
   wire [`DWIDTH-1:0] a15_data_delayed_4;
   wire [`DWIDTH-1:0] a15_data_delayed_5;
   wire [`DWIDTH-1:0] a15_data_delayed_6;
   wire [`DWIDTH-1:0] a15_data_delayed_7;
   wire [`DWIDTH-1:0] a15_data_delayed_8;
   wire [`DWIDTH-1:0] a15_data_delayed_9;
   wire [`DWIDTH-1:0] a15_data_delayed_10;
   wire [`DWIDTH-1:0] a15_data_delayed_11;
   wire [`DWIDTH-1:0] a15_data_delayed_12;
   wire [`DWIDTH-1:0] a15_data_delayed_13;
   wire [`DWIDTH-1:0] a15_data_delayed_14;
   wire [`DWIDTH-1:0] a15_data_delayed_15;
   wire [`DWIDTH-1:0] b1_data_delayed_1;
   wire [`DWIDTH-1:0] b2_data_delayed_1;
   wire [`DWIDTH-1:0] b2_data_delayed_2;
   wire [`DWIDTH-1:0] b3_data_delayed_1;
   wire [`DWIDTH-1:0] b3_data_delayed_2;
   wire [`DWIDTH-1:0] b3_data_delayed_3;
   wire [`DWIDTH-1:0] b4_data_delayed_1;
   wire [`DWIDTH-1:0] b4_data_delayed_2;
   wire [`DWIDTH-1:0] b4_data_delayed_3;
   wire [`DWIDTH-1:0] b4_data_delayed_4;
   wire [`DWIDTH-1:0] b5_data_delayed_1;
   wire [`DWIDTH-1:0] b5_data_delayed_2;
   wire [`DWIDTH-1:0] b5_data_delayed_3;
   wire [`DWIDTH-1:0] b5_data_delayed_4;
   wire [`DWIDTH-1:0] b5_data_delayed_5;
   wire [`DWIDTH-1:0] b6_data_delayed_1;
   wire [`DWIDTH-1:0] b6_data_delayed_2;
   wire [`DWIDTH-1:0] b6_data_delayed_3;
   wire [`DWIDTH-1:0] b6_data_delayed_4;
   wire [`DWIDTH-1:0] b6_data_delayed_5;
   wire [`DWIDTH-1:0] b6_data_delayed_6;
   wire [`DWIDTH-1:0] b7_data_delayed_1;
   wire [`DWIDTH-1:0] b7_data_delayed_2;
   wire [`DWIDTH-1:0] b7_data_delayed_3;
   wire [`DWIDTH-1:0] b7_data_delayed_4;
   wire [`DWIDTH-1:0] b7_data_delayed_5;
   wire [`DWIDTH-1:0] b7_data_delayed_6;
   wire [`DWIDTH-1:0] b7_data_delayed_7;
   wire [`DWIDTH-1:0] b8_data_delayed_1;
   wire [`DWIDTH-1:0] b8_data_delayed_2;
   wire [`DWIDTH-1:0] b8_data_delayed_3;
   wire [`DWIDTH-1:0] b8_data_delayed_4;
   wire [`DWIDTH-1:0] b8_data_delayed_5;
   wire [`DWIDTH-1:0] b8_data_delayed_6;
   wire [`DWIDTH-1:0] b8_data_delayed_7;
   wire [`DWIDTH-1:0] b8_data_delayed_8;
   wire [`DWIDTH-1:0] b9_data_delayed_1;
   wire [`DWIDTH-1:0] b9_data_delayed_2;
   wire [`DWIDTH-1:0] b9_data_delayed_3;
   wire [`DWIDTH-1:0] b9_data_delayed_4;
   wire [`DWIDTH-1:0] b9_data_delayed_5;
   wire [`DWIDTH-1:0] b9_data_delayed_6;
   wire [`DWIDTH-1:0] b9_data_delayed_7;
   wire [`DWIDTH-1:0] b9_data_delayed_8;
   wire [`DWIDTH-1:0] b9_data_delayed_9;
   wire [`DWIDTH-1:0] b10_data_delayed_1;
   wire [`DWIDTH-1:0] b10_data_delayed_2;
   wire [`DWIDTH-1:0] b10_data_delayed_3;
   wire [`DWIDTH-1:0] b10_data_delayed_4;
   wire [`DWIDTH-1:0] b10_data_delayed_5;
   wire [`DWIDTH-1:0] b10_data_delayed_6;
   wire [`DWIDTH-1:0] b10_data_delayed_7;
   wire [`DWIDTH-1:0] b10_data_delayed_8;
   wire [`DWIDTH-1:0] b10_data_delayed_9;
   wire [`DWIDTH-1:0] b10_data_delayed_10;
   wire [`DWIDTH-1:0] b11_data_delayed_1;
   wire [`DWIDTH-1:0] b11_data_delayed_2;
   wire [`DWIDTH-1:0] b11_data_delayed_3;
   wire [`DWIDTH-1:0] b11_data_delayed_4;
   wire [`DWIDTH-1:0] b11_data_delayed_5;
   wire [`DWIDTH-1:0] b11_data_delayed_6;
   wire [`DWIDTH-1:0] b11_data_delayed_7;
   wire [`DWIDTH-1:0] b11_data_delayed_8;
   wire [`DWIDTH-1:0] b11_data_delayed_9;
   wire [`DWIDTH-1:0] b11_data_delayed_10;
   wire [`DWIDTH-1:0] b11_data_delayed_11;
   wire [`DWIDTH-1:0] b12_data_delayed_1;
   wire [`DWIDTH-1:0] b12_data_delayed_2;
   wire [`DWIDTH-1:0] b12_data_delayed_3;
   wire [`DWIDTH-1:0] b12_data_delayed_4;
   wire [`DWIDTH-1:0] b12_data_delayed_5;
   wire [`DWIDTH-1:0] b12_data_delayed_6;
   wire [`DWIDTH-1:0] b12_data_delayed_7;
   wire [`DWIDTH-1:0] b12_data_delayed_8;
   wire [`DWIDTH-1:0] b12_data_delayed_9;
   wire [`DWIDTH-1:0] b12_data_delayed_10;
   wire [`DWIDTH-1:0] b12_data_delayed_11;
   wire [`DWIDTH-1:0] b12_data_delayed_12;
   wire [`DWIDTH-1:0] b13_data_delayed_1;
   wire [`DWIDTH-1:0] b13_data_delayed_2;
   wire [`DWIDTH-1:0] b13_data_delayed_3;
   wire [`DWIDTH-1:0] b13_data_delayed_4;
   wire [`DWIDTH-1:0] b13_data_delayed_5;
   wire [`DWIDTH-1:0] b13_data_delayed_6;
   wire [`DWIDTH-1:0] b13_data_delayed_7;
   wire [`DWIDTH-1:0] b13_data_delayed_8;
   wire [`DWIDTH-1:0] b13_data_delayed_9;
   wire [`DWIDTH-1:0] b13_data_delayed_10;
   wire [`DWIDTH-1:0] b13_data_delayed_11;
   wire [`DWIDTH-1:0] b13_data_delayed_12;
   wire [`DWIDTH-1:0] b13_data_delayed_13;
   wire [`DWIDTH-1:0] b14_data_delayed_1;
   wire [`DWIDTH-1:0] b14_data_delayed_2;
   wire [`DWIDTH-1:0] b14_data_delayed_3;
   wire [`DWIDTH-1:0] b14_data_delayed_4;
   wire [`DWIDTH-1:0] b14_data_delayed_5;
   wire [`DWIDTH-1:0] b14_data_delayed_6;
   wire [`DWIDTH-1:0] b14_data_delayed_7;
   wire [`DWIDTH-1:0] b14_data_delayed_8;
   wire [`DWIDTH-1:0] b14_data_delayed_9;
   wire [`DWIDTH-1:0] b14_data_delayed_10;
   wire [`DWIDTH-1:0] b14_data_delayed_11;
   wire [`DWIDTH-1:0] b14_data_delayed_12;
   wire [`DWIDTH-1:0] b14_data_delayed_13;
   wire [`DWIDTH-1:0] b14_data_delayed_14;
   wire [`DWIDTH-1:0] b15_data_delayed_1;
   wire [`DWIDTH-1:0] b15_data_delayed_2;
   wire [`DWIDTH-1:0] b15_data_delayed_3;
   wire [`DWIDTH-1:0] b15_data_delayed_4;
   wire [`DWIDTH-1:0] b15_data_delayed_5;
   wire [`DWIDTH-1:0] b15_data_delayed_6;
   wire [`DWIDTH-1:0] b15_data_delayed_7;
   wire [`DWIDTH-1:0] b15_data_delayed_8;
   wire [`DWIDTH-1:0] b15_data_delayed_9;
   wire [`DWIDTH-1:0] b15_data_delayed_10;
   wire [`DWIDTH-1:0] b15_data_delayed_11;
   wire [`DWIDTH-1:0] b15_data_delayed_12;
   wire [`DWIDTH-1:0] b15_data_delayed_13;
   wire [`DWIDTH-1:0] b15_data_delayed_14;
   wire [`DWIDTH-1:0] b15_data_delayed_15;
   
   
   //////////////////////////////////////////////////////////////////////////
   // Instantiation of systolic data setup
   //////////////////////////////////////////////////////////////////////////
   systolic_data_setup u_systolic_data_setup(
   .clk(clk),
   .reset(reset),
   .start_mat_mul(start_mat_mul),
   .a_addr(a_addr),
   .b_addr(b_addr),
   .address_mat_a(address_mat_a),
   .address_mat_b(address_mat_b),
   .address_stride_a(address_stride_a),
   .address_stride_b(address_stride_b),
   .a_data(a_data),
   .b_data(b_data),
   .clk_cnt(clk_cnt),
   .a0_data(a0_data),
   .b0_data(b0_data),
   .a1_data_delayed_1(a1_data_delayed_1),
   .b1_data_delayed_1(b1_data_delayed_1),
   .a2_data_delayed_2(a2_data_delayed_2),
   .b2_data_delayed_2(b2_data_delayed_2),
   .a3_data_delayed_3(a3_data_delayed_3),
   .b3_data_delayed_3(b3_data_delayed_3),
   .a4_data_delayed_4(a4_data_delayed_4),
   .b4_data_delayed_4(b4_data_delayed_4),
   .a5_data_delayed_5(a5_data_delayed_5),
   .b5_data_delayed_5(b5_data_delayed_5),
   .a6_data_delayed_6(a6_data_delayed_6),
   .b6_data_delayed_6(b6_data_delayed_6),
   .a7_data_delayed_7(a7_data_delayed_7),
   .b7_data_delayed_7(b7_data_delayed_7),
   .a8_data_delayed_8(a8_data_delayed_8),
   .b8_data_delayed_8(b8_data_delayed_8),
   .a9_data_delayed_9(a9_data_delayed_9),
   .b9_data_delayed_9(b9_data_delayed_9),
   .a10_data_delayed_10(a10_data_delayed_10),
   .b10_data_delayed_10(b10_data_delayed_10),
   .a11_data_delayed_11(a11_data_delayed_11),
   .b11_data_delayed_11(b11_data_delayed_11),
   .a12_data_delayed_12(a12_data_delayed_12),
   .b12_data_delayed_12(b12_data_delayed_12),
   .a13_data_delayed_13(a13_data_delayed_13),
   .b13_data_delayed_13(b13_data_delayed_13),
   .a14_data_delayed_14(a14_data_delayed_14),
   .b14_data_delayed_14(b14_data_delayed_14),
   .a15_data_delayed_15(a15_data_delayed_15),
   .b15_data_delayed_15(b15_data_delayed_15),
   
   .validity_mask_a_rows(validity_mask_a_rows),
   .validity_mask_a_cols(validity_mask_a_cols),
   .validity_mask_b_rows(validity_mask_b_rows),
   .validity_mask_b_cols(validity_mask_b_cols),
   
   .final_mat_mul_size(final_mat_mul_size),
	 
   .a_loc(a_loc),
   .b_loc(b_loc)
   );
   
   //////////////////////////////////////////////////////////////////////////
   // Logic to mux data_in coming from neighboring matmuls
   //////////////////////////////////////////////////////////////////////////
   wire [`DWIDTH-1:0] a0;
   wire [`DWIDTH-1:0] a1;
   wire [`DWIDTH-1:0] a2;
   wire [`DWIDTH-1:0] a3;
   wire [`DWIDTH-1:0] a4;
   wire [`DWIDTH-1:0] a5;
   wire [`DWIDTH-1:0] a6;
   wire [`DWIDTH-1:0] a7;
   wire [`DWIDTH-1:0] a8;
   wire [`DWIDTH-1:0] a9;
   wire [`DWIDTH-1:0] a10;
   wire [`DWIDTH-1:0] a11;
   wire [`DWIDTH-1:0] a12;
   wire [`DWIDTH-1:0] a13;
   wire [`DWIDTH-1:0] a14;
   wire [`DWIDTH-1:0] a15;
   wire [`DWIDTH-1:0] b0;
   wire [`DWIDTH-1:0] b1;
   wire [`DWIDTH-1:0] b2;
   wire [`DWIDTH-1:0] b3;
   wire [`DWIDTH-1:0] b4;
   wire [`DWIDTH-1:0] b5;
   wire [`DWIDTH-1:0] b6;
   wire [`DWIDTH-1:0] b7;
   wire [`DWIDTH-1:0] b8;
   wire [`DWIDTH-1:0] b9;
   wire [`DWIDTH-1:0] b10;
   wire [`DWIDTH-1:0] b11;
   wire [`DWIDTH-1:0] b12;
   wire [`DWIDTH-1:0] b13;
   wire [`DWIDTH-1:0] b14;
   wire [`DWIDTH-1:0] b15;
   
   wire [`DWIDTH-1:0] a0_data_in;
   wire [`DWIDTH-1:0] a1_data_in;
   wire [`DWIDTH-1:0] a2_data_in;
   wire [`DWIDTH-1:0] a3_data_in;
   wire [`DWIDTH-1:0] a4_data_in;
   wire [`DWIDTH-1:0] a5_data_in;
   wire [`DWIDTH-1:0] a6_data_in;
   wire [`DWIDTH-1:0] a7_data_in;
   wire [`DWIDTH-1:0] a8_data_in;
   wire [`DWIDTH-1:0] a9_data_in;
   wire [`DWIDTH-1:0] a10_data_in;
   wire [`DWIDTH-1:0] a11_data_in;
   wire [`DWIDTH-1:0] a12_data_in;
   wire [`DWIDTH-1:0] a13_data_in;
   wire [`DWIDTH-1:0] a14_data_in;
   wire [`DWIDTH-1:0] a15_data_in;
   
   assign a0_data_in = a_data_in[1*`DWIDTH-1:0*`DWIDTH];
   assign a1_data_in = a_data_in[2*`DWIDTH-1:1*`DWIDTH];
   assign a2_data_in = a_data_in[3*`DWIDTH-1:2*`DWIDTH];
   assign a3_data_in = a_data_in[4*`DWIDTH-1:3*`DWIDTH];
   assign a4_data_in = a_data_in[5*`DWIDTH-1:4*`DWIDTH];
   assign a5_data_in = a_data_in[6*`DWIDTH-1:5*`DWIDTH];
   assign a6_data_in = a_data_in[7*`DWIDTH-1:6*`DWIDTH];
   assign a7_data_in = a_data_in[8*`DWIDTH-1:7*`DWIDTH];
   assign a8_data_in = a_data_in[9*`DWIDTH-1:8*`DWIDTH];
   assign a9_data_in = a_data_in[10*`DWIDTH-1:9*`DWIDTH];
   assign a10_data_in = a_data_in[11*`DWIDTH-1:10*`DWIDTH];
   assign a11_data_in = a_data_in[12*`DWIDTH-1:11*`DWIDTH];
   assign a12_data_in = a_data_in[13*`DWIDTH-1:12*`DWIDTH];
   assign a13_data_in = a_data_in[14*`DWIDTH-1:13*`DWIDTH];
   assign a14_data_in = a_data_in[15*`DWIDTH-1:14*`DWIDTH];
   assign a15_data_in = a_data_in[16*`DWIDTH-1:15*`DWIDTH];
   
   wire [`DWIDTH-1:0] b0_data_in;
   wire [`DWIDTH-1:0] b1_data_in;
   wire [`DWIDTH-1:0] b2_data_in;
   wire [`DWIDTH-1:0] b3_data_in;
   wire [`DWIDTH-1:0] b4_data_in;
   wire [`DWIDTH-1:0] b5_data_in;
   wire [`DWIDTH-1:0] b6_data_in;
   wire [`DWIDTH-1:0] b7_data_in;
   wire [`DWIDTH-1:0] b8_data_in;
   wire [`DWIDTH-1:0] b9_data_in;
   wire [`DWIDTH-1:0] b10_data_in;
   wire [`DWIDTH-1:0] b11_data_in;
   wire [`DWIDTH-1:0] b12_data_in;
   wire [`DWIDTH-1:0] b13_data_in;
   wire [`DWIDTH-1:0] b14_data_in;
   wire [`DWIDTH-1:0] b15_data_in;
   
   assign b0_data_in = b_data_in[1*`DWIDTH-1:0*`DWIDTH];
   assign b1_data_in = b_data_in[2*`DWIDTH-1:1*`DWIDTH];
   assign b2_data_in = b_data_in[3*`DWIDTH-1:2*`DWIDTH];
   assign b3_data_in = b_data_in[4*`DWIDTH-1:3*`DWIDTH];
   assign b4_data_in = b_data_in[5*`DWIDTH-1:4*`DWIDTH];
   assign b5_data_in = b_data_in[6*`DWIDTH-1:5*`DWIDTH];
   assign b6_data_in = b_data_in[7*`DWIDTH-1:6*`DWIDTH];
   assign b7_data_in = b_data_in[8*`DWIDTH-1:7*`DWIDTH];
   assign b8_data_in = b_data_in[9*`DWIDTH-1:8*`DWIDTH];
   assign b9_data_in = b_data_in[10*`DWIDTH-1:9*`DWIDTH];
   assign b10_data_in = b_data_in[11*`DWIDTH-1:10*`DWIDTH];
   assign b11_data_in = b_data_in[12*`DWIDTH-1:11*`DWIDTH];
   assign b12_data_in = b_data_in[13*`DWIDTH-1:12*`DWIDTH];
   assign b13_data_in = b_data_in[14*`DWIDTH-1:13*`DWIDTH];
   assign b14_data_in = b_data_in[15*`DWIDTH-1:14*`DWIDTH];
   assign b15_data_in = b_data_in[16*`DWIDTH-1:15*`DWIDTH];
   
   assign a0 = (b_loc==0) ? a0_data           : a0_data_in;
   assign a1 = (b_loc==0) ? a1_data_delayed_1 : a1_data_in;
   assign a2 = (b_loc==0) ? a2_data_delayed_2 : a2_data_in;
   assign a3 = (b_loc==0) ? a3_data_delayed_3 : a3_data_in;
   assign a4 = (b_loc==0) ? a4_data_delayed_4 : a4_data_in;
   assign a5 = (b_loc==0) ? a5_data_delayed_5 : a5_data_in;
   assign a6 = (b_loc==0) ? a6_data_delayed_6 : a6_data_in;
   assign a7 = (b_loc==0) ? a7_data_delayed_7 : a7_data_in;
   assign a8 = (b_loc==0) ? a8_data_delayed_8 : a8_data_in;
   assign a9 = (b_loc==0) ? a9_data_delayed_9 : a9_data_in;
   assign a10 = (b_loc==0) ? a10_data_delayed_10 : a10_data_in;
   assign a11 = (b_loc==0) ? a11_data_delayed_11 : a11_data_in;
   assign a12 = (b_loc==0) ? a12_data_delayed_12 : a12_data_in;
   assign a13 = (b_loc==0) ? a13_data_delayed_13 : a13_data_in;
   assign a14 = (b_loc==0) ? a14_data_delayed_14 : a14_data_in;
   assign a15 = (b_loc==0) ? a15_data_delayed_15 : a15_data_in;
   
   assign b0 = (a_loc==0) ? b0_data           : b0_data_in;
   assign b1 = (a_loc==0) ? b1_data_delayed_1 : b1_data_in;
   assign b2 = (a_loc==0) ? b2_data_delayed_2 : b2_data_in;
   assign b3 = (a_loc==0) ? b3_data_delayed_3 : b3_data_in;
   assign b4 = (a_loc==0) ? b4_data_delayed_4 : b4_data_in;
   assign b5 = (a_loc==0) ? b5_data_delayed_5 : b5_data_in;
   assign b6 = (a_loc==0) ? b6_data_delayed_6 : b6_data_in;
   assign b7 = (a_loc==0) ? b7_data_delayed_7 : b7_data_in;
   assign b8 = (a_loc==0) ? b8_data_delayed_8 : b8_data_in;
   assign b9 = (a_loc==0) ? b9_data_delayed_9 : b9_data_in;
   assign b10 = (a_loc==0) ? b10_data_delayed_10 : b10_data_in;
   assign b11 = (a_loc==0) ? b11_data_delayed_11 : b11_data_in;
   assign b12 = (a_loc==0) ? b12_data_delayed_12 : b12_data_in;
   assign b13 = (a_loc==0) ? b13_data_delayed_13 : b13_data_in;
   assign b14 = (a_loc==0) ? b14_data_delayed_14 : b14_data_in;
   assign b15 = (a_loc==0) ? b15_data_delayed_15 : b15_data_in;
   
   wire [`DWIDTH-1:0] matrixC0_0;
   wire [`DWIDTH-1:0] matrixC0_1;
   wire [`DWIDTH-1:0] matrixC0_2;
   wire [`DWIDTH-1:0] matrixC0_3;
   wire [`DWIDTH-1:0] matrixC0_4;
   wire [`DWIDTH-1:0] matrixC0_5;
   wire [`DWIDTH-1:0] matrixC0_6;
   wire [`DWIDTH-1:0] matrixC0_7;
   wire [`DWIDTH-1:0] matrixC0_8;
   wire [`DWIDTH-1:0] matrixC0_9;
   wire [`DWIDTH-1:0] matrixC0_10;
   wire [`DWIDTH-1:0] matrixC0_11;
   wire [`DWIDTH-1:0] matrixC0_12;
   wire [`DWIDTH-1:0] matrixC0_13;
   wire [`DWIDTH-1:0] matrixC0_14;
   wire [`DWIDTH-1:0] matrixC0_15;
   wire [`DWIDTH-1:0] matrixC1_0;
   wire [`DWIDTH-1:0] matrixC1_1;
   wire [`DWIDTH-1:0] matrixC1_2;
   wire [`DWIDTH-1:0] matrixC1_3;
   wire [`DWIDTH-1:0] matrixC1_4;
   wire [`DWIDTH-1:0] matrixC1_5;
   wire [`DWIDTH-1:0] matrixC1_6;
   wire [`DWIDTH-1:0] matrixC1_7;
   wire [`DWIDTH-1:0] matrixC1_8;
   wire [`DWIDTH-1:0] matrixC1_9;
   wire [`DWIDTH-1:0] matrixC1_10;
   wire [`DWIDTH-1:0] matrixC1_11;
   wire [`DWIDTH-1:0] matrixC1_12;
   wire [`DWIDTH-1:0] matrixC1_13;
   wire [`DWIDTH-1:0] matrixC1_14;
   wire [`DWIDTH-1:0] matrixC1_15;
   wire [`DWIDTH-1:0] matrixC2_0;
   wire [`DWIDTH-1:0] matrixC2_1;
   wire [`DWIDTH-1:0] matrixC2_2;
   wire [`DWIDTH-1:0] matrixC2_3;
   wire [`DWIDTH-1:0] matrixC2_4;
   wire [`DWIDTH-1:0] matrixC2_5;
   wire [`DWIDTH-1:0] matrixC2_6;
   wire [`DWIDTH-1:0] matrixC2_7;
   wire [`DWIDTH-1:0] matrixC2_8;
   wire [`DWIDTH-1:0] matrixC2_9;
   wire [`DWIDTH-1:0] matrixC2_10;
   wire [`DWIDTH-1:0] matrixC2_11;
   wire [`DWIDTH-1:0] matrixC2_12;
   wire [`DWIDTH-1:0] matrixC2_13;
   wire [`DWIDTH-1:0] matrixC2_14;
   wire [`DWIDTH-1:0] matrixC2_15;
   wire [`DWIDTH-1:0] matrixC3_0;
   wire [`DWIDTH-1:0] matrixC3_1;
   wire [`DWIDTH-1:0] matrixC3_2;
   wire [`DWIDTH-1:0] matrixC3_3;
   wire [`DWIDTH-1:0] matrixC3_4;
   wire [`DWIDTH-1:0] matrixC3_5;
   wire [`DWIDTH-1:0] matrixC3_6;
   wire [`DWIDTH-1:0] matrixC3_7;
   wire [`DWIDTH-1:0] matrixC3_8;
   wire [`DWIDTH-1:0] matrixC3_9;
   wire [`DWIDTH-1:0] matrixC3_10;
   wire [`DWIDTH-1:0] matrixC3_11;
   wire [`DWIDTH-1:0] matrixC3_12;
   wire [`DWIDTH-1:0] matrixC3_13;
   wire [`DWIDTH-1:0] matrixC3_14;
   wire [`DWIDTH-1:0] matrixC3_15;
   wire [`DWIDTH-1:0] matrixC4_0;
   wire [`DWIDTH-1:0] matrixC4_1;
   wire [`DWIDTH-1:0] matrixC4_2;
   wire [`DWIDTH-1:0] matrixC4_3;
   wire [`DWIDTH-1:0] matrixC4_4;
   wire [`DWIDTH-1:0] matrixC4_5;
   wire [`DWIDTH-1:0] matrixC4_6;
   wire [`DWIDTH-1:0] matrixC4_7;
   wire [`DWIDTH-1:0] matrixC4_8;
   wire [`DWIDTH-1:0] matrixC4_9;
   wire [`DWIDTH-1:0] matrixC4_10;
   wire [`DWIDTH-1:0] matrixC4_11;
   wire [`DWIDTH-1:0] matrixC4_12;
   wire [`DWIDTH-1:0] matrixC4_13;
   wire [`DWIDTH-1:0] matrixC4_14;
   wire [`DWIDTH-1:0] matrixC4_15;
   wire [`DWIDTH-1:0] matrixC5_0;
   wire [`DWIDTH-1:0] matrixC5_1;
   wire [`DWIDTH-1:0] matrixC5_2;
   wire [`DWIDTH-1:0] matrixC5_3;
   wire [`DWIDTH-1:0] matrixC5_4;
   wire [`DWIDTH-1:0] matrixC5_5;
   wire [`DWIDTH-1:0] matrixC5_6;
   wire [`DWIDTH-1:0] matrixC5_7;
   wire [`DWIDTH-1:0] matrixC5_8;
   wire [`DWIDTH-1:0] matrixC5_9;
   wire [`DWIDTH-1:0] matrixC5_10;
   wire [`DWIDTH-1:0] matrixC5_11;
   wire [`DWIDTH-1:0] matrixC5_12;
   wire [`DWIDTH-1:0] matrixC5_13;
   wire [`DWIDTH-1:0] matrixC5_14;
   wire [`DWIDTH-1:0] matrixC5_15;
   wire [`DWIDTH-1:0] matrixC6_0;
   wire [`DWIDTH-1:0] matrixC6_1;
   wire [`DWIDTH-1:0] matrixC6_2;
   wire [`DWIDTH-1:0] matrixC6_3;
   wire [`DWIDTH-1:0] matrixC6_4;
   wire [`DWIDTH-1:0] matrixC6_5;
   wire [`DWIDTH-1:0] matrixC6_6;
   wire [`DWIDTH-1:0] matrixC6_7;
   wire [`DWIDTH-1:0] matrixC6_8;
   wire [`DWIDTH-1:0] matrixC6_9;
   wire [`DWIDTH-1:0] matrixC6_10;
   wire [`DWIDTH-1:0] matrixC6_11;
   wire [`DWIDTH-1:0] matrixC6_12;
   wire [`DWIDTH-1:0] matrixC6_13;
   wire [`DWIDTH-1:0] matrixC6_14;
   wire [`DWIDTH-1:0] matrixC6_15;
   wire [`DWIDTH-1:0] matrixC7_0;
   wire [`DWIDTH-1:0] matrixC7_1;
   wire [`DWIDTH-1:0] matrixC7_2;
   wire [`DWIDTH-1:0] matrixC7_3;
   wire [`DWIDTH-1:0] matrixC7_4;
   wire [`DWIDTH-1:0] matrixC7_5;
   wire [`DWIDTH-1:0] matrixC7_6;
   wire [`DWIDTH-1:0] matrixC7_7;
   wire [`DWIDTH-1:0] matrixC7_8;
   wire [`DWIDTH-1:0] matrixC7_9;
   wire [`DWIDTH-1:0] matrixC7_10;
   wire [`DWIDTH-1:0] matrixC7_11;
   wire [`DWIDTH-1:0] matrixC7_12;
   wire [`DWIDTH-1:0] matrixC7_13;
   wire [`DWIDTH-1:0] matrixC7_14;
   wire [`DWIDTH-1:0] matrixC7_15;
   wire [`DWIDTH-1:0] matrixC8_0;
   wire [`DWIDTH-1:0] matrixC8_1;
   wire [`DWIDTH-1:0] matrixC8_2;
   wire [`DWIDTH-1:0] matrixC8_3;
   wire [`DWIDTH-1:0] matrixC8_4;
   wire [`DWIDTH-1:0] matrixC8_5;
   wire [`DWIDTH-1:0] matrixC8_6;
   wire [`DWIDTH-1:0] matrixC8_7;
   wire [`DWIDTH-1:0] matrixC8_8;
   wire [`DWIDTH-1:0] matrixC8_9;
   wire [`DWIDTH-1:0] matrixC8_10;
   wire [`DWIDTH-1:0] matrixC8_11;
   wire [`DWIDTH-1:0] matrixC8_12;
   wire [`DWIDTH-1:0] matrixC8_13;
   wire [`DWIDTH-1:0] matrixC8_14;
   wire [`DWIDTH-1:0] matrixC8_15;
   wire [`DWIDTH-1:0] matrixC9_0;
   wire [`DWIDTH-1:0] matrixC9_1;
   wire [`DWIDTH-1:0] matrixC9_2;
   wire [`DWIDTH-1:0] matrixC9_3;
   wire [`DWIDTH-1:0] matrixC9_4;
   wire [`DWIDTH-1:0] matrixC9_5;
   wire [`DWIDTH-1:0] matrixC9_6;
   wire [`DWIDTH-1:0] matrixC9_7;
   wire [`DWIDTH-1:0] matrixC9_8;
   wire [`DWIDTH-1:0] matrixC9_9;
   wire [`DWIDTH-1:0] matrixC9_10;
   wire [`DWIDTH-1:0] matrixC9_11;
   wire [`DWIDTH-1:0] matrixC9_12;
   wire [`DWIDTH-1:0] matrixC9_13;
   wire [`DWIDTH-1:0] matrixC9_14;
   wire [`DWIDTH-1:0] matrixC9_15;
   wire [`DWIDTH-1:0] matrixC10_0;
   wire [`DWIDTH-1:0] matrixC10_1;
   wire [`DWIDTH-1:0] matrixC10_2;
   wire [`DWIDTH-1:0] matrixC10_3;
   wire [`DWIDTH-1:0] matrixC10_4;
   wire [`DWIDTH-1:0] matrixC10_5;
   wire [`DWIDTH-1:0] matrixC10_6;
   wire [`DWIDTH-1:0] matrixC10_7;
   wire [`DWIDTH-1:0] matrixC10_8;
   wire [`DWIDTH-1:0] matrixC10_9;
   wire [`DWIDTH-1:0] matrixC10_10;
   wire [`DWIDTH-1:0] matrixC10_11;
   wire [`DWIDTH-1:0] matrixC10_12;
   wire [`DWIDTH-1:0] matrixC10_13;
   wire [`DWIDTH-1:0] matrixC10_14;
   wire [`DWIDTH-1:0] matrixC10_15;
   wire [`DWIDTH-1:0] matrixC11_0;
   wire [`DWIDTH-1:0] matrixC11_1;
   wire [`DWIDTH-1:0] matrixC11_2;
   wire [`DWIDTH-1:0] matrixC11_3;
   wire [`DWIDTH-1:0] matrixC11_4;
   wire [`DWIDTH-1:0] matrixC11_5;
   wire [`DWIDTH-1:0] matrixC11_6;
   wire [`DWIDTH-1:0] matrixC11_7;
   wire [`DWIDTH-1:0] matrixC11_8;
   wire [`DWIDTH-1:0] matrixC11_9;
   wire [`DWIDTH-1:0] matrixC11_10;
   wire [`DWIDTH-1:0] matrixC11_11;
   wire [`DWIDTH-1:0] matrixC11_12;
   wire [`DWIDTH-1:0] matrixC11_13;
   wire [`DWIDTH-1:0] matrixC11_14;
   wire [`DWIDTH-1:0] matrixC11_15;
   wire [`DWIDTH-1:0] matrixC12_0;
   wire [`DWIDTH-1:0] matrixC12_1;
   wire [`DWIDTH-1:0] matrixC12_2;
   wire [`DWIDTH-1:0] matrixC12_3;
   wire [`DWIDTH-1:0] matrixC12_4;
   wire [`DWIDTH-1:0] matrixC12_5;
   wire [`DWIDTH-1:0] matrixC12_6;
   wire [`DWIDTH-1:0] matrixC12_7;
   wire [`DWIDTH-1:0] matrixC12_8;
   wire [`DWIDTH-1:0] matrixC12_9;
   wire [`DWIDTH-1:0] matrixC12_10;
   wire [`DWIDTH-1:0] matrixC12_11;
   wire [`DWIDTH-1:0] matrixC12_12;
   wire [`DWIDTH-1:0] matrixC12_13;
   wire [`DWIDTH-1:0] matrixC12_14;
   wire [`DWIDTH-1:0] matrixC12_15;
   wire [`DWIDTH-1:0] matrixC13_0;
   wire [`DWIDTH-1:0] matrixC13_1;
   wire [`DWIDTH-1:0] matrixC13_2;
   wire [`DWIDTH-1:0] matrixC13_3;
   wire [`DWIDTH-1:0] matrixC13_4;
   wire [`DWIDTH-1:0] matrixC13_5;
   wire [`DWIDTH-1:0] matrixC13_6;
   wire [`DWIDTH-1:0] matrixC13_7;
   wire [`DWIDTH-1:0] matrixC13_8;
   wire [`DWIDTH-1:0] matrixC13_9;
   wire [`DWIDTH-1:0] matrixC13_10;
   wire [`DWIDTH-1:0] matrixC13_11;
   wire [`DWIDTH-1:0] matrixC13_12;
   wire [`DWIDTH-1:0] matrixC13_13;
   wire [`DWIDTH-1:0] matrixC13_14;
   wire [`DWIDTH-1:0] matrixC13_15;
   wire [`DWIDTH-1:0] matrixC14_0;
   wire [`DWIDTH-1:0] matrixC14_1;
   wire [`DWIDTH-1:0] matrixC14_2;
   wire [`DWIDTH-1:0] matrixC14_3;
   wire [`DWIDTH-1:0] matrixC14_4;
   wire [`DWIDTH-1:0] matrixC14_5;
   wire [`DWIDTH-1:0] matrixC14_6;
   wire [`DWIDTH-1:0] matrixC14_7;
   wire [`DWIDTH-1:0] matrixC14_8;
   wire [`DWIDTH-1:0] matrixC14_9;
   wire [`DWIDTH-1:0] matrixC14_10;
   wire [`DWIDTH-1:0] matrixC14_11;
   wire [`DWIDTH-1:0] matrixC14_12;
   wire [`DWIDTH-1:0] matrixC14_13;
   wire [`DWIDTH-1:0] matrixC14_14;
   wire [`DWIDTH-1:0] matrixC14_15;
   wire [`DWIDTH-1:0] matrixC15_0;
   wire [`DWIDTH-1:0] matrixC15_1;
   wire [`DWIDTH-1:0] matrixC15_2;
   wire [`DWIDTH-1:0] matrixC15_3;
   wire [`DWIDTH-1:0] matrixC15_4;
   wire [`DWIDTH-1:0] matrixC15_5;
   wire [`DWIDTH-1:0] matrixC15_6;
   wire [`DWIDTH-1:0] matrixC15_7;
   wire [`DWIDTH-1:0] matrixC15_8;
   wire [`DWIDTH-1:0] matrixC15_9;
   wire [`DWIDTH-1:0] matrixC15_10;
   wire [`DWIDTH-1:0] matrixC15_11;
   wire [`DWIDTH-1:0] matrixC15_12;
   wire [`DWIDTH-1:0] matrixC15_13;
   wire [`DWIDTH-1:0] matrixC15_14;
   wire [`DWIDTH-1:0] matrixC15_15;
   
   wire row_latch_en;
   //////////////////////////////////////////////////////////////////////////
   // Instantiation of the output logic
   //////////////////////////////////////////////////////////////////////////
   output_logic u_output_logic(
   .start_mat_mul(start_mat_mul),
   .done_mat_mul(done_mat_mul),
   .address_mat_c(address_mat_c),
   .address_stride_c(address_stride_c),
   .c_data_out(c_data_out),
   .c_data_in(c_data_in),
   .c_addr(c_addr),
   .c_data_available(c_data_available),
   .clk_cnt(clk_cnt),
   .row_latch_en(row_latch_en),
   .final_mat_mul_size(final_mat_mul_size),
   .matrixC0_0(matrixC0_0),
   .matrixC0_1(matrixC0_1),
   .matrixC0_2(matrixC0_2),
   .matrixC0_3(matrixC0_3),
   .matrixC0_4(matrixC0_4),
   .matrixC0_5(matrixC0_5),
   .matrixC0_6(matrixC0_6),
   .matrixC0_7(matrixC0_7),
   .matrixC0_8(matrixC0_8),
   .matrixC0_9(matrixC0_9),
   .matrixC0_10(matrixC0_10),
   .matrixC0_11(matrixC0_11),
   .matrixC0_12(matrixC0_12),
   .matrixC0_13(matrixC0_13),
   .matrixC0_14(matrixC0_14),
   .matrixC0_15(matrixC0_15),
   .matrixC1_0(matrixC1_0),
   .matrixC1_1(matrixC1_1),
   .matrixC1_2(matrixC1_2),
   .matrixC1_3(matrixC1_3),
   .matrixC1_4(matrixC1_4),
   .matrixC1_5(matrixC1_5),
   .matrixC1_6(matrixC1_6),
   .matrixC1_7(matrixC1_7),
   .matrixC1_8(matrixC1_8),
   .matrixC1_9(matrixC1_9),
   .matrixC1_10(matrixC1_10),
   .matrixC1_11(matrixC1_11),
   .matrixC1_12(matrixC1_12),
   .matrixC1_13(matrixC1_13),
   .matrixC1_14(matrixC1_14),
   .matrixC1_15(matrixC1_15),
   .matrixC2_0(matrixC2_0),
   .matrixC2_1(matrixC2_1),
   .matrixC2_2(matrixC2_2),
   .matrixC2_3(matrixC2_3),
   .matrixC2_4(matrixC2_4),
   .matrixC2_5(matrixC2_5),
   .matrixC2_6(matrixC2_6),
   .matrixC2_7(matrixC2_7),
   .matrixC2_8(matrixC2_8),
   .matrixC2_9(matrixC2_9),
   .matrixC2_10(matrixC2_10),
   .matrixC2_11(matrixC2_11),
   .matrixC2_12(matrixC2_12),
   .matrixC2_13(matrixC2_13),
   .matrixC2_14(matrixC2_14),
   .matrixC2_15(matrixC2_15),
   .matrixC3_0(matrixC3_0),
   .matrixC3_1(matrixC3_1),
   .matrixC3_2(matrixC3_2),
   .matrixC3_3(matrixC3_3),
   .matrixC3_4(matrixC3_4),
   .matrixC3_5(matrixC3_5),
   .matrixC3_6(matrixC3_6),
   .matrixC3_7(matrixC3_7),
   .matrixC3_8(matrixC3_8),
   .matrixC3_9(matrixC3_9),
   .matrixC3_10(matrixC3_10),
   .matrixC3_11(matrixC3_11),
   .matrixC3_12(matrixC3_12),
   .matrixC3_13(matrixC3_13),
   .matrixC3_14(matrixC3_14),
   .matrixC3_15(matrixC3_15),
   .matrixC4_0(matrixC4_0),
   .matrixC4_1(matrixC4_1),
   .matrixC4_2(matrixC4_2),
   .matrixC4_3(matrixC4_3),
   .matrixC4_4(matrixC4_4),
   .matrixC4_5(matrixC4_5),
   .matrixC4_6(matrixC4_6),
   .matrixC4_7(matrixC4_7),
   .matrixC4_8(matrixC4_8),
   .matrixC4_9(matrixC4_9),
   .matrixC4_10(matrixC4_10),
   .matrixC4_11(matrixC4_11),
   .matrixC4_12(matrixC4_12),
   .matrixC4_13(matrixC4_13),
   .matrixC4_14(matrixC4_14),
   .matrixC4_15(matrixC4_15),
   .matrixC5_0(matrixC5_0),
   .matrixC5_1(matrixC5_1),
   .matrixC5_2(matrixC5_2),
   .matrixC5_3(matrixC5_3),
   .matrixC5_4(matrixC5_4),
   .matrixC5_5(matrixC5_5),
   .matrixC5_6(matrixC5_6),
   .matrixC5_7(matrixC5_7),
   .matrixC5_8(matrixC5_8),
   .matrixC5_9(matrixC5_9),
   .matrixC5_10(matrixC5_10),
   .matrixC5_11(matrixC5_11),
   .matrixC5_12(matrixC5_12),
   .matrixC5_13(matrixC5_13),
   .matrixC5_14(matrixC5_14),
   .matrixC5_15(matrixC5_15),
   .matrixC6_0(matrixC6_0),
   .matrixC6_1(matrixC6_1),
   .matrixC6_2(matrixC6_2),
   .matrixC6_3(matrixC6_3),
   .matrixC6_4(matrixC6_4),
   .matrixC6_5(matrixC6_5),
   .matrixC6_6(matrixC6_6),
   .matrixC6_7(matrixC6_7),
   .matrixC6_8(matrixC6_8),
   .matrixC6_9(matrixC6_9),
   .matrixC6_10(matrixC6_10),
   .matrixC6_11(matrixC6_11),
   .matrixC6_12(matrixC6_12),
   .matrixC6_13(matrixC6_13),
   .matrixC6_14(matrixC6_14),
   .matrixC6_15(matrixC6_15),
   .matrixC7_0(matrixC7_0),
   .matrixC7_1(matrixC7_1),
   .matrixC7_2(matrixC7_2),
   .matrixC7_3(matrixC7_3),
   .matrixC7_4(matrixC7_4),
   .matrixC7_5(matrixC7_5),
   .matrixC7_6(matrixC7_6),
   .matrixC7_7(matrixC7_7),
   .matrixC7_8(matrixC7_8),
   .matrixC7_9(matrixC7_9),
   .matrixC7_10(matrixC7_10),
   .matrixC7_11(matrixC7_11),
   .matrixC7_12(matrixC7_12),
   .matrixC7_13(matrixC7_13),
   .matrixC7_14(matrixC7_14),
   .matrixC7_15(matrixC7_15),
   .matrixC8_0(matrixC8_0),
   .matrixC8_1(matrixC8_1),
   .matrixC8_2(matrixC8_2),
   .matrixC8_3(matrixC8_3),
   .matrixC8_4(matrixC8_4),
   .matrixC8_5(matrixC8_5),
   .matrixC8_6(matrixC8_6),
   .matrixC8_7(matrixC8_7),
   .matrixC8_8(matrixC8_8),
   .matrixC8_9(matrixC8_9),
   .matrixC8_10(matrixC8_10),
   .matrixC8_11(matrixC8_11),
   .matrixC8_12(matrixC8_12),
   .matrixC8_13(matrixC8_13),
   .matrixC8_14(matrixC8_14),
   .matrixC8_15(matrixC8_15),
   .matrixC9_0(matrixC9_0),
   .matrixC9_1(matrixC9_1),
   .matrixC9_2(matrixC9_2),
   .matrixC9_3(matrixC9_3),
   .matrixC9_4(matrixC9_4),
   .matrixC9_5(matrixC9_5),
   .matrixC9_6(matrixC9_6),
   .matrixC9_7(matrixC9_7),
   .matrixC9_8(matrixC9_8),
   .matrixC9_9(matrixC9_9),
   .matrixC9_10(matrixC9_10),
   .matrixC9_11(matrixC9_11),
   .matrixC9_12(matrixC9_12),
   .matrixC9_13(matrixC9_13),
   .matrixC9_14(matrixC9_14),
   .matrixC9_15(matrixC9_15),
   .matrixC10_0(matrixC10_0),
   .matrixC10_1(matrixC10_1),
   .matrixC10_2(matrixC10_2),
   .matrixC10_3(matrixC10_3),
   .matrixC10_4(matrixC10_4),
   .matrixC10_5(matrixC10_5),
   .matrixC10_6(matrixC10_6),
   .matrixC10_7(matrixC10_7),
   .matrixC10_8(matrixC10_8),
   .matrixC10_9(matrixC10_9),
   .matrixC10_10(matrixC10_10),
   .matrixC10_11(matrixC10_11),
   .matrixC10_12(matrixC10_12),
   .matrixC10_13(matrixC10_13),
   .matrixC10_14(matrixC10_14),
   .matrixC10_15(matrixC10_15),
   .matrixC11_0(matrixC11_0),
   .matrixC11_1(matrixC11_1),
   .matrixC11_2(matrixC11_2),
   .matrixC11_3(matrixC11_3),
   .matrixC11_4(matrixC11_4),
   .matrixC11_5(matrixC11_5),
   .matrixC11_6(matrixC11_6),
   .matrixC11_7(matrixC11_7),
   .matrixC11_8(matrixC11_8),
   .matrixC11_9(matrixC11_9),
   .matrixC11_10(matrixC11_10),
   .matrixC11_11(matrixC11_11),
   .matrixC11_12(matrixC11_12),
   .matrixC11_13(matrixC11_13),
   .matrixC11_14(matrixC11_14),
   .matrixC11_15(matrixC11_15),
   .matrixC12_0(matrixC12_0),
   .matrixC12_1(matrixC12_1),
   .matrixC12_2(matrixC12_2),
   .matrixC12_3(matrixC12_3),
   .matrixC12_4(matrixC12_4),
   .matrixC12_5(matrixC12_5),
   .matrixC12_6(matrixC12_6),
   .matrixC12_7(matrixC12_7),
   .matrixC12_8(matrixC12_8),
   .matrixC12_9(matrixC12_9),
   .matrixC12_10(matrixC12_10),
   .matrixC12_11(matrixC12_11),
   .matrixC12_12(matrixC12_12),
   .matrixC12_13(matrixC12_13),
   .matrixC12_14(matrixC12_14),
   .matrixC12_15(matrixC12_15),
   .matrixC13_0(matrixC13_0),
   .matrixC13_1(matrixC13_1),
   .matrixC13_2(matrixC13_2),
   .matrixC13_3(matrixC13_3),
   .matrixC13_4(matrixC13_4),
   .matrixC13_5(matrixC13_5),
   .matrixC13_6(matrixC13_6),
   .matrixC13_7(matrixC13_7),
   .matrixC13_8(matrixC13_8),
   .matrixC13_9(matrixC13_9),
   .matrixC13_10(matrixC13_10),
   .matrixC13_11(matrixC13_11),
   .matrixC13_12(matrixC13_12),
   .matrixC13_13(matrixC13_13),
   .matrixC13_14(matrixC13_14),
   .matrixC13_15(matrixC13_15),
   .matrixC14_0(matrixC14_0),
   .matrixC14_1(matrixC14_1),
   .matrixC14_2(matrixC14_2),
   .matrixC14_3(matrixC14_3),
   .matrixC14_4(matrixC14_4),
   .matrixC14_5(matrixC14_5),
   .matrixC14_6(matrixC14_6),
   .matrixC14_7(matrixC14_7),
   .matrixC14_8(matrixC14_8),
   .matrixC14_9(matrixC14_9),
   .matrixC14_10(matrixC14_10),
   .matrixC14_11(matrixC14_11),
   .matrixC14_12(matrixC14_12),
   .matrixC14_13(matrixC14_13),
   .matrixC14_14(matrixC14_14),
   .matrixC14_15(matrixC14_15),
   .matrixC15_0(matrixC15_0),
   .matrixC15_1(matrixC15_1),
   .matrixC15_2(matrixC15_2),
   .matrixC15_3(matrixC15_3),
   .matrixC15_4(matrixC15_4),
   .matrixC15_5(matrixC15_5),
   .matrixC15_6(matrixC15_6),
   .matrixC15_7(matrixC15_7),
   .matrixC15_8(matrixC15_8),
   .matrixC15_9(matrixC15_9),
   .matrixC15_10(matrixC15_10),
   .matrixC15_11(matrixC15_11),
   .matrixC15_12(matrixC15_12),
   .matrixC15_13(matrixC15_13),
   .matrixC15_14(matrixC15_14),
   .matrixC15_15(matrixC15_15),
   
   .clk(clk),
   .reset(reset)
   );
   
   //////////////////////////////////////////////////////////////////////////
   // Instantiations of the actual PEs
   //////////////////////////////////////////////////////////////////////////
   systolic_pe_matrix u_systolic_pe_matrix(
   .clk(clk),
   .reset(reset),
   .pe_reset(pe_reset),
   .a0(a0),
   .a1(a1),
   .a2(a2),
   .a3(a3),
   .a4(a4),
   .a5(a5),
   .a6(a6),
   .a7(a7),
   .a8(a8),
   .a9(a9),
   .a10(a10),
   .a11(a11),
   .a12(a12),
   .a13(a13),
   .a14(a14),
   .a15(a15),
   .b0(b0),
   .b1(b1),
   .b2(b2),
   .b3(b3),
   .b4(b4),
   .b5(b5),
   .b6(b6),
   .b7(b7),
   .b8(b8),
   .b9(b9),
   .b10(b10),
   .b11(b11),
   .b12(b12),
   .b13(b13),
   .b14(b14),
   .b15(b15),
   .matrixC0_0(matrixC0_0),
   .matrixC0_1(matrixC0_1),
   .matrixC0_2(matrixC0_2),
   .matrixC0_3(matrixC0_3),
   .matrixC0_4(matrixC0_4),
   .matrixC0_5(matrixC0_5),
   .matrixC0_6(matrixC0_6),
   .matrixC0_7(matrixC0_7),
   .matrixC0_8(matrixC0_8),
   .matrixC0_9(matrixC0_9),
   .matrixC0_10(matrixC0_10),
   .matrixC0_11(matrixC0_11),
   .matrixC0_12(matrixC0_12),
   .matrixC0_13(matrixC0_13),
   .matrixC0_14(matrixC0_14),
   .matrixC0_15(matrixC0_15),
   .matrixC1_0(matrixC1_0),
   .matrixC1_1(matrixC1_1),
   .matrixC1_2(matrixC1_2),
   .matrixC1_3(matrixC1_3),
   .matrixC1_4(matrixC1_4),
   .matrixC1_5(matrixC1_5),
   .matrixC1_6(matrixC1_6),
   .matrixC1_7(matrixC1_7),
   .matrixC1_8(matrixC1_8),
   .matrixC1_9(matrixC1_9),
   .matrixC1_10(matrixC1_10),
   .matrixC1_11(matrixC1_11),
   .matrixC1_12(matrixC1_12),
   .matrixC1_13(matrixC1_13),
   .matrixC1_14(matrixC1_14),
   .matrixC1_15(matrixC1_15),
   .matrixC2_0(matrixC2_0),
   .matrixC2_1(matrixC2_1),
   .matrixC2_2(matrixC2_2),
   .matrixC2_3(matrixC2_3),
   .matrixC2_4(matrixC2_4),
   .matrixC2_5(matrixC2_5),
   .matrixC2_6(matrixC2_6),
   .matrixC2_7(matrixC2_7),
   .matrixC2_8(matrixC2_8),
   .matrixC2_9(matrixC2_9),
   .matrixC2_10(matrixC2_10),
   .matrixC2_11(matrixC2_11),
   .matrixC2_12(matrixC2_12),
   .matrixC2_13(matrixC2_13),
   .matrixC2_14(matrixC2_14),
   .matrixC2_15(matrixC2_15),
   .matrixC3_0(matrixC3_0),
   .matrixC3_1(matrixC3_1),
   .matrixC3_2(matrixC3_2),
   .matrixC3_3(matrixC3_3),
   .matrixC3_4(matrixC3_4),
   .matrixC3_5(matrixC3_5),
   .matrixC3_6(matrixC3_6),
   .matrixC3_7(matrixC3_7),
   .matrixC3_8(matrixC3_8),
   .matrixC3_9(matrixC3_9),
   .matrixC3_10(matrixC3_10),
   .matrixC3_11(matrixC3_11),
   .matrixC3_12(matrixC3_12),
   .matrixC3_13(matrixC3_13),
   .matrixC3_14(matrixC3_14),
   .matrixC3_15(matrixC3_15),
   .matrixC4_0(matrixC4_0),
   .matrixC4_1(matrixC4_1),
   .matrixC4_2(matrixC4_2),
   .matrixC4_3(matrixC4_3),
   .matrixC4_4(matrixC4_4),
   .matrixC4_5(matrixC4_5),
   .matrixC4_6(matrixC4_6),
   .matrixC4_7(matrixC4_7),
   .matrixC4_8(matrixC4_8),
   .matrixC4_9(matrixC4_9),
   .matrixC4_10(matrixC4_10),
   .matrixC4_11(matrixC4_11),
   .matrixC4_12(matrixC4_12),
   .matrixC4_13(matrixC4_13),
   .matrixC4_14(matrixC4_14),
   .matrixC4_15(matrixC4_15),
   .matrixC5_0(matrixC5_0),
   .matrixC5_1(matrixC5_1),
   .matrixC5_2(matrixC5_2),
   .matrixC5_3(matrixC5_3),
   .matrixC5_4(matrixC5_4),
   .matrixC5_5(matrixC5_5),
   .matrixC5_6(matrixC5_6),
   .matrixC5_7(matrixC5_7),
   .matrixC5_8(matrixC5_8),
   .matrixC5_9(matrixC5_9),
   .matrixC5_10(matrixC5_10),
   .matrixC5_11(matrixC5_11),
   .matrixC5_12(matrixC5_12),
   .matrixC5_13(matrixC5_13),
   .matrixC5_14(matrixC5_14),
   .matrixC5_15(matrixC5_15),
   .matrixC6_0(matrixC6_0),
   .matrixC6_1(matrixC6_1),
   .matrixC6_2(matrixC6_2),
   .matrixC6_3(matrixC6_3),
   .matrixC6_4(matrixC6_4),
   .matrixC6_5(matrixC6_5),
   .matrixC6_6(matrixC6_6),
   .matrixC6_7(matrixC6_7),
   .matrixC6_8(matrixC6_8),
   .matrixC6_9(matrixC6_9),
   .matrixC6_10(matrixC6_10),
   .matrixC6_11(matrixC6_11),
   .matrixC6_12(matrixC6_12),
   .matrixC6_13(matrixC6_13),
   .matrixC6_14(matrixC6_14),
   .matrixC6_15(matrixC6_15),
   .matrixC7_0(matrixC7_0),
   .matrixC7_1(matrixC7_1),
   .matrixC7_2(matrixC7_2),
   .matrixC7_3(matrixC7_3),
   .matrixC7_4(matrixC7_4),
   .matrixC7_5(matrixC7_5),
   .matrixC7_6(matrixC7_6),
   .matrixC7_7(matrixC7_7),
   .matrixC7_8(matrixC7_8),
   .matrixC7_9(matrixC7_9),
   .matrixC7_10(matrixC7_10),
   .matrixC7_11(matrixC7_11),
   .matrixC7_12(matrixC7_12),
   .matrixC7_13(matrixC7_13),
   .matrixC7_14(matrixC7_14),
   .matrixC7_15(matrixC7_15),
   .matrixC8_0(matrixC8_0),
   .matrixC8_1(matrixC8_1),
   .matrixC8_2(matrixC8_2),
   .matrixC8_3(matrixC8_3),
   .matrixC8_4(matrixC8_4),
   .matrixC8_5(matrixC8_5),
   .matrixC8_6(matrixC8_6),
   .matrixC8_7(matrixC8_7),
   .matrixC8_8(matrixC8_8),
   .matrixC8_9(matrixC8_9),
   .matrixC8_10(matrixC8_10),
   .matrixC8_11(matrixC8_11),
   .matrixC8_12(matrixC8_12),
   .matrixC8_13(matrixC8_13),
   .matrixC8_14(matrixC8_14),
   .matrixC8_15(matrixC8_15),
   .matrixC9_0(matrixC9_0),
   .matrixC9_1(matrixC9_1),
   .matrixC9_2(matrixC9_2),
   .matrixC9_3(matrixC9_3),
   .matrixC9_4(matrixC9_4),
   .matrixC9_5(matrixC9_5),
   .matrixC9_6(matrixC9_6),
   .matrixC9_7(matrixC9_7),
   .matrixC9_8(matrixC9_8),
   .matrixC9_9(matrixC9_9),
   .matrixC9_10(matrixC9_10),
   .matrixC9_11(matrixC9_11),
   .matrixC9_12(matrixC9_12),
   .matrixC9_13(matrixC9_13),
   .matrixC9_14(matrixC9_14),
   .matrixC9_15(matrixC9_15),
   .matrixC10_0(matrixC10_0),
   .matrixC10_1(matrixC10_1),
   .matrixC10_2(matrixC10_2),
   .matrixC10_3(matrixC10_3),
   .matrixC10_4(matrixC10_4),
   .matrixC10_5(matrixC10_5),
   .matrixC10_6(matrixC10_6),
   .matrixC10_7(matrixC10_7),
   .matrixC10_8(matrixC10_8),
   .matrixC10_9(matrixC10_9),
   .matrixC10_10(matrixC10_10),
   .matrixC10_11(matrixC10_11),
   .matrixC10_12(matrixC10_12),
   .matrixC10_13(matrixC10_13),
   .matrixC10_14(matrixC10_14),
   .matrixC10_15(matrixC10_15),
   .matrixC11_0(matrixC11_0),
   .matrixC11_1(matrixC11_1),
   .matrixC11_2(matrixC11_2),
   .matrixC11_3(matrixC11_3),
   .matrixC11_4(matrixC11_4),
   .matrixC11_5(matrixC11_5),
   .matrixC11_6(matrixC11_6),
   .matrixC11_7(matrixC11_7),
   .matrixC11_8(matrixC11_8),
   .matrixC11_9(matrixC11_9),
   .matrixC11_10(matrixC11_10),
   .matrixC11_11(matrixC11_11),
   .matrixC11_12(matrixC11_12),
   .matrixC11_13(matrixC11_13),
   .matrixC11_14(matrixC11_14),
   .matrixC11_15(matrixC11_15),
   .matrixC12_0(matrixC12_0),
   .matrixC12_1(matrixC12_1),
   .matrixC12_2(matrixC12_2),
   .matrixC12_3(matrixC12_3),
   .matrixC12_4(matrixC12_4),
   .matrixC12_5(matrixC12_5),
   .matrixC12_6(matrixC12_6),
   .matrixC12_7(matrixC12_7),
   .matrixC12_8(matrixC12_8),
   .matrixC12_9(matrixC12_9),
   .matrixC12_10(matrixC12_10),
   .matrixC12_11(matrixC12_11),
   .matrixC12_12(matrixC12_12),
   .matrixC12_13(matrixC12_13),
   .matrixC12_14(matrixC12_14),
   .matrixC12_15(matrixC12_15),
   .matrixC13_0(matrixC13_0),
   .matrixC13_1(matrixC13_1),
   .matrixC13_2(matrixC13_2),
   .matrixC13_3(matrixC13_3),
   .matrixC13_4(matrixC13_4),
   .matrixC13_5(matrixC13_5),
   .matrixC13_6(matrixC13_6),
   .matrixC13_7(matrixC13_7),
   .matrixC13_8(matrixC13_8),
   .matrixC13_9(matrixC13_9),
   .matrixC13_10(matrixC13_10),
   .matrixC13_11(matrixC13_11),
   .matrixC13_12(matrixC13_12),
   .matrixC13_13(matrixC13_13),
   .matrixC13_14(matrixC13_14),
   .matrixC13_15(matrixC13_15),
   .matrixC14_0(matrixC14_0),
   .matrixC14_1(matrixC14_1),
   .matrixC14_2(matrixC14_2),
   .matrixC14_3(matrixC14_3),
   .matrixC14_4(matrixC14_4),
   .matrixC14_5(matrixC14_5),
   .matrixC14_6(matrixC14_6),
   .matrixC14_7(matrixC14_7),
   .matrixC14_8(matrixC14_8),
   .matrixC14_9(matrixC14_9),
   .matrixC14_10(matrixC14_10),
   .matrixC14_11(matrixC14_11),
   .matrixC14_12(matrixC14_12),
   .matrixC14_13(matrixC14_13),
   .matrixC14_14(matrixC14_14),
   .matrixC14_15(matrixC14_15),
   .matrixC15_0(matrixC15_0),
   .matrixC15_1(matrixC15_1),
   .matrixC15_2(matrixC15_2),
   .matrixC15_3(matrixC15_3),
   .matrixC15_4(matrixC15_4),
   .matrixC15_5(matrixC15_5),
   .matrixC15_6(matrixC15_6),
   .matrixC15_7(matrixC15_7),
   .matrixC15_8(matrixC15_8),
   .matrixC15_9(matrixC15_9),
   .matrixC15_10(matrixC15_10),
   .matrixC15_11(matrixC15_11),
   .matrixC15_12(matrixC15_12),
   .matrixC15_13(matrixC15_13),
   .matrixC15_14(matrixC15_14),
   .matrixC15_15(matrixC15_15),
   
   .a_data_out(a_data_out),
   .b_data_out(b_data_out)
   );
   
   endmodule
