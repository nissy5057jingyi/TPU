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



module cfg(
    input                             PCLK,
    input                             PRESETn,
    input        [`REG_ADDRWIDTH-1:0] PADDR,
    input                             PWRITE,
    input                             PSEL,
    input                             PENABLE,
    input        [`REG_DATAWIDTH-1:0] PWDATA,
	input                             done_tpu,
    output reg   [`REG_DATAWIDTH-1:0] PRDATA,
    output reg                        PREADY,
    output reg start_tpu,
    output reg enable_matmul,
    output reg enable_norm,
    output reg enable_pool,
    output reg enable_activation,
    output reg enable_conv_mode,
    output reg [`DWIDTH-1:0] mean,
    output reg [`DWIDTH-1:0] inv_var,
	output reg [`MAX_BITS_POOL-1:0] pool_window_size,
	output reg [`AWIDTH-1:0] address_mat_a,
    output reg [`AWIDTH-1:0] address_mat_b,
    output reg [`AWIDTH-1:0] address_mat_c,
    output reg [`MASK_WIDTH-1:0] validity_mask_a_rows,
    output reg [`MASK_WIDTH-1:0] validity_mask_a_cols,
    output reg [`MASK_WIDTH-1:0] validity_mask_b_rows,
    output reg [`MASK_WIDTH-1:0] validity_mask_b_cols,
    output reg save_output_to_accum,
    output reg add_accum_to_output,
    output reg [`ADDR_STRIDE_WIDTH-1:0] address_stride_a,
    output reg [`ADDR_STRIDE_WIDTH-1:0] address_stride_b,
    output reg [`ADDR_STRIDE_WIDTH-1:0] address_stride_c,
    output reg activation_type,
    output reg [3:0] conv_filter_height,
    output reg [3:0] conv_filter_width,
    output reg [3:0] conv_stride_horiz,
    output reg [3:0] conv_stride_verti,
    output reg [3:0] conv_padding_left,
    output reg [3:0] conv_padding_right,
    output reg [3:0] conv_padding_top,
    output reg [3:0] conv_padding_bottom,
    output reg [15:0] num_channels_inp,
    output reg [15:0] num_channels_out,
    output reg [15:0] inp_img_height,
    output reg [15:0] inp_img_width,
    output reg [15:0] out_img_height,
    output reg [15:0] out_img_width,
    output reg [31:0] batch_size,
    output reg pe_reset

);

