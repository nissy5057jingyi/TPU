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
`timescale 1ns / 1ps



module tb_top;

// Clock and reset signals
reg clk;
reg clk_mem;
reg reset;
reg resetn;

// APB Interface signals
reg [`REG_ADDRWIDTH-1:0] PADDR;
reg PWRITE;
reg PSEL;
reg PENABLE;
reg [`REG_DATAWIDTH-1:0] PWDATA;

// BRAM Interface signals
reg [`AWIDTH-1:0] bram_addr_a_ext;
reg [`DESIGN_SIZE*`DWIDTH-1:0] bram_wdata_a_ext;
reg [`DESIGN_SIZE-1:0] bram_we_a_ext;
reg [`AWIDTH-1:0] bram_addr_b_ext;
reg [`DESIGN_SIZE*`DWIDTH-1:0] bram_wdata_b_ext;
reg [`DESIGN_SIZE-1:0] bram_we_b_ext;

wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_rdata_b_ext;
wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_rdata_a_ext;
wire [`REG_DATAWIDTH-1:0] PRDATA;
wire PREADY;

integer i;
integer j;
integer n;
integer m;
integer file;
// Instantiate the top module
top uut (
    .clk(clk),
    .clk_mem(clk_mem),
    .reset(reset),
    .resetn(resetn),
    .PADDR(PADDR),
    .PWRITE(PWRITE),
    .PSEL(PSEL),
    .PENABLE(PENABLE),
    .PWDATA(PWDATA),
    .bram_addr_a_ext(bram_addr_a_ext),
    .bram_wdata_a_ext(bram_wdata_a_ext),
    .bram_we_a_ext(bram_we_a_ext),
    .bram_addr_b_ext(bram_addr_b_ext),
    .bram_wdata_b_ext(bram_wdata_b_ext),
    .bram_we_b_ext(bram_we_b_ext),
    .bram_rdata_b_ext(bram_rdata_b_ext),
    .bram_rdata_a_ext(bram_rdata_a_ext),
    .PRDATA(PRDATA),
    .PREADY(PREADY)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    clk_mem = 0;
    forever #5 clk_mem = ~clk_mem;
end

initial begin 
////////////////////////////////////////////////////////////////
//Reset
////////////////////////////////////////////////////////////////	
		clk = 0;
        clk_mem = 0;
        reset = 1;
        resetn = 0;
        #20;

////////////////////////////////////////////////////////////////
//Initial
////////////////////////////////////////////////////////////////
        reset = 0;
        resetn = 1;
		file = $fopen("TPU_OPRATION_REPORT.rpt", "w");

////////////////////////////////////////////////////////////////
// Title Print
////////////////////////////////////////////////////////////////
		$fwrite(file,"TPU start operation!\n");

////////////////////////////////////////////////////////////////
// Stage 1: SET MASK
////////////////////////////////////////////////////////////////
		$fwrite(file,"MASK SETTING...\n");
		@(posedge clk);
		PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
		PWDATA = 32'hffff_ffff;
		@(posedge clk);
		PADDR = `REG_VALID_MASK_A_ROWS_ADDR;
		@(posedge clk);
		PWDATA = 32'hffff_ffff;
		$fwrite(file,"MASK_A_ROWS SET TO : 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_VALID_MASK_A_COLS_ADDR;
		@(posedge clk);
		PWDATA = 32'hffff_ffff;
		$fwrite(file,"MASK_A_COLS SET TO : 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_VALID_MASK_B_ROWS_ADDR;
		@(posedge clk);
		PWDATA = 32'hffff_ffff;
		$fwrite(file,"MASK_B_ROWS SET TO : 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_VALID_MASK_B_COLS_ADDR;
		@(posedge clk);
		PWDATA = 32'hffff_ffff;
		$fwrite(file,"MASK_B_COLS SET TO : 32'h%08h\n",PWDATA);
		$fwrite(file,"MASK SETTING DONE\n");
		
////////////////////////////////////////////////////////////////
// Stage 2: SET MAT ADDRESS 
////////////////////////////////////////////////////////////////
		$fwrite(file,"MAT ADDRESS SETTING...\n");
		PWDATA = 32'h0000_0001;
		@(posedge clk);
		PADDR = `REG_MATRIX_A_ADDR;
		@(posedge clk);
		PWDATA = 32'h0000_0001;
		$fwrite(file,"MATRIX A MAT ADDRESS STRIDE SET TO 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_MATRIX_B_ADDR;
		@(posedge clk);
		PWDATA = 32'h0000_0001;
		$fwrite(file,"MATRIX B MAT ADDRESS STRIDE SET TO 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_MATRIX_C_ADDR;
		@(posedge clk);
		PWDATA = 32'h0000_0020;
		$fwrite(file,"MATRIX C MAT ADDRESS STRIDE SET TO 32'h%08h\n",PWDATA);
		$fwrite(file,"MAT ADDRESS SETTING DONE\n");
////////////////////////////////////////////////////////////////
// Stage 3: SET ADDRESS STRIDE
////////////////////////////////////////////////////////////////
		//set address stride by 1
		$fwrite(file,"ADDRESS STRIDE SETTING...\n");
		@(posedge clk);
		PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
		
		@(posedge clk);
		PADDR = `REG_MATRIX_A_STRIDE_ADDR;
		@(posedge clk);
		PWDATA = 32'h0000_0001;
		$fwrite(file,"MATRIX A ADDRESS STRIDE SET TO 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_MATRIX_B_STRIDE_ADDR;
		@(posedge clk);
		PWDATA = 32'h0000_0001;
		$fwrite(file,"MATRIX B ADDRESS STRIDE SET TO 32'h%08h\n",PWDATA);
		@(posedge clk);
		PADDR = `REG_MATRIX_C_STRIDE_ADDR;
		
		PWDATA = 32'h0000_0001;
		
		
		
		
		$fwrite(file,"MATRIX C ADDRESS STRIDE SET TO 32'h%08h\n",PWDATA);
		$fwrite(file,"ADDRESS STRIDE SETTING DONE\n");
		
////////////////////////////////////////////////////////////////
// Stage 4: WRITE DATA IN MATRIX A AND B 
////////////////////////////////////////////////////////////////
		$fwrite(file,"DATA WRITING TO MATRIX A AND B...\n");
		@(posedge clk);
        PADDR = `REG_ENABLES_ADDR;
        PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
        PWDATA = 32'b0;
		@(posedge clk);

		$fwrite(file, "INPUT PADDR: `REG_ENABLES_ADDR (32'h%08h)\n", `REG_ENABLES_ADDR);
		$fwrite(file, "INPUT PWRITE: %0d\n", PWRITE);
		$fwrite(file, "INPUT PSEL: %0d\n", PSEL);
		$fwrite(file, "INPUT PWDATA: %0b\n", PWDATA);

		//write external data into matrix A 
		bram_we_a_ext = {`DESIGN_SIZE{1'b1}};
		bram_we_b_ext = 0;
		bram_addr_a_ext = 1;
		//@(posedge clk);

		$fwrite(file,"input for matrix A is\n");
		for(i=0;i<=`DESIGN_SIZE;i = i+1)begin
			bram_wdata_a_ext = 0;
			@(posedge clk);
			for(j = 0; j<`DESIGN_SIZE;j=j+1)begin
				
				bram_wdata_a_ext[j*`DWIDTH +: `DWIDTH] = $urandom_range(0,9);
				
				$fwrite(file, "%d |", bram_wdata_a_ext[j*`DWIDTH +: `DWIDTH]);
			end
			$fwrite(file,"\n");
			@(posedge clk);
			if (bram_we_a_ext) begin
				bram_addr_a_ext = bram_addr_a_ext+1;
			end
			
		end
        
		//write external data into matrix B
		bram_we_a_ext = 0;
		bram_we_b_ext = {`DESIGN_SIZE{1'b1}};
		bram_addr_b_ext = 1;

		
		$fwrite(file,"input for matrix B is\n");

		for(n=0;n<=`DESIGN_SIZE;n = n+1)begin
			@(posedge clk);
			bram_wdata_b_ext = 0;
			
			for(m = 0; m<`DESIGN_SIZE;m=m+1)begin
				
				bram_wdata_b_ext[m*`DWIDTH +: `DWIDTH] = $urandom_range(0,9);
				
				$fwrite(file, "%d |", bram_wdata_b_ext[m*`DWIDTH +: `DWIDTH]);
			end
			$fwrite(file,"\n");
			@(posedge clk);
			if(bram_we_b_ext)begin
				bram_addr_b_ext = bram_addr_b_ext+1;
			end
		end
		$fwrite(file,"DATA WRITING TO MATRIX A AND B DONE\n");
////////////////////////////////////////////////////////////////
// Stage 5: START READING DATA From A and B
////////////////////////////////////////////////////////////////
		PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
		bram_we_a_ext = 0;
		bram_we_b_ext = 0;
		$fwrite(file,"DATA READING TO MATRIX A AND B ...\n");
		@(posedge clk);
		PADDR = `REG_ENABLES_ADDR;
		PWDATA = 32'h8000_0001;//sat_mult = 1, other enable = 0
		@(posedge clk);
        PADDR = `REG_STDN_TPU_ADDR;
		@(posedge clk);
        PWDATA = 32'h0000_0001;//start_tpu =1 pe_reset = 0
		@(negedge clk);
		$fwrite(file,"DATA READING TO MATRIX A AND B done\n");
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
		@(posedge clk);
////////////////////////////////////////////////////////////////
// Stage 6: set c matrix address
////////////////////////////////////////////////////////////////	
		@(posedge clk);
		PADDR = `REG_MATRIX_C_STRIDE_ADDR;
		@(posedge clk);
		PWDATA = 32'h0000_0001;
////////////////////////////////////////////////////////////////
// Stage 7: wait computation done
////////////////////////////////////////////////////////////////
		@(posedge clk);
		wait(uut.u_matmul.u_output_logic.row_latch_en == 1);
		PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
		PADDR = `REG_ENABLES_ADDR;
		PWDATA = 32'h0000_000f;//sat_mult = 1, other enable = 1

////////////////////////////////////////////////////////////////
// Stage 8:  star normalization
////////////////////////////////////////////////////////////////





		/*reset = 1;
        resetn = 0;
        #20;
		reset = 0;
        resetn = 1;
		$fwrite(file,"DATA WRITING TO MATRIX A AND B...\n");
		@(posedge clk);
        PADDR = `REG_ENABLES_ADDR;
        PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
        PWDATA = 32'b0;
		@(posedge clk);

		$fwrite(file, "INPUT PADDR: `REG_ENABLES_ADDR (32'h%08h)\n", `REG_ENABLES_ADDR);
		$fwrite(file, "INPUT PWRITE: %0d\n", PWRITE);
		$fwrite(file, "INPUT PSEL: %0d\n", PSEL);
		$fwrite(file, "INPUT PWDATA: %0b\n", PWDATA);

		//write external data into matrix A 
		bram_we_a_ext = {`DESIGN_SIZE{1'b1}};
		bram_we_b_ext = 0;
		bram_addr_a_ext = 0;
		//@(posedge clk);

		$fwrite(file,"input for matrix A is\n");
		for(i=0;i<=`DESIGN_SIZE;i = i+1)begin
			//bram_wdata_a_ext = 0;
			@(posedge clk);
			for(j = 0; j<`DESIGN_SIZE;j=j+1)begin
				
				bram_wdata_a_ext[j*`DWIDTH +: `DWIDTH] = ($random%19)-9;
				
				$fwrite(file, "%d |", bram_wdata_a_ext[j*`DWIDTH +: `DWIDTH]);
			end
			$fwrite(file,"\n");
			@(posedge clk);
			if (bram_we_a_ext) begin
				bram_addr_a_ext = bram_addr_a_ext+1;
			end
			
		end
        
		//write external data into matrix B
		bram_we_a_ext = 0;
		bram_we_b_ext = {`DESIGN_SIZE{1'b1}};
		bram_addr_b_ext = 0;

		
		$fwrite(file,"input for matrix B is\n");

		for(n=0;n<=`DESIGN_SIZE;n = n+1)begin
			@(posedge clk);
			bram_wdata_b_ext = 0;
			
			for(m = 0; m<`DESIGN_SIZE;m=m+1)begin
				
				bram_wdata_b_ext[m*`DWIDTH +: `DWIDTH] = ($random%19)-9;
				
				$fwrite(file, "%d |", bram_wdata_b_ext[m*`DWIDTH +: `DWIDTH]);
			end
			$fwrite(file,"\n");
			@(posedge clk);
			if(bram_we_b_ext)begin
				bram_addr_b_ext = bram_addr_b_ext+1;
			end
		end
		$fwrite(file,"DATA WRITING TO MATRIX A AND B DONE\n");
////////////////////////////////////////////////////////////////
// Stage 7: START READING DATA From A and B
////////////////////////////////////////////////////////////////
		PWRITE = 1;
        PSEL = 1;
        PENABLE = 1;
		bram_we_a_ext = 0;
		bram_we_b_ext = 0;
		$fwrite(file,"DATA READING TO MATRIX A AND B ...\n");
		@(posedge clk);
		PADDR = `REG_ENABLES_ADDR;
		PWDATA = 32'h8000_0001;//sat_mult = 1, other enable = 0
		@(posedge clk);
        PADDR = `REG_STDN_TPU_ADDR;
		@(posedge clk);
        PWDATA = 32'h0000_0001;//start_tpu =1 pe_reset = 0
		@(negedge clk);
		$fwrite(file,"DATA READING TO MATRIX A AND B done\n");*/
        #2000; // Delay to allow some operations
		$fclose(file);
        //$display("Test completed.");
        $finish;
end
endmodule

