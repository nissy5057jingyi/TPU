`timescale 1ns / 1ps

///////////////////////////////////
// Overview
///////////////////////////////////
//This design is based on the architecture from Google's TPU v1 [1]. At its heart, 
//it uses a 16x16 matrix multiplication unit, instead of a 256x256 matrix multiplication 
//unit used by the TPU. The design uses int8 precision. This systolic matrix multiplication
//unit is a output stationary unit, compared to weight stationary architecture used in the TPU.
//The activations are stored in RAM block A, whereas the weights are stored in RAM block B. 
//Control and configuration are done through an APB interface, instead of a PCIe interface on 
//the TPU. The normalization block applies the mean and variance values to the output of the 
//matrix multiplication unit. Pooling unit supports 3 pooling windows - 1x1, 2x2 and 4x4. 
//The activation unit supports two activation functions - rectified linear unit (ReLU) and 
//the hyperbolic tangent (TanH). The activation unit is the last unit before the results 
//are written back to RAM block A, from where they can be read again into the matrix 
//multiplication unit for the next layer.
//
//[1] Jouppi et. al., In-Datacenter Performance Analysis of a Tensor Processing Unit, ISCA 2017

//////////////////////////////////////
// Module hierarchy
//////////////////////////////////////
// top                                      (the top level design)
//   |--- ram                   matrix_A    (the RAM that stores matrix A (activations))
//   |--- ram                   matrix_B    (the RAM that stores matrix B (weights))
//   |--- control               u_control   (the state machine that controls the operation)
//   |--- cfg                   u_cfg       (unit to configure/observe registers using an APB interface)
//   |--- matmul_16x16_systolic u_matmul    (systolic 16x16 matrix multiplication unit)
//   |    |--- output_logic                 (contains logic to shift out the outputs of matmul)
//   |    |--- systolic_data_setup          (contains logic to shift in the inputs of the matmul)
//   |    |--- systolic_pe_matrix           (16x16 matrix of processing elements)
//   |         |--- processing_element      (one processing element)
//   |              |--- seq_mac            (mac block inside each processing element)
//   |                   |--- qmult         (multiplier inside each mac)
//   |                   |--- qadd          (adder inside each mac)
//   |--- norm                  u_norm      (normalization block; applies mean and variance)
//   |--- pool                  u_pool      (block that performs pooling)
//   |--- activation            u_activation(block that applies activation - relu or tanh)

//////////////////////////////////////
// Tested architectures
//////////////////////////////////////
// This design has been tested with:
// 1. The VTR flagship 40nm architecture. Example: arch/timing/k6_frac_N10_frac_chain_mem32K_40nm.xml
//    Properties of this design on this architecture:
//      Critical path delay: 8.32 ns               
//      Clock frequency: 120.19 MHz
//      Critical path: Includes the multiplier in the MAC in a PE and inter-CLB routing
//      Logic area (used): 1.97532e+08 MWTAs
//      Resource usage: 1556 LBs, 8 RAMs, 276 Multipliers
//      Runtime (on Intel Xeon E5-2430 2.5GHz with single thread): 3200 sec
// 2. 22nm architectures generated from COFFE. Example: arch/COFFE_22nm/stratix10_arch.xml
//    Properties of this design on this architecture:
//      Critical path delay: 9.24 ns             
//      Clock frequency: 108.17 MHz
//      Critical path: Includes the multiplier in the MAC in a PE and inter-CLB routing
//      Logic area (used): 4.95598e+07 MWTAs
//      Resource usage: 1477 LBs, 14 RAMs, 280 Multipliers
//      Runtime (on Intel Xeon E5-2430 2.5GHz with single thread): 3400 sec
// 3. 22nm architectures generated from COFFE. Example: arch/COFFE_22nm/k6n10LB_mem20K_complexDSP_customSB_22nm*

//////////////////////////////////////
// Parameters
//////////////////////////////////////

//The width of the data. This design uses int8 precision. So, DWIDTH is 8
//To change to a floating point 16 version, change this to 16 and also
//change the datapath components (like adder and multiplier) to be floating point. 
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

/////////////////////////////////////
// Matrix multiplication unit
////////////////////////////////////
module activation(
    input activation_type, // 选择激活函数类型，1'b1 表示 tanH，1'b0 表示 ReLU
    input enable_activation, // 启用激活模块
    input in_data_available, // 输入数据有效信号
    input [`DESIGN_SIZE*`DWIDTH-1:0] inp_data, // 输入数据 transform 16 data at one clock cycle
    output [`DESIGN_SIZE*`DWIDTH-1:0] out_data, // 输出数据
    output out_data_available, // 输出数据有效信号
    input [`MASK_WIDTH-1:0] validity_mask, // 有效性掩码（当前未使用，仅为占位）
    output done_activation, // 激活完成信号
    input clk, // 时钟信号
    input reset // 复位信号
);
// 内部寄存器和信号声明
reg  done_activation_internal;// internal flag to track whether computation is done ---done_activation
reg  out_data_available_internal;
wire [`DESIGN_SIZE*`DWIDTH-1:0] out_data_internal;
reg [`DESIGN_SIZE*`DWIDTH-1:0] slope_applied_data_internal;//store the A*x in tanH 
reg [`DESIGN_SIZE*`DWIDTH-1:0] intercept_applied_data_internal;//store B in tanH
reg [`DESIGN_SIZE*`DWIDTH-1:0] relu_applied_data_internal;// store computation result in relu
reg [31:0] i;//go through data point
reg [31:0] cycle_count;// time cycle
reg activation_in_progress;//indicate whether the activation is processing

