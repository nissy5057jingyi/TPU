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
module systolic_data_setup(
	clk,
	reset,
	start_mat_mul,
	a_addr,
	b_addr,
	address_mat_a,
	address_mat_b,
	address_stride_a,
	address_stride_b,
	a_data,
	b_data,
	clk_cnt,
	a0_data,
	b0_data,
	a1_data_delayed_1,
	b1_data_delayed_1,
	a2_data_delayed_2,
	b2_data_delayed_2,
	a3_data_delayed_3,
	b3_data_delayed_3,
	a4_data_delayed_4,
	b4_data_delayed_4,
	a5_data_delayed_5,
	b5_data_delayed_5,
	a6_data_delayed_6,
	b6_data_delayed_6,
	a7_data_delayed_7,
	b7_data_delayed_7,
	a8_data_delayed_8,
	b8_data_delayed_8,
	a9_data_delayed_9,
	b9_data_delayed_9,
	a10_data_delayed_10,
	b10_data_delayed_10,
	a11_data_delayed_11,
	b11_data_delayed_11,
	a12_data_delayed_12,
	b12_data_delayed_12,
	a13_data_delayed_13,
	b13_data_delayed_13,
	a14_data_delayed_14,
	b14_data_delayed_14,
	a15_data_delayed_15,
	b15_data_delayed_15,
	
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
	input start_mat_mul;
	output [`AWIDTH-1:0] a_addr;
	output [`AWIDTH-1:0] b_addr;
	input [`AWIDTH-1:0] address_mat_a;
	input [`AWIDTH-1:0] address_mat_b;
	input [`ADDR_STRIDE_WIDTH-1:0] address_stride_a;
	input [`ADDR_STRIDE_WIDTH-1:0] address_stride_b;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] a_data;
	input [`MAT_MUL_SIZE*`DWIDTH-1:0] b_data;
	input [7:0] clk_cnt;
	output [`DWIDTH-1:0] a0_data;
	output [`DWIDTH-1:0] b0_data;
	output [`DWIDTH-1:0] a1_data_delayed_1;
	output [`DWIDTH-1:0] b1_data_delayed_1;
	output [`DWIDTH-1:0] a2_data_delayed_2;
	output [`DWIDTH-1:0] b2_data_delayed_2;
	output [`DWIDTH-1:0] a3_data_delayed_3;
	output [`DWIDTH-1:0] b3_data_delayed_3;
	output [`DWIDTH-1:0] a4_data_delayed_4;
	output [`DWIDTH-1:0] b4_data_delayed_4;
	output [`DWIDTH-1:0] a5_data_delayed_5;
	output [`DWIDTH-1:0] b5_data_delayed_5;
	output [`DWIDTH-1:0] a6_data_delayed_6;
	output [`DWIDTH-1:0] b6_data_delayed_6;
	output [`DWIDTH-1:0] a7_data_delayed_7;
	output [`DWIDTH-1:0] b7_data_delayed_7;
	output [`DWIDTH-1:0] a8_data_delayed_8;
	output [`DWIDTH-1:0] b8_data_delayed_8;
	output [`DWIDTH-1:0] a9_data_delayed_9;
	output [`DWIDTH-1:0] b9_data_delayed_9;
	output [`DWIDTH-1:0] a10_data_delayed_10;
	output [`DWIDTH-1:0] b10_data_delayed_10;
	output [`DWIDTH-1:0] a11_data_delayed_11;
	output [`DWIDTH-1:0] b11_data_delayed_11;
	output [`DWIDTH-1:0] a12_data_delayed_12;
	output [`DWIDTH-1:0] b12_data_delayed_12;
	output [`DWIDTH-1:0] a13_data_delayed_13;
	output [`DWIDTH-1:0] b13_data_delayed_13;
	output [`DWIDTH-1:0] a14_data_delayed_14;
	output [`DWIDTH-1:0] b14_data_delayed_14;
	output [`DWIDTH-1:0] a15_data_delayed_15;
	output [`DWIDTH-1:0] b15_data_delayed_15;
	
	input [`MASK_WIDTH-1:0] validity_mask_a_rows;
	input [`MASK_WIDTH-1:0] validity_mask_a_cols;
	input [`MASK_WIDTH-1:0] validity_mask_b_rows;
	input [`MASK_WIDTH-1:0] validity_mask_b_cols;
	
	input [7:0] final_mat_mul_size;
	  
	input [7:0] a_loc;
	input [7:0] b_loc;
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
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to generate addresses to BRAM A
	//////////////////////////////////////////////////////////////////////////
	reg [`AWIDTH-1:0] a_addr;
	reg a_mem_access; //flag that tells whether the matmul is trying to access memory or not
	
	always @(posedge clk) begin
	  //(clk_cnt >= a_loc*`MAT_MUL_SIZE+final_mat_mul_size) begin
	  //Writing the line above to avoid multiplication:
	  
	  if (reset || ~start_mat_mul || (clk_cnt >= (a_loc<<`LOG2_MAT_MUL_SIZE)+`final_mat_mul_size)) begin
	  //reset:system reset
	  //start_mat_mul:signal used to control matrix-computation
	  //clk_cnt cycle count
	  //a_loc<<`LOG2_MAT_MUL_SIZE: computation start time
	  //final_mat_mul_size: computation time
	  //if clk cycle beyond the limited, the computation should be finshed, next computation begin
		  a_addr <= address_mat_a-address_stride_a;
	  
		a_mem_access <= 0;
	  end
	  //else if ((clk_cnt >= a_loc*`MAT_MUL_SIZE) && (clk_cnt < a_loc*`MAT_MUL_SIZE+final_mat_mul_size)) begin
	  //Writing the line above to avoid multiplication:
	
	  else if ((clk_cnt >= (a_loc<<`LOG2_MAT_MUL_SIZE)) && (clk_cnt < (a_loc<<`LOG2_MAT_MUL_SIZE)+`final_mat_mul_size)) begin
	  
		  a_addr <= a_addr + address_stride_a;
	  
		a_mem_access <= 1;
	  end
	end
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to generate valid signals for data coming from BRAM A
	//////////////////////////////////////////////////////////////////////////
	reg [7:0] a_mem_access_counter;
	always @(posedge clk) begin
	  if (reset || ~start_mat_mul) begin
		a_mem_access_counter <= 0;
	  end
	  else if (a_mem_access == 1) begin
		a_mem_access_counter <= a_mem_access_counter + 1;  
	  end
	  else begin
		a_mem_access_counter <= 0;
	  end
	end
	
	wire a_data_valid; //flag that tells whether the data from memory is valid
	assign a_data_valid = 
		 ((validity_mask_a_cols[0]==1'b0 && a_mem_access_counter==1) ||
		  (validity_mask_a_cols[1]==1'b0 && a_mem_access_counter==2) ||
		  (validity_mask_a_cols[2]==1'b0 && a_mem_access_counter==3) ||
		  (validity_mask_a_cols[3]==1'b0 && a_mem_access_counter==4) ||
		  (validity_mask_a_cols[4]==1'b0 && a_mem_access_counter==5) ||
		  (validity_mask_a_cols[5]==1'b0 && a_mem_access_counter==6) ||
		  (validity_mask_a_cols[6]==1'b0 && a_mem_access_counter==7) ||
		  (validity_mask_a_cols[7]==1'b0 && a_mem_access_counter==8) ||
		  (validity_mask_a_cols[8]==1'b0 && a_mem_access_counter==9) ||
		  (validity_mask_a_cols[9]==1'b0 && a_mem_access_counter==10) ||
		  (validity_mask_a_cols[10]==1'b0 && a_mem_access_counter==11) ||
		  (validity_mask_a_cols[11]==1'b0 && a_mem_access_counter==12) ||
		  (validity_mask_a_cols[12]==1'b0 && a_mem_access_counter==13) ||
		  (validity_mask_a_cols[13]==1'b0 && a_mem_access_counter==14) ||
		  (validity_mask_a_cols[14]==1'b0 && a_mem_access_counter==15) ||
		  (validity_mask_a_cols[15]==1'b0 && a_mem_access_counter==16)) ?
		
		1'b0 : (a_mem_access_counter >= `MEM_ACCESS_LATENCY);
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to delay certain parts of the data received from BRAM A (systolic data setup)
	//////////////////////////////////////////////////////////////////////////
	assign a0_data = a_data[1*`DWIDTH-1:0*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[0]}};
	assign a1_data = a_data[2*`DWIDTH-1:1*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[1]}};
	assign a2_data = a_data[3*`DWIDTH-1:2*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[2]}};
	assign a3_data = a_data[4*`DWIDTH-1:3*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[3]}};
	assign a4_data = a_data[5*`DWIDTH-1:4*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[4]}};
	assign a5_data = a_data[6*`DWIDTH-1:5*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[5]}};
	assign a6_data = a_data[7*`DWIDTH-1:6*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[6]}};
	assign a7_data = a_data[8*`DWIDTH-1:7*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[7]}};
	assign a8_data = a_data[9*`DWIDTH-1:8*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[8]}};
	assign a9_data = a_data[10*`DWIDTH-1:9*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[9]}};
	assign a10_data = a_data[11*`DWIDTH-1:10*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[10]}};
	assign a11_data = a_data[12*`DWIDTH-1:11*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[11]}};
	assign a12_data = a_data[13*`DWIDTH-1:12*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[12]}};
	assign a13_data = a_data[14*`DWIDTH-1:13*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[13]}};
	assign a14_data = a_data[15*`DWIDTH-1:14*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[14]}};
	assign a15_data = a_data[16*`DWIDTH-1:15*`DWIDTH] & {`DWIDTH{a_data_valid}} & {`DWIDTH{validity_mask_a_rows[15]}};
	
	reg [`DWIDTH-1:0] a1_data_delayed_1;
	reg [`DWIDTH-1:0] a2_data_delayed_1;
	reg [`DWIDTH-1:0] a2_data_delayed_2;
	reg [`DWIDTH-1:0] a3_data_delayed_1;
	reg [`DWIDTH-1:0] a3_data_delayed_2;
	reg [`DWIDTH-1:0] a3_data_delayed_3;
	reg [`DWIDTH-1:0] a4_data_delayed_1;
	reg [`DWIDTH-1:0] a4_data_delayed_2;
	reg [`DWIDTH-1:0] a4_data_delayed_3;
	reg [`DWIDTH-1:0] a4_data_delayed_4;
	reg [`DWIDTH-1:0] a5_data_delayed_1;
	reg [`DWIDTH-1:0] a5_data_delayed_2;
	reg [`DWIDTH-1:0] a5_data_delayed_3;
	reg [`DWIDTH-1:0] a5_data_delayed_4;
	reg [`DWIDTH-1:0] a5_data_delayed_5;
	reg [`DWIDTH-1:0] a6_data_delayed_1;
	reg [`DWIDTH-1:0] a6_data_delayed_2;
	reg [`DWIDTH-1:0] a6_data_delayed_3;
	reg [`DWIDTH-1:0] a6_data_delayed_4;
	reg [`DWIDTH-1:0] a6_data_delayed_5;
	reg [`DWIDTH-1:0] a6_data_delayed_6;
	reg [`DWIDTH-1:0] a7_data_delayed_1;
	reg [`DWIDTH-1:0] a7_data_delayed_2;
	reg [`DWIDTH-1:0] a7_data_delayed_3;
	reg [`DWIDTH-1:0] a7_data_delayed_4;
	reg [`DWIDTH-1:0] a7_data_delayed_5;
	reg [`DWIDTH-1:0] a7_data_delayed_6;
	reg [`DWIDTH-1:0] a7_data_delayed_7;
	reg [`DWIDTH-1:0] a8_data_delayed_1;
	reg [`DWIDTH-1:0] a8_data_delayed_2;
	reg [`DWIDTH-1:0] a8_data_delayed_3;
	reg [`DWIDTH-1:0] a8_data_delayed_4;
	reg [`DWIDTH-1:0] a8_data_delayed_5;
	reg [`DWIDTH-1:0] a8_data_delayed_6;
	reg [`DWIDTH-1:0] a8_data_delayed_7;
	reg [`DWIDTH-1:0] a8_data_delayed_8;
	reg [`DWIDTH-1:0] a9_data_delayed_1;
	reg [`DWIDTH-1:0] a9_data_delayed_2;
	reg [`DWIDTH-1:0] a9_data_delayed_3;
	reg [`DWIDTH-1:0] a9_data_delayed_4;
	reg [`DWIDTH-1:0] a9_data_delayed_5;
	reg [`DWIDTH-1:0] a9_data_delayed_6;
	reg [`DWIDTH-1:0] a9_data_delayed_7;
	reg [`DWIDTH-1:0] a9_data_delayed_8;
	reg [`DWIDTH-1:0] a9_data_delayed_9;
	reg [`DWIDTH-1:0] a10_data_delayed_1;
	reg [`DWIDTH-1:0] a10_data_delayed_2;
	reg [`DWIDTH-1:0] a10_data_delayed_3;
	reg [`DWIDTH-1:0] a10_data_delayed_4;
	reg [`DWIDTH-1:0] a10_data_delayed_5;
	reg [`DWIDTH-1:0] a10_data_delayed_6;
	reg [`DWIDTH-1:0] a10_data_delayed_7;
	reg [`DWIDTH-1:0] a10_data_delayed_8;
	reg [`DWIDTH-1:0] a10_data_delayed_9;
	reg [`DWIDTH-1:0] a10_data_delayed_10;
	reg [`DWIDTH-1:0] a11_data_delayed_1;
	reg [`DWIDTH-1:0] a11_data_delayed_2;
	reg [`DWIDTH-1:0] a11_data_delayed_3;
	reg [`DWIDTH-1:0] a11_data_delayed_4;
	reg [`DWIDTH-1:0] a11_data_delayed_5;
	reg [`DWIDTH-1:0] a11_data_delayed_6;
	reg [`DWIDTH-1:0] a11_data_delayed_7;
	reg [`DWIDTH-1:0] a11_data_delayed_8;
	reg [`DWIDTH-1:0] a11_data_delayed_9;
	reg [`DWIDTH-1:0] a11_data_delayed_10;
	reg [`DWIDTH-1:0] a11_data_delayed_11;
	reg [`DWIDTH-1:0] a12_data_delayed_1;
	reg [`DWIDTH-1:0] a12_data_delayed_2;
	reg [`DWIDTH-1:0] a12_data_delayed_3;
	reg [`DWIDTH-1:0] a12_data_delayed_4;
	reg [`DWIDTH-1:0] a12_data_delayed_5;
	reg [`DWIDTH-1:0] a12_data_delayed_6;
	reg [`DWIDTH-1:0] a12_data_delayed_7;
	reg [`DWIDTH-1:0] a12_data_delayed_8;
	reg [`DWIDTH-1:0] a12_data_delayed_9;
	reg [`DWIDTH-1:0] a12_data_delayed_10;
	reg [`DWIDTH-1:0] a12_data_delayed_11;
	reg [`DWIDTH-1:0] a12_data_delayed_12;
	reg [`DWIDTH-1:0] a13_data_delayed_1;
	reg [`DWIDTH-1:0] a13_data_delayed_2;
	reg [`DWIDTH-1:0] a13_data_delayed_3;
	reg [`DWIDTH-1:0] a13_data_delayed_4;
	reg [`DWIDTH-1:0] a13_data_delayed_5;
	reg [`DWIDTH-1:0] a13_data_delayed_6;
	reg [`DWIDTH-1:0] a13_data_delayed_7;
	reg [`DWIDTH-1:0] a13_data_delayed_8;
	reg [`DWIDTH-1:0] a13_data_delayed_9;
	reg [`DWIDTH-1:0] a13_data_delayed_10;
	reg [`DWIDTH-1:0] a13_data_delayed_11;
	reg [`DWIDTH-1:0] a13_data_delayed_12;
	reg [`DWIDTH-1:0] a13_data_delayed_13;
	reg [`DWIDTH-1:0] a14_data_delayed_1;
	reg [`DWIDTH-1:0] a14_data_delayed_2;
	reg [`DWIDTH-1:0] a14_data_delayed_3;
	reg [`DWIDTH-1:0] a14_data_delayed_4;
	reg [`DWIDTH-1:0] a14_data_delayed_5;
	reg [`DWIDTH-1:0] a14_data_delayed_6;
	reg [`DWIDTH-1:0] a14_data_delayed_7;
	reg [`DWIDTH-1:0] a14_data_delayed_8;
	reg [`DWIDTH-1:0] a14_data_delayed_9;
	reg [`DWIDTH-1:0] a14_data_delayed_10;
	reg [`DWIDTH-1:0] a14_data_delayed_11;
	reg [`DWIDTH-1:0] a14_data_delayed_12;
	reg [`DWIDTH-1:0] a14_data_delayed_13;
	reg [`DWIDTH-1:0] a14_data_delayed_14;
	reg [`DWIDTH-1:0] a15_data_delayed_1;
	reg [`DWIDTH-1:0] a15_data_delayed_2;
	reg [`DWIDTH-1:0] a15_data_delayed_3;
	reg [`DWIDTH-1:0] a15_data_delayed_4;
	reg [`DWIDTH-1:0] a15_data_delayed_5;
	reg [`DWIDTH-1:0] a15_data_delayed_6;
	reg [`DWIDTH-1:0] a15_data_delayed_7;
	reg [`DWIDTH-1:0] a15_data_delayed_8;
	reg [`DWIDTH-1:0] a15_data_delayed_9;
	reg [`DWIDTH-1:0] a15_data_delayed_10;
	reg [`DWIDTH-1:0] a15_data_delayed_11;
	reg [`DWIDTH-1:0] a15_data_delayed_12;
	reg [`DWIDTH-1:0] a15_data_delayed_13;
	reg [`DWIDTH-1:0] a15_data_delayed_14;
	reg [`DWIDTH-1:0] a15_data_delayed_15;
	
	
	always @(posedge clk) begin
	  if (reset || ~start_mat_mul || clk_cnt==0) begin
		a1_data_delayed_1 <= 0;
		a2_data_delayed_1 <= 0;
		a2_data_delayed_2 <= 0;
		a3_data_delayed_1 <= 0;
		a3_data_delayed_2 <= 0;
		a3_data_delayed_3 <= 0;
		a4_data_delayed_1 <= 0;
		a4_data_delayed_2 <= 0;
		a4_data_delayed_3 <= 0;
		a4_data_delayed_4 <= 0;
		a5_data_delayed_1 <= 0;
		a5_data_delayed_2 <= 0;
		a5_data_delayed_3 <= 0;
		a5_data_delayed_4 <= 0;
		a5_data_delayed_5 <= 0;
		a6_data_delayed_1 <= 0;
		a6_data_delayed_2 <= 0;
		a6_data_delayed_3 <= 0;
		a6_data_delayed_4 <= 0;
		a6_data_delayed_5 <= 0;
		a6_data_delayed_6 <= 0;
		a7_data_delayed_1 <= 0;
		a7_data_delayed_2 <= 0;
		a7_data_delayed_3 <= 0;
		a7_data_delayed_4 <= 0;
		a7_data_delayed_5 <= 0;
		a7_data_delayed_6 <= 0;
		a7_data_delayed_7 <= 0;
		a8_data_delayed_1 <= 0;
		a8_data_delayed_2 <= 0;
		a8_data_delayed_3 <= 0;
		a8_data_delayed_4 <= 0;
		a8_data_delayed_5 <= 0;
		a8_data_delayed_6 <= 0;
		a8_data_delayed_7 <= 0;
		a8_data_delayed_8 <= 0;
		a9_data_delayed_1 <= 0;
		a9_data_delayed_2 <= 0;
		a9_data_delayed_3 <= 0;
		a9_data_delayed_4 <= 0;
		a9_data_delayed_5 <= 0;
		a9_data_delayed_6 <= 0;
		a9_data_delayed_7 <= 0;
		a9_data_delayed_8 <= 0;
		a9_data_delayed_9 <= 0;
		a10_data_delayed_1 <= 0;
		a10_data_delayed_2 <= 0;
		a10_data_delayed_3 <= 0;
		a10_data_delayed_4 <= 0;
		a10_data_delayed_5 <= 0;
		a10_data_delayed_6 <= 0;
		a10_data_delayed_7 <= 0;
		a10_data_delayed_8 <= 0;
		a10_data_delayed_9 <= 0;
		a10_data_delayed_10 <= 0;
		a11_data_delayed_1 <= 0;
		a11_data_delayed_2 <= 0;
		a11_data_delayed_3 <= 0;
		a11_data_delayed_4 <= 0;
		a11_data_delayed_5 <= 0;
		a11_data_delayed_6 <= 0;
		a11_data_delayed_7 <= 0;
		a11_data_delayed_8 <= 0;
		a11_data_delayed_9 <= 0;
		a11_data_delayed_10 <= 0;
		a11_data_delayed_11 <= 0;
		a12_data_delayed_1 <= 0;
		a12_data_delayed_2 <= 0;
		a12_data_delayed_3 <= 0;
		a12_data_delayed_4 <= 0;
		a12_data_delayed_5 <= 0;
		a12_data_delayed_6 <= 0;
		a12_data_delayed_7 <= 0;
		a12_data_delayed_8 <= 0;
		a12_data_delayed_9 <= 0;
		a12_data_delayed_10 <= 0;
		a12_data_delayed_11 <= 0;
		a12_data_delayed_12 <= 0;
		a13_data_delayed_1 <= 0;
		a13_data_delayed_2 <= 0;
		a13_data_delayed_3 <= 0;
		a13_data_delayed_4 <= 0;
		a13_data_delayed_5 <= 0;
		a13_data_delayed_6 <= 0;
		a13_data_delayed_7 <= 0;
		a13_data_delayed_8 <= 0;
		a13_data_delayed_9 <= 0;
		a13_data_delayed_10 <= 0;
		a13_data_delayed_11 <= 0;
		a13_data_delayed_12 <= 0;
		a13_data_delayed_13 <= 0;
		a14_data_delayed_1 <= 0;
		a14_data_delayed_2 <= 0;
		a14_data_delayed_3 <= 0;
		a14_data_delayed_4 <= 0;
		a14_data_delayed_5 <= 0;
		a14_data_delayed_6 <= 0;
		a14_data_delayed_7 <= 0;
		a14_data_delayed_8 <= 0;
		a14_data_delayed_9 <= 0;
		a14_data_delayed_10 <= 0;
		a14_data_delayed_11 <= 0;
		a14_data_delayed_12 <= 0;
		a14_data_delayed_13 <= 0;
		a14_data_delayed_14 <= 0;
		a15_data_delayed_1 <= 0;
		a15_data_delayed_2 <= 0;
		a15_data_delayed_3 <= 0;
		a15_data_delayed_4 <= 0;
		a15_data_delayed_5 <= 0;
		a15_data_delayed_6 <= 0;
		a15_data_delayed_7 <= 0;
		a15_data_delayed_8 <= 0;
		a15_data_delayed_9 <= 0;
		a15_data_delayed_10 <= 0;
		a15_data_delayed_11 <= 0;
		a15_data_delayed_12 <= 0;
		a15_data_delayed_13 <= 0;
		a15_data_delayed_14 <= 0;
		a15_data_delayed_15 <= 0;
	
	  end
	  else begin
	  a1_data_delayed_1 <= a1_data;
	  a2_data_delayed_1 <= a2_data;
	  a3_data_delayed_1 <= a3_data;
	  a4_data_delayed_1 <= a4_data;
	  a5_data_delayed_1 <= a5_data;
	  a6_data_delayed_1 <= a6_data;
	  a7_data_delayed_1 <= a7_data;
	  a8_data_delayed_1 <= a8_data;
	  a9_data_delayed_1 <= a9_data;
	  a10_data_delayed_1 <= a10_data;
	  a11_data_delayed_1 <= a11_data;
	  a12_data_delayed_1 <= a12_data;
	  a13_data_delayed_1 <= a13_data;
	  a14_data_delayed_1 <= a14_data;
	  a15_data_delayed_1 <= a15_data;
	  a2_data_delayed_2 <= a2_data_delayed_1;
	  a3_data_delayed_2 <= a3_data_delayed_1;
	  a3_data_delayed_3 <= a3_data_delayed_2;
	  a4_data_delayed_2 <= a4_data_delayed_1;
	  a4_data_delayed_3 <= a4_data_delayed_2;
	  a4_data_delayed_4 <= a4_data_delayed_3;
	  a5_data_delayed_2 <= a5_data_delayed_1;
	  a5_data_delayed_3 <= a5_data_delayed_2;
	  a5_data_delayed_4 <= a5_data_delayed_3;
	  a5_data_delayed_5 <= a5_data_delayed_4;
	  a6_data_delayed_2 <= a6_data_delayed_1;
	  a6_data_delayed_3 <= a6_data_delayed_2;
	  a6_data_delayed_4 <= a6_data_delayed_3;
	  a6_data_delayed_5 <= a6_data_delayed_4;
	  a6_data_delayed_6 <= a6_data_delayed_5;
	  a7_data_delayed_2 <= a7_data_delayed_1;
	  a7_data_delayed_3 <= a7_data_delayed_2;
	  a7_data_delayed_4 <= a7_data_delayed_3;
	  a7_data_delayed_5 <= a7_data_delayed_4;
	  a7_data_delayed_6 <= a7_data_delayed_5;
	  a7_data_delayed_7 <= a7_data_delayed_6;
	  a8_data_delayed_2 <= a8_data_delayed_1;
	  a8_data_delayed_3 <= a8_data_delayed_2;
	  a8_data_delayed_4 <= a8_data_delayed_3;
	  a8_data_delayed_5 <= a8_data_delayed_4;
	  a8_data_delayed_6 <= a8_data_delayed_5;
	  a8_data_delayed_7 <= a8_data_delayed_6;
	  a8_data_delayed_8 <= a8_data_delayed_7;
	  a9_data_delayed_2 <= a9_data_delayed_1;
	  a9_data_delayed_3 <= a9_data_delayed_2;
	  a9_data_delayed_4 <= a9_data_delayed_3;
	  a9_data_delayed_5 <= a9_data_delayed_4;
	  a9_data_delayed_6 <= a9_data_delayed_5;
	  a9_data_delayed_7 <= a9_data_delayed_6;
	  a9_data_delayed_8 <= a9_data_delayed_7;
	  a9_data_delayed_9 <= a9_data_delayed_8;
	  a10_data_delayed_2 <= a10_data_delayed_1;
	  a10_data_delayed_3 <= a10_data_delayed_2;
	  a10_data_delayed_4 <= a10_data_delayed_3;
	  a10_data_delayed_5 <= a10_data_delayed_4;
	  a10_data_delayed_6 <= a10_data_delayed_5;
	  a10_data_delayed_7 <= a10_data_delayed_6;
	  a10_data_delayed_8 <= a10_data_delayed_7;
	  a10_data_delayed_9 <= a10_data_delayed_8;
	  a10_data_delayed_10 <= a10_data_delayed_9;
	  a11_data_delayed_2 <= a11_data_delayed_1;
	  a11_data_delayed_3 <= a11_data_delayed_2;
	  a11_data_delayed_4 <= a11_data_delayed_3;
	  a11_data_delayed_5 <= a11_data_delayed_4;
	  a11_data_delayed_6 <= a11_data_delayed_5;
	  a11_data_delayed_7 <= a11_data_delayed_6;
	  a11_data_delayed_8 <= a11_data_delayed_7;
	  a11_data_delayed_9 <= a11_data_delayed_8;
	  a11_data_delayed_10 <= a11_data_delayed_9;
	  a11_data_delayed_11 <= a11_data_delayed_10;
	  a12_data_delayed_2 <= a12_data_delayed_1;
	  a12_data_delayed_3 <= a12_data_delayed_2;
	  a12_data_delayed_4 <= a12_data_delayed_3;
	  a12_data_delayed_5 <= a12_data_delayed_4;
	  a12_data_delayed_6 <= a12_data_delayed_5;
	  a12_data_delayed_7 <= a12_data_delayed_6;
	  a12_data_delayed_8 <= a12_data_delayed_7;
	  a12_data_delayed_9 <= a12_data_delayed_8;
	  a12_data_delayed_10 <= a12_data_delayed_9;
	  a12_data_delayed_11 <= a12_data_delayed_10;
	  a12_data_delayed_12 <= a12_data_delayed_11;
	  a13_data_delayed_2 <= a13_data_delayed_1;
	  a13_data_delayed_3 <= a13_data_delayed_2;
	  a13_data_delayed_4 <= a13_data_delayed_3;
	  a13_data_delayed_5 <= a13_data_delayed_4;
	  a13_data_delayed_6 <= a13_data_delayed_5;
	  a13_data_delayed_7 <= a13_data_delayed_6;
	  a13_data_delayed_8 <= a13_data_delayed_7;
	  a13_data_delayed_9 <= a13_data_delayed_8;
	  a13_data_delayed_10 <= a13_data_delayed_9;
	  a13_data_delayed_11 <= a13_data_delayed_10;
	  a13_data_delayed_12 <= a13_data_delayed_11;
	  a13_data_delayed_13 <= a13_data_delayed_12;
	  a14_data_delayed_2 <= a14_data_delayed_1;
	  a14_data_delayed_3 <= a14_data_delayed_2;
	  a14_data_delayed_4 <= a14_data_delayed_3;
	  a14_data_delayed_5 <= a14_data_delayed_4;
	  a14_data_delayed_6 <= a14_data_delayed_5;
	  a14_data_delayed_7 <= a14_data_delayed_6;
	  a14_data_delayed_8 <= a14_data_delayed_7;
	  a14_data_delayed_9 <= a14_data_delayed_8;
	  a14_data_delayed_10 <= a14_data_delayed_9;
	  a14_data_delayed_11 <= a14_data_delayed_10;
	  a14_data_delayed_12 <= a14_data_delayed_11;
	  a14_data_delayed_13 <= a14_data_delayed_12;
	  a14_data_delayed_14 <= a14_data_delayed_13;
	  a15_data_delayed_2 <= a15_data_delayed_1;
	  a15_data_delayed_3 <= a15_data_delayed_2;
	  a15_data_delayed_4 <= a15_data_delayed_3;
	  a15_data_delayed_5 <= a15_data_delayed_4;
	  a15_data_delayed_6 <= a15_data_delayed_5;
	  a15_data_delayed_7 <= a15_data_delayed_6;
	  a15_data_delayed_8 <= a15_data_delayed_7;
	  a15_data_delayed_9 <= a15_data_delayed_8;
	  a15_data_delayed_10 <= a15_data_delayed_9;
	  a15_data_delayed_11 <= a15_data_delayed_10;
	  a15_data_delayed_12 <= a15_data_delayed_11;
	  a15_data_delayed_13 <= a15_data_delayed_12;
	  a15_data_delayed_14 <= a15_data_delayed_13;
	  a15_data_delayed_15 <= a15_data_delayed_14;
	 
	  end
	end
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to generate addresses to BRAM B
	//////////////////////////////////////////////////////////////////////////
	reg [`AWIDTH-1:0] b_addr;
	reg b_mem_access; //flag that tells whether the matmul is trying to access memory or not
	always @(posedge clk) begin
	  //else if (clk_cnt >= b_loc*`MAT_MUL_SIZE+final_mat_mul_size) begin
	  //Writing the line above to avoid multiplication:
	
	  if ((reset || ~start_mat_mul) || (clk_cnt >= (b_loc<<`LOG2_MAT_MUL_SIZE)+`final_mat_mul_size)) begin
	
		  b_addr <= address_mat_b - address_stride_b;
	  
		b_mem_access <= 0;
	  end
	  //else if ((clk_cnt >= b_loc*`MAT_MUL_SIZE) && (clk_cnt < b_loc*`MAT_MUL_SIZE+final_mat_mul_size)) begin
	  //Writing the line above to avoid multiplication:
	
	  else if ((clk_cnt >= (b_loc<<`LOG2_MAT_MUL_SIZE)) && (clk_cnt < (b_loc<<`LOG2_MAT_MUL_SIZE)+`final_mat_mul_size)) begin
	
		  b_addr <= b_addr + address_stride_b;
	  
		b_mem_access <= 1;
	  end
	end 
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to generate valid signals for data coming from BRAM B
	//////////////////////////////////////////////////////////////////////////
	reg [7:0] b_mem_access_counter;
	always @(posedge clk) begin
	  if (reset || ~start_mat_mul) begin
		b_mem_access_counter <= 0;
	  end
	  else if (b_mem_access == 1) begin
		b_mem_access_counter <= b_mem_access_counter + 1;  
	  end
	  else begin
		b_mem_access_counter <= 0;
	  end
	end
	
	wire b_data_valid; //flag that tells whether the data from memory is valid
	assign b_data_valid = 
		 ((validity_mask_b_rows[0]==1'b0 && b_mem_access_counter==1) ||
		  (validity_mask_b_rows[1]==1'b0 && b_mem_access_counter==2) ||
		  (validity_mask_b_rows[2]==1'b0 && b_mem_access_counter==3) ||
		  (validity_mask_b_rows[3]==1'b0 && b_mem_access_counter==4) ||
		  (validity_mask_b_rows[4]==1'b0 && b_mem_access_counter==5) ||
		  (validity_mask_b_rows[5]==1'b0 && b_mem_access_counter==6) ||
		  (validity_mask_b_rows[6]==1'b0 && b_mem_access_counter==7) ||
		  (validity_mask_b_rows[7]==1'b0 && b_mem_access_counter==8) ||
		  (validity_mask_b_rows[8]==1'b0 && b_mem_access_counter==9) ||
		  (validity_mask_b_rows[9]==1'b0 && b_mem_access_counter==10) ||
		  (validity_mask_b_rows[10]==1'b0 && b_mem_access_counter==11) ||
		  (validity_mask_b_rows[11]==1'b0 && b_mem_access_counter==12) ||
		  (validity_mask_b_rows[12]==1'b0 && b_mem_access_counter==13) ||
		  (validity_mask_b_rows[13]==1'b0 && b_mem_access_counter==14) ||
		  (validity_mask_b_rows[14]==1'b0 && b_mem_access_counter==15) ||
		  (validity_mask_b_rows[15]==1'b0 && b_mem_access_counter==16)) ?
		
			1'b0 : (b_mem_access_counter >= `MEM_ACCESS_LATENCY);
	
	//////////////////////////////////////////////////////////////////////////
	// Logic to delay certain parts of the data received from BRAM B (systolic data setup)
	//////////////////////////////////////////////////////////////////////////
	assign b0_data = b_data[1*`DWIDTH-1:0*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[0]}};
	assign b1_data = b_data[2*`DWIDTH-1:1*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[1]}};
	assign b2_data = b_data[3*`DWIDTH-1:2*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[2]}};
	assign b3_data = b_data[4*`DWIDTH-1:3*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[3]}};
	assign b4_data = b_data[5*`DWIDTH-1:4*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[4]}};
	assign b5_data = b_data[6*`DWIDTH-1:5*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[5]}};
	assign b6_data = b_data[7*`DWIDTH-1:6*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[6]}};
	assign b7_data = b_data[8*`DWIDTH-1:7*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[7]}};
	assign b8_data = b_data[9*`DWIDTH-1:8*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[8]}};
	assign b9_data = b_data[10*`DWIDTH-1:9*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[9]}};
	assign b10_data = b_data[11*`DWIDTH-1:10*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[10]}};
	assign b11_data = b_data[12*`DWIDTH-1:11*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[11]}};
	assign b12_data = b_data[13*`DWIDTH-1:12*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[12]}};
	assign b13_data = b_data[14*`DWIDTH-1:13*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[13]}};
	assign b14_data = b_data[15*`DWIDTH-1:14*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[14]}};
	assign b15_data = b_data[16*`DWIDTH-1:15*`DWIDTH] & {`DWIDTH{b_data_valid}} & {`DWIDTH{validity_mask_b_cols[15]}};
	
	reg [`DWIDTH-1:0] b1_data_delayed_1;
	reg [`DWIDTH-1:0] b2_data_delayed_1;
	reg [`DWIDTH-1:0] b2_data_delayed_2;
	reg [`DWIDTH-1:0] b3_data_delayed_1;
	reg [`DWIDTH-1:0] b3_data_delayed_2;
	reg [`DWIDTH-1:0] b3_data_delayed_3;
	reg [`DWIDTH-1:0] b4_data_delayed_1;
	reg [`DWIDTH-1:0] b4_data_delayed_2;
	reg [`DWIDTH-1:0] b4_data_delayed_3;
	reg [`DWIDTH-1:0] b4_data_delayed_4;
	reg [`DWIDTH-1:0] b5_data_delayed_1;
	reg [`DWIDTH-1:0] b5_data_delayed_2;
	reg [`DWIDTH-1:0] b5_data_delayed_3;
	reg [`DWIDTH-1:0] b5_data_delayed_4;
	reg [`DWIDTH-1:0] b5_data_delayed_5;
	reg [`DWIDTH-1:0] b6_data_delayed_1;
	reg [`DWIDTH-1:0] b6_data_delayed_2;
	reg [`DWIDTH-1:0] b6_data_delayed_3;
	reg [`DWIDTH-1:0] b6_data_delayed_4;
	reg [`DWIDTH-1:0] b6_data_delayed_5;
	reg [`DWIDTH-1:0] b6_data_delayed_6;
	reg [`DWIDTH-1:0] b7_data_delayed_1;
	reg [`DWIDTH-1:0] b7_data_delayed_2;
	reg [`DWIDTH-1:0] b7_data_delayed_3;
	reg [`DWIDTH-1:0] b7_data_delayed_4;
	reg [`DWIDTH-1:0] b7_data_delayed_5;
	reg [`DWIDTH-1:0] b7_data_delayed_6;
	reg [`DWIDTH-1:0] b7_data_delayed_7;
	reg [`DWIDTH-1:0] b8_data_delayed_1;
	reg [`DWIDTH-1:0] b8_data_delayed_2;
	reg [`DWIDTH-1:0] b8_data_delayed_3;
	reg [`DWIDTH-1:0] b8_data_delayed_4;
	reg [`DWIDTH-1:0] b8_data_delayed_5;
	reg [`DWIDTH-1:0] b8_data_delayed_6;
	reg [`DWIDTH-1:0] b8_data_delayed_7;
	reg [`DWIDTH-1:0] b8_data_delayed_8;
	reg [`DWIDTH-1:0] b9_data_delayed_1;
	reg [`DWIDTH-1:0] b9_data_delayed_2;
	reg [`DWIDTH-1:0] b9_data_delayed_3;
	reg [`DWIDTH-1:0] b9_data_delayed_4;
	reg [`DWIDTH-1:0] b9_data_delayed_5;
	reg [`DWIDTH-1:0] b9_data_delayed_6;
	reg [`DWIDTH-1:0] b9_data_delayed_7;
	reg [`DWIDTH-1:0] b9_data_delayed_8;
	reg [`DWIDTH-1:0] b9_data_delayed_9;
	reg [`DWIDTH-1:0] b10_data_delayed_1;
	reg [`DWIDTH-1:0] b10_data_delayed_2;
	reg [`DWIDTH-1:0] b10_data_delayed_3;
	reg [`DWIDTH-1:0] b10_data_delayed_4;
	reg [`DWIDTH-1:0] b10_data_delayed_5;
	reg [`DWIDTH-1:0] b10_data_delayed_6;
	reg [`DWIDTH-1:0] b10_data_delayed_7;
	reg [`DWIDTH-1:0] b10_data_delayed_8;
	reg [`DWIDTH-1:0] b10_data_delayed_9;
	reg [`DWIDTH-1:0] b10_data_delayed_10;
	reg [`DWIDTH-1:0] b11_data_delayed_1;
	reg [`DWIDTH-1:0] b11_data_delayed_2;
	reg [`DWIDTH-1:0] b11_data_delayed_3;
	reg [`DWIDTH-1:0] b11_data_delayed_4;
	reg [`DWIDTH-1:0] b11_data_delayed_5;
	reg [`DWIDTH-1:0] b11_data_delayed_6;
	reg [`DWIDTH-1:0] b11_data_delayed_7;
	reg [`DWIDTH-1:0] b11_data_delayed_8;
	reg [`DWIDTH-1:0] b11_data_delayed_9;
	reg [`DWIDTH-1:0] b11_data_delayed_10;
	reg [`DWIDTH-1:0] b11_data_delayed_11;
	reg [`DWIDTH-1:0] b12_data_delayed_1;
	reg [`DWIDTH-1:0] b12_data_delayed_2;
	reg [`DWIDTH-1:0] b12_data_delayed_3;
	reg [`DWIDTH-1:0] b12_data_delayed_4;
	reg [`DWIDTH-1:0] b12_data_delayed_5;
	reg [`DWIDTH-1:0] b12_data_delayed_6;
	reg [`DWIDTH-1:0] b12_data_delayed_7;
	reg [`DWIDTH-1:0] b12_data_delayed_8;
	reg [`DWIDTH-1:0] b12_data_delayed_9;
	reg [`DWIDTH-1:0] b12_data_delayed_10;
	reg [`DWIDTH-1:0] b12_data_delayed_11;
	reg [`DWIDTH-1:0] b12_data_delayed_12;
	reg [`DWIDTH-1:0] b13_data_delayed_1;
	reg [`DWIDTH-1:0] b13_data_delayed_2;
	reg [`DWIDTH-1:0] b13_data_delayed_3;
	reg [`DWIDTH-1:0] b13_data_delayed_4;
	reg [`DWIDTH-1:0] b13_data_delayed_5;
	reg [`DWIDTH-1:0] b13_data_delayed_6;
	reg [`DWIDTH-1:0] b13_data_delayed_7;
	reg [`DWIDTH-1:0] b13_data_delayed_8;
	reg [`DWIDTH-1:0] b13_data_delayed_9;
	reg [`DWIDTH-1:0] b13_data_delayed_10;
	reg [`DWIDTH-1:0] b13_data_delayed_11;
	reg [`DWIDTH-1:0] b13_data_delayed_12;
	reg [`DWIDTH-1:0] b13_data_delayed_13;
	reg [`DWIDTH-1:0] b14_data_delayed_1;
	reg [`DWIDTH-1:0] b14_data_delayed_2;
	reg [`DWIDTH-1:0] b14_data_delayed_3;
	reg [`DWIDTH-1:0] b14_data_delayed_4;
	reg [`DWIDTH-1:0] b14_data_delayed_5;
	reg [`DWIDTH-1:0] b14_data_delayed_6;
	reg [`DWIDTH-1:0] b14_data_delayed_7;
	reg [`DWIDTH-1:0] b14_data_delayed_8;
	reg [`DWIDTH-1:0] b14_data_delayed_9;
	reg [`DWIDTH-1:0] b14_data_delayed_10;
	reg [`DWIDTH-1:0] b14_data_delayed_11;
	reg [`DWIDTH-1:0] b14_data_delayed_12;
	reg [`DWIDTH-1:0] b14_data_delayed_13;
	reg [`DWIDTH-1:0] b14_data_delayed_14;
	reg [`DWIDTH-1:0] b15_data_delayed_1;
	reg [`DWIDTH-1:0] b15_data_delayed_2;
	reg [`DWIDTH-1:0] b15_data_delayed_3;
	reg [`DWIDTH-1:0] b15_data_delayed_4;
	reg [`DWIDTH-1:0] b15_data_delayed_5;
	reg [`DWIDTH-1:0] b15_data_delayed_6;
	reg [`DWIDTH-1:0] b15_data_delayed_7;
	reg [`DWIDTH-1:0] b15_data_delayed_8;
	reg [`DWIDTH-1:0] b15_data_delayed_9;
	reg [`DWIDTH-1:0] b15_data_delayed_10;
	reg [`DWIDTH-1:0] b15_data_delayed_11;
	reg [`DWIDTH-1:0] b15_data_delayed_12;
	reg [`DWIDTH-1:0] b15_data_delayed_13;
	reg [`DWIDTH-1:0] b15_data_delayed_14;
	reg [`DWIDTH-1:0] b15_data_delayed_15;
	
	
	always @(posedge clk) begin
	  if (reset || ~start_mat_mul || clk_cnt==0) begin
		b1_data_delayed_1 <= 0;
		b2_data_delayed_1 <= 0;
		b2_data_delayed_2 <= 0;
		b3_data_delayed_1 <= 0;
		b3_data_delayed_2 <= 0;
		b3_data_delayed_3 <= 0;
		b4_data_delayed_1 <= 0;
		b4_data_delayed_2 <= 0;
		b4_data_delayed_3 <= 0;
		b4_data_delayed_4 <= 0;
		b5_data_delayed_1 <= 0;
		b5_data_delayed_2 <= 0;
		b5_data_delayed_3 <= 0;
		b5_data_delayed_4 <= 0;
		b5_data_delayed_5 <= 0;
		b6_data_delayed_1 <= 0;
		b6_data_delayed_2 <= 0;
		b6_data_delayed_3 <= 0;
		b6_data_delayed_4 <= 0;
		b6_data_delayed_5 <= 0;
		b6_data_delayed_6 <= 0;
		b7_data_delayed_1 <= 0;
		b7_data_delayed_2 <= 0;
		b7_data_delayed_3 <= 0;
		b7_data_delayed_4 <= 0;
		b7_data_delayed_5 <= 0;
		b7_data_delayed_6 <= 0;
		b7_data_delayed_7 <= 0;
		b8_data_delayed_1 <= 0;
		b8_data_delayed_2 <= 0;
		b8_data_delayed_3 <= 0;
		b8_data_delayed_4 <= 0;
		b8_data_delayed_5 <= 0;
		b8_data_delayed_6 <= 0;
		b8_data_delayed_7 <= 0;
		b8_data_delayed_8 <= 0;
		b9_data_delayed_1 <= 0;
		b9_data_delayed_2 <= 0;
		b9_data_delayed_3 <= 0;
		b9_data_delayed_4 <= 0;
		b9_data_delayed_5 <= 0;
		b9_data_delayed_6 <= 0;
		b9_data_delayed_7 <= 0;
		b9_data_delayed_8 <= 0;
		b9_data_delayed_9 <= 0;
		b10_data_delayed_1 <= 0;
		b10_data_delayed_2 <= 0;
		b10_data_delayed_3 <= 0;
		b10_data_delayed_4 <= 0;
		b10_data_delayed_5 <= 0;
		b10_data_delayed_6 <= 0;
		b10_data_delayed_7 <= 0;
		b10_data_delayed_8 <= 0;
		b10_data_delayed_9 <= 0;
		b10_data_delayed_10 <= 0;
		b11_data_delayed_1 <= 0;
		b11_data_delayed_2 <= 0;
		b11_data_delayed_3 <= 0;
		b11_data_delayed_4 <= 0;
		b11_data_delayed_5 <= 0;
		b11_data_delayed_6 <= 0;
		b11_data_delayed_7 <= 0;
		b11_data_delayed_8 <= 0;
		b11_data_delayed_9 <= 0;
		b11_data_delayed_10 <= 0;
		b11_data_delayed_11 <= 0;
		b12_data_delayed_1 <= 0;
		b12_data_delayed_2 <= 0;
		b12_data_delayed_3 <= 0;
		b12_data_delayed_4 <= 0;
		b12_data_delayed_5 <= 0;
		b12_data_delayed_6 <= 0;
		b12_data_delayed_7 <= 0;
		b12_data_delayed_8 <= 0;
		b12_data_delayed_9 <= 0;
		b12_data_delayed_10 <= 0;
		b12_data_delayed_11 <= 0;
		b12_data_delayed_12 <= 0;
		b13_data_delayed_1 <= 0;
		b13_data_delayed_2 <= 0;
		b13_data_delayed_3 <= 0;
		b13_data_delayed_4 <= 0;
		b13_data_delayed_5 <= 0;
		b13_data_delayed_6 <= 0;
		b13_data_delayed_7 <= 0;
		b13_data_delayed_8 <= 0;
		b13_data_delayed_9 <= 0;
		b13_data_delayed_10 <= 0;
		b13_data_delayed_11 <= 0;
		b13_data_delayed_12 <= 0;
		b13_data_delayed_13 <= 0;
		b14_data_delayed_1 <= 0;
		b14_data_delayed_2 <= 0;
		b14_data_delayed_3 <= 0;
		b14_data_delayed_4 <= 0;
		b14_data_delayed_5 <= 0;
		b14_data_delayed_6 <= 0;
		b14_data_delayed_7 <= 0;
		b14_data_delayed_8 <= 0;
		b14_data_delayed_9 <= 0;
		b14_data_delayed_10 <= 0;
		b14_data_delayed_11 <= 0;
		b14_data_delayed_12 <= 0;
		b14_data_delayed_13 <= 0;
		b14_data_delayed_14 <= 0;
		b15_data_delayed_1 <= 0;
		b15_data_delayed_2 <= 0;
		b15_data_delayed_3 <= 0;
		b15_data_delayed_4 <= 0;
		b15_data_delayed_5 <= 0;
		b15_data_delayed_6 <= 0;
		b15_data_delayed_7 <= 0;
		b15_data_delayed_8 <= 0;
		b15_data_delayed_9 <= 0;
		b15_data_delayed_10 <= 0;
		b15_data_delayed_11 <= 0;
		b15_data_delayed_12 <= 0;
		b15_data_delayed_13 <= 0;
		b15_data_delayed_14 <= 0;
		b15_data_delayed_15 <= 0;
	
	  end
	  else begin
	  b1_data_delayed_1 <= b1_data;
	  b2_data_delayed_1 <= b2_data;
	  b3_data_delayed_1 <= b3_data;
	  b4_data_delayed_1 <= b4_data;
	  b5_data_delayed_1 <= b5_data;
	  b6_data_delayed_1 <= b6_data;
	  b7_data_delayed_1 <= b7_data;
	  b8_data_delayed_1 <= b8_data;
	  b9_data_delayed_1 <= b9_data;
	  b10_data_delayed_1 <= b10_data;
	  b11_data_delayed_1 <= b11_data;
	  b12_data_delayed_1 <= b12_data;
	  b13_data_delayed_1 <= b13_data;
	  b14_data_delayed_1 <= b14_data;
	  b15_data_delayed_1 <= b15_data;
	  b2_data_delayed_2 <= b2_data_delayed_1;
	  b3_data_delayed_2 <= b3_data_delayed_1;
	  b3_data_delayed_3 <= b3_data_delayed_2;
	  b4_data_delayed_2 <= b4_data_delayed_1;
	  b4_data_delayed_3 <= b4_data_delayed_2;
	  b4_data_delayed_4 <= b4_data_delayed_3;
	  b5_data_delayed_2 <= b5_data_delayed_1;
	  b5_data_delayed_3 <= b5_data_delayed_2;
	  b5_data_delayed_4 <= b5_data_delayed_3;
	  b5_data_delayed_5 <= b5_data_delayed_4;
	  b6_data_delayed_2 <= b6_data_delayed_1;
	  b6_data_delayed_3 <= b6_data_delayed_2;
	  b6_data_delayed_4 <= b6_data_delayed_3;
	  b6_data_delayed_5 <= b6_data_delayed_4;
	  b6_data_delayed_6 <= b6_data_delayed_5;
	  b7_data_delayed_2 <= b7_data_delayed_1;
	  b7_data_delayed_3 <= b7_data_delayed_2;
	  b7_data_delayed_4 <= b7_data_delayed_3;
	  b7_data_delayed_5 <= b7_data_delayed_4;
	  b7_data_delayed_6 <= b7_data_delayed_5;
	  b7_data_delayed_7 <= b7_data_delayed_6;
	  b8_data_delayed_2 <= b8_data_delayed_1;
	  b8_data_delayed_3 <= b8_data_delayed_2;
	  b8_data_delayed_4 <= b8_data_delayed_3;
	  b8_data_delayed_5 <= b8_data_delayed_4;
	  b8_data_delayed_6 <= b8_data_delayed_5;
	  b8_data_delayed_7 <= b8_data_delayed_6;
	  b8_data_delayed_8 <= b8_data_delayed_7;
	  b9_data_delayed_2 <= b9_data_delayed_1;
	  b9_data_delayed_3 <= b9_data_delayed_2;
	  b9_data_delayed_4 <= b9_data_delayed_3;
	  b9_data_delayed_5 <= b9_data_delayed_4;
	  b9_data_delayed_6 <= b9_data_delayed_5;
	  b9_data_delayed_7 <= b9_data_delayed_6;
	  b9_data_delayed_8 <= b9_data_delayed_7;
	  b9_data_delayed_9 <= b9_data_delayed_8;
	  b10_data_delayed_2 <= b10_data_delayed_1;
	  b10_data_delayed_3 <= b10_data_delayed_2;
	  b10_data_delayed_4 <= b10_data_delayed_3;
	  b10_data_delayed_5 <= b10_data_delayed_4;
	  b10_data_delayed_6 <= b10_data_delayed_5;
	  b10_data_delayed_7 <= b10_data_delayed_6;
	  b10_data_delayed_8 <= b10_data_delayed_7;
	  b10_data_delayed_9 <= b10_data_delayed_8;
	  b10_data_delayed_10 <= b10_data_delayed_9;
	  b11_data_delayed_2 <= b11_data_delayed_1;
	  b11_data_delayed_3 <= b11_data_delayed_2;
	  b11_data_delayed_4 <= b11_data_delayed_3;
	  b11_data_delayed_5 <= b11_data_delayed_4;
	  b11_data_delayed_6 <= b11_data_delayed_5;
	  b11_data_delayed_7 <= b11_data_delayed_6;
	  b11_data_delayed_8 <= b11_data_delayed_7;
	  b11_data_delayed_9 <= b11_data_delayed_8;
	  b11_data_delayed_10 <= b11_data_delayed_9;
	  b11_data_delayed_11 <= b11_data_delayed_10;
	  b12_data_delayed_2 <= b12_data_delayed_1;
	  b12_data_delayed_3 <= b12_data_delayed_2;
	  b12_data_delayed_4 <= b12_data_delayed_3;
	  b12_data_delayed_5 <= b12_data_delayed_4;
	  b12_data_delayed_6 <= b12_data_delayed_5;
	  b12_data_delayed_7 <= b12_data_delayed_6;
	  b12_data_delayed_8 <= b12_data_delayed_7;
	  b12_data_delayed_9 <= b12_data_delayed_8;
	  b12_data_delayed_10 <= b12_data_delayed_9;
	  b12_data_delayed_11 <= b12_data_delayed_10;
	  b12_data_delayed_12 <= b12_data_delayed_11;
	  b13_data_delayed_2 <= b13_data_delayed_1;
	  b13_data_delayed_3 <= b13_data_delayed_2;
	  b13_data_delayed_4 <= b13_data_delayed_3;
	  b13_data_delayed_5 <= b13_data_delayed_4;
	  b13_data_delayed_6 <= b13_data_delayed_5;
	  b13_data_delayed_7 <= b13_data_delayed_6;
	  b13_data_delayed_8 <= b13_data_delayed_7;
	  b13_data_delayed_9 <= b13_data_delayed_8;
	  b13_data_delayed_10 <= b13_data_delayed_9;
	  b13_data_delayed_11 <= b13_data_delayed_10;
	  b13_data_delayed_12 <= b13_data_delayed_11;
	  b13_data_delayed_13 <= b13_data_delayed_12;
	  b14_data_delayed_2 <= b14_data_delayed_1;
	  b14_data_delayed_3 <= b14_data_delayed_2;
	  b14_data_delayed_4 <= b14_data_delayed_3;
	  b14_data_delayed_5 <= b14_data_delayed_4;
	  b14_data_delayed_6 <= b14_data_delayed_5;
	  b14_data_delayed_7 <= b14_data_delayed_6;
	  b14_data_delayed_8 <= b14_data_delayed_7;
	  b14_data_delayed_9 <= b14_data_delayed_8;
	  b14_data_delayed_10 <= b14_data_delayed_9;
	  b14_data_delayed_11 <= b14_data_delayed_10;
	  b14_data_delayed_12 <= b14_data_delayed_11;
	  b14_data_delayed_13 <= b14_data_delayed_12;
	  b14_data_delayed_14 <= b14_data_delayed_13;
	  b15_data_delayed_2 <= b15_data_delayed_1;
	  b15_data_delayed_3 <= b15_data_delayed_2;
	  b15_data_delayed_4 <= b15_data_delayed_3;
	  b15_data_delayed_5 <= b15_data_delayed_4;
	  b15_data_delayed_6 <= b15_data_delayed_5;
	  b15_data_delayed_7 <= b15_data_delayed_6;
	  b15_data_delayed_8 <= b15_data_delayed_7;
	  b15_data_delayed_9 <= b15_data_delayed_8;
	  b15_data_delayed_10 <= b15_data_delayed_9;
	  b15_data_delayed_11 <= b15_data_delayed_10;
	  b15_data_delayed_12 <= b15_data_delayed_11;
	  b15_data_delayed_13 <= b15_data_delayed_12;
	  b15_data_delayed_14 <= b15_data_delayed_13;
	  b15_data_delayed_15 <= b15_data_delayed_14;
	 
	  end
	end
	endmodule