//Dummy register to sync all other invalid/unimplemented addresses
reg [`REG_DATAWIDTH-1:0] reg_dummy;


//////////////////////////////////////////////////////
//Using a simple APB interface. Taken from:
// https://github.com/maomran/APB-Slave
// https://research.ijcaonline.org/volume95/number21/pxc3897047.pdf

reg [1:0] State;
`define IDLE     2'b00
`define W_ENABLE  2'b01
`define R_ENABLE  2'b10

always @(posedge PCLK) begin
  if (PRESETn == 0) begin
    State <= `IDLE;
    PRDATA <= 0;
    PREADY <= 0;
    start_tpu <= 0;
    enable_matmul <= 0;
    enable_norm <= 0;
    enable_pool <= 0;
    enable_activation <= 0;
    mean <= 0;
    inv_var <= 0;
    pool_window_size <= 1;
		reg_dummy <= 0;
    address_mat_a <= 0;
    address_mat_b <= 0;
    address_mat_c <= 0;
    validity_mask_a_rows <= {`MASK_WIDTH{1'b1}};
    validity_mask_a_cols <= {`MASK_WIDTH{1'b1}};
    validity_mask_b_rows <= {`MASK_WIDTH{1'b1}};
    validity_mask_b_cols <= {`MASK_WIDTH{1'b1}};
    save_output_to_accum <= 0;
    add_accum_to_output <= 0;
    address_stride_a <= `DESIGN_SIZE;
    address_stride_b <= `DESIGN_SIZE;
    address_stride_c <= `DESIGN_SIZE;
    activation_type <= 1;
    conv_filter_height <= 2;
    conv_filter_width  <= 2;
    conv_stride_horiz  <= 1;
    conv_stride_verti  <= 1;
    conv_padding_left  <= 0;
    conv_padding_right <= 0;
    conv_padding_top   <= 0;
    conv_padding_bottom <= 0;
    num_channels_inp <= 4;
    num_channels_out <= 4;
    inp_img_height   <= 8;
    inp_img_width    <= 8;
    out_img_height   <= 7;
    out_img_width    <= 7;
    batch_size       <= 2;
    enable_conv_mode <= 0;
    pe_reset <= 0;
  end

  else begin
    case (State)
      `IDLE : begin
        PRDATA <= 0;
        if (PSEL) begin
          if (PWRITE) begin
            State <= `W_ENABLE;
          end
          else begin
            State <= `R_ENABLE;
          end
        end
        PREADY <= 0;
        pe_reset <= 0; //this register bit auto resets itself
      end

      `W_ENABLE : begin
        if (PSEL && PWRITE && PENABLE) begin
          case (PADDR)
          `REG_ENABLES_ADDR   : begin 
                                enable_conv_mode  <= PWDATA[31];
                                enable_activation <= PWDATA[3];
                                enable_pool       <= PWDATA[2];
                                enable_norm       <= PWDATA[1];
                                enable_matmul     <= PWDATA[0];
                                end
          `REG_STDN_TPU_ADDR  : begin
                                start_tpu <= PWDATA[0];
                                pe_reset <= PWDATA[15]; 
                                end
          `REG_MEAN_ADDR      : mean <= PWDATA[`DWIDTH-1:0];
          `REG_INV_VAR_ADDR   : inv_var <= PWDATA[`DWIDTH-1:0];
          `REG_MATRIX_A_ADDR  : address_mat_a <= PWDATA[`AWIDTH-1:0];
          `REG_MATRIX_B_ADDR  : address_mat_b <= PWDATA[`AWIDTH-1:0];
          `REG_MATRIX_C_ADDR  : address_mat_c <= PWDATA[`AWIDTH-1:0];
          `REG_VALID_MASK_A_ROWS_ADDR: begin
                                validity_mask_a_rows <= PWDATA[`MASK_WIDTH-1:0];
                                end
          `REG_VALID_MASK_A_COLS_ADDR: begin
                                validity_mask_a_cols <= PWDATA[`MASK_WIDTH-1:0];
                                end
          `REG_VALID_MASK_B_ROWS_ADDR: begin
                                validity_mask_b_rows <= PWDATA[`MASK_WIDTH-1:0];
                                end
          `REG_VALID_MASK_B_COLS_ADDR: begin
                                validity_mask_b_cols <= PWDATA[`MASK_WIDTH-1:0];
                                end
          `REG_POOL_WINDOW_ADDR: pool_window_size <= PWDATA[`MAX_BITS_POOL-1:0];
		  `REG_ACCUM_ACTIONS_ADDR: begin
                                   add_accum_to_output <= PWDATA[1];
                                   save_output_to_accum <= PWDATA[0];
                                   end
          `REG_MATRIX_A_STRIDE_ADDR : address_stride_a <= PWDATA[`ADDR_STRIDE_WIDTH-1:0];
          `REG_MATRIX_B_STRIDE_ADDR : address_stride_b <= PWDATA[`ADDR_STRIDE_WIDTH-1:0];
          `REG_MATRIX_C_STRIDE_ADDR : address_stride_c <= PWDATA[`ADDR_STRIDE_WIDTH-1:0];
          `REG_ACTIVATION_CSR_ADDR  : activation_type  <= PWDATA[0];
          `REG_CONV_PARAMS_1_ADDR   : begin
                                      conv_filter_height <= PWDATA[3:0]; 
                                      conv_filter_width  <= PWDATA[7:4];
                                      conv_stride_horiz  <= PWDATA[11:8];
                                      conv_stride_verti  <= PWDATA[15:12];
                                      conv_padding_left  <= PWDATA[19:16];
                                      conv_padding_right <= PWDATA[23:20];
                                      conv_padding_top   <= PWDATA[27:24];
                                      conv_padding_bottom<= PWDATA[31:28];
                                      end
          `REG_CONV_PARAMS_2_ADDR   : begin
                                      num_channels_inp <= PWDATA[15:0];
                                      num_channels_out <= PWDATA[31:16];
                                      end
          `REG_CONV_PARAMS_3_ADDR   : begin
                                      inp_img_height   <= PWDATA[15:0];
                                      inp_img_width    <= PWDATA[31:16];
                                      end
          `REG_CONV_PARAMS_4_ADDR   : begin
                                      out_img_height   <= PWDATA[15:0];
                                      out_img_width    <= PWDATA[31:16];
                                      end
          `REG_BATCH_SIZE_ADDR      : batch_size <= PWDATA[31:0];
          default: reg_dummy <= PWDATA; //sink writes to a dummy register
          endcase
          PREADY <=1;          
        end
        State <= `IDLE;
      end

      `R_ENABLE : begin
        if (PSEL && !PWRITE && PENABLE) begin
          PREADY <= 1;
          case (PADDR)
          `REG_ENABLES_ADDR   : PRDATA <= {28'b0, enable_activation, enable_pool, enable_norm, enable_matmul};
          `REG_STDN_TPU_ADDR  : PRDATA <= {done_tpu, 30'b0, start_tpu};
          `REG_MEAN_ADDR      : PRDATA <= mean;
          `REG_INV_VAR_ADDR   : PRDATA <= inv_var;
          `REG_MATRIX_A_ADDR  : PRDATA <= address_mat_a;
          `REG_MATRIX_B_ADDR  : PRDATA <= address_mat_b;
          `REG_MATRIX_C_ADDR  : PRDATA <= address_mat_c;
          `REG_VALID_MASK_A_ROWS_ADDR: PRDATA <= validity_mask_a_rows;
          `REG_VALID_MASK_A_COLS_ADDR: PRDATA <= validity_mask_a_cols;
          `REG_VALID_MASK_B_ROWS_ADDR: PRDATA <= validity_mask_b_rows;
          `REG_VALID_MASK_B_COLS_ADDR: PRDATA <= validity_mask_b_cols;
          `REG_POOL_WINDOW_ADDR : PRDATA <= pool_window_size;
		  `REG_ACCUM_ACTIONS_ADDR: PRDATA <= {30'b0, add_accum_to_output, save_output_to_accum};
          `REG_MATRIX_A_STRIDE_ADDR : PRDATA <= address_stride_a;
          `REG_MATRIX_B_STRIDE_ADDR : PRDATA <= address_stride_b;
          `REG_MATRIX_C_STRIDE_ADDR : PRDATA <= address_stride_c;
          `REG_ACTIVATION_CSR_ADDR  : PRDATA <= {31'b0, activation_type};
          `REG_CONV_PARAMS_1_ADDR   : PRDATA <= {
                                      conv_filter_height,
                                      conv_filter_width,  
                                      conv_stride_horiz, 
                                      conv_stride_verti,  
                                      conv_padding_left,  
                                      conv_padding_right, 
                                      conv_padding_top,   
                                      conv_padding_bottom
                                      };
          `REG_CONV_PARAMS_2_ADDR   : PRDATA <= {
                                      num_channels_inp,
                                      num_channels_out
                                      };
          `REG_CONV_PARAMS_3_ADDR   : PRDATA <= {
                                      inp_img_height,
                                      inp_img_width 
                                      };
          `REG_CONV_PARAMS_4_ADDR   : PRDATA <= {
                                      out_img_height,
                                      out_img_width
                                      };
          `REG_BATCH_SIZE_ADDR      : PRDATA <= batch_size;
          default             : PRDATA <= reg_dummy; //read the dummy register for undefined addresses
          endcase
        end
        State <= `IDLE;
      end
      default: begin
        State <= `IDLE;
      end
    endcase
  end
end 

endmodule