reg [(`DESIGN_SIZE*4)-1:0] address;// 查找表(LUT)地址, 4bits design size：number of data
reg [(`DESIGN_SIZE*8)-1:0] data_slope;// tanH 斜率系数
reg [(`DESIGN_SIZE*8)-1:0] data_slope_flopped;// store the previous cycle data_slope value, LUT has delay
reg [(`DESIGN_SIZE*8)-1:0] data_intercept;// tanH 截距系数
reg [(`DESIGN_SIZE*8)-1:0] data_intercept_delayed;//1 cycle data_intercept
reg [(`DESIGN_SIZE*8)-1:0] data_intercept_flopped;//2 cycle data intercept

reg in_data_available_flopped;
reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data_flopped;
// 将输入数据寄存，提高时序稳定性
always @(posedge clk) begin
  if (reset) begin
    inp_data_flopped <= 0;
    data_slope_flopped <= 0;
  end else begin
    inp_data_flopped <= inp_data;
    data_slope_flopped <= data_slope;
  end
end

// 如果未启用激活模块，直接输出输入数据
// If the activation block is not enabled, just forward the input data
//if enabld output the internal value
assign out_data             = enable_activation ? out_data_internal : inp_data_flopped;
assign done_activation      = enable_activation ? done_activation_internal : 1'b1;
assign out_data_available   = enable_activation ? out_data_available_internal : in_data_available_flopped;

//activation process
//used RELU or tanH for data processing


always @(posedge clk) begin
   if (reset || ~enable_activation) begin
	  //reset all state 
      slope_applied_data_internal     <= 0;
      intercept_applied_data_internal <= 0; 
      relu_applied_data_internal      <= 0; 
      data_intercept_delayed      <= 0;
      data_intercept_flopped      <= 0;
      done_activation_internal    <= 0;
      out_data_available_internal <= 0;
      cycle_count                 <= 0;
      activation_in_progress      <= 0;
      in_data_available_flopped <= in_data_available;
   end else if(in_data_available || activation_in_progress) begin
      cycle_count <= cycle_count + 1;

      for (i = 0; i < `DESIGN_SIZE; i=i+1) begin
         if(activation_type==1'b1) begin // tanH computation
            slope_applied_data_internal[i*`DWIDTH +:`DWIDTH] <= data_slope_flopped[i*8 +: 8] * inp_data_flopped[i*`DWIDTH +:`DWIDTH];//A*X calculation
            data_intercept_flopped[i*8 +: 8] <= data_intercept[i*8 +: 8];
            data_intercept_delayed[i*8 +: 8] <= data_intercept_flopped[i*8 +: 8];
            intercept_applied_data_internal[i*`DWIDTH +:`DWIDTH] <= slope_applied_data_internal[i*`DWIDTH +:`DWIDTH] + data_intercept_delayed[i*8 +: 8];
         end else begin // ReLU computation
            relu_applied_data_internal[i*`DWIDTH +:`DWIDTH] <= inp_data[i*`DWIDTH] ? {`DWIDTH{1'b0}} : inp_data[i*`DWIDTH +:`DWIDTH];
         end
      end   

	  //valid output 
      //TANH needs 1 extra cycle
      if (activation_type==1'b1) begin
         if (cycle_count==3) begin
            out_data_available_internal <= 1;
         end
      end else begin
         if (cycle_count==2) begin
           out_data_available_internal <= 1;
         end
      end

      //TANH needs 1 extra cycle
      if (activation_type==1'b1) begin
        if(cycle_count==(`DESIGN_SIZE+2)) begin
           done_activation_internal <= 1'b1;
           activation_in_progress <= 0;
        end
        else begin
           activation_in_progress <= 1;
        end
      end else begin//Relu
        if(cycle_count==(`DESIGN_SIZE+1)) begin
           done_activation_internal <= 1'b1;
           activation_in_progress <= 0;
        end
        else begin
           activation_in_progress <= 1;
        end
      end
   end
   else begin
      slope_applied_data_internal     <= 0;
      intercept_applied_data_internal <= 0; 
      relu_applied_data_internal      <= 0; 
      data_intercept_delayed      <= 0;
      data_intercept_flopped      <= 0;
      done_activation_internal    <= 0;
      out_data_available_internal <= 0;
      cycle_count                 <= 0;
      activation_in_progress      <= 0;
   end
end

assign out_data_internal = (activation_type) ? intercept_applied_data_internal : relu_applied_data_internal;

//Our equation of tanh is Y=AX+B
//A is the slope and B is the intercept.
//We store A in one LUT and B in another.
//LUT for the slope
always @(address) begin
    for (i = 0; i < `DESIGN_SIZE; i=i+1) begin
    case (address[i*4+:4])
      4'b0000: data_slope[i*8+:8] = 8'd0;
      4'b0001: data_slope[i*8+:8] = 8'd0;
      4'b0010: data_slope[i*8+:8] = 8'd2;
      4'b0011: data_slope[i*8+:8] = 8'd3;
      4'b0100: data_slope[i*8+:8] = 8'd4;
      4'b0101: data_slope[i*8+:8] = 8'd0;
      4'b0110: data_slope[i*8+:8] = 8'd4;
      4'b0111: data_slope[i*8+:8] = 8'd3;
      4'b1000: data_slope[i*8+:8] = 8'd2;
      4'b1001: data_slope[i*8+:8] = 8'd0;
      4'b1010: data_slope[i*8+:8] = 8'd0;
      default: data_slope[i*8+:8] = 8'd0;
    endcase  
    end
end

//LUT for the intercept
always @(address) begin
    for (i = 0; i < `DESIGN_SIZE; i=i+1) begin
    case (address[i*4+:4])
      4'b0000: data_intercept[i*8+:8] = 8'd127;
      4'b0001: data_intercept[i*8+:8] = 8'd99;
      4'b0010: data_intercept[i*8+:8] = 8'd46;
      4'b0011: data_intercept[i*8+:8] = 8'd18;
      4'b0100: data_intercept[i*8+:8] = 8'd0;
      4'b0101: data_intercept[i*8+:8] = 8'd0;
      4'b0110: data_intercept[i*8+:8] = 8'd0;
      4'b0111: data_intercept[i*8+:8] = -8'd18;
      4'b1000: data_intercept[i*8+:8] = -8'd46;
      4'b1001: data_intercept[i*8+:8] = -8'd99;
      4'b1010: data_intercept[i*8+:8] = -8'd127;
      default: data_intercept[i*8+:8] = 8'd0;
    endcase  
    end
end

//Logic to find address // 
always @(inp_data) begin
    for (i = 0; i < `DESIGN_SIZE; i=i+1) begin
        if((inp_data[i*`DWIDTH +:`DWIDTH])>=90) begin
           address[i*4+:4] = 4'b0000;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>=39 && (inp_data[i*`DWIDTH +:`DWIDTH])<90) begin
           address[i*4+:4] = 4'b0001;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>=28 && (inp_data[i*`DWIDTH +:`DWIDTH])<39) begin
           address[i*4+:4] = 4'b0010;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>=16 && (inp_data[i*`DWIDTH +:`DWIDTH])<28) begin
           address[i*4+:4] = 4'b0011;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>=1 && (inp_data[i*`DWIDTH +:`DWIDTH])<16) begin
           address[i*4+:4] = 4'b0100;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])==0) begin
           address[i*4+:4] = 4'b0101;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>-16 && (inp_data[i*`DWIDTH +:`DWIDTH])<=-1) begin
           address[i*4+:4] = 4'b0110;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>-28 && (inp_data[i*`DWIDTH +:`DWIDTH])<=-16) begin
           address[i*4+:4] = 4'b0111;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>-39 && (inp_data[i*`DWIDTH +:`DWIDTH])<=-28) begin
           address[i*4+:4] = 4'b1000;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])>-90 && (inp_data[i*`DWIDTH +:`DWIDTH])<=-39) begin
           address[i*4+:4] = 4'b1001;
        end
        else if ((inp_data[i*`DWIDTH +:`DWIDTH])<=-90) begin
           address[i*4+:4] = 4'b1010;
        end
        else begin
           address[i*4+:4] = 4'b0101;
        end
    end
end

//Adding a dummy signal to use validity_mask input, to make ODIN happy
//TODO: Need to correctly use validity_mask
wire [`MASK_WIDTH-1:0] dummy;
assign dummy = validity_mask;

endmodule
