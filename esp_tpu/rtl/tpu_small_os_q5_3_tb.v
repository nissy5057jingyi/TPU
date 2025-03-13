// TPU Q5.3 Testbench with Fixed Control Signals
`timescale 1ns / 1ps

// Redefining parameters for the testbench
`define DWIDTH 8
`define AWIDTH 10
`define DESIGN_SIZE 16
`define MAX_BITS_POOL 3
`define MASK_WIDTH 16
`define REG_DATAWIDTH 32
`define REG_ADDRWIDTH 8
`define ADDR_STRIDE_WIDTH 16

// Addressing
`define REG_ENABLES_ADDR      32'h0
`define REG_STDN_TPU_ADDR     32'h4
`define REG_MEAN_ADDR         32'h8
`define REG_INV_VAR_ADDR      32'hA
`define REG_MATRIX_A_ADDR     32'he
`define REG_MATRIX_B_ADDR     32'h12
`define REG_MATRIX_C_ADDR     32'h16
`define REG_VALID_MASK_A_ROWS_ADDR 32'h20
`define REG_VALID_MASK_A_COLS_ADDR 32'h54
`define REG_VALID_MASK_B_ROWS_ADDR 32'h5c
`define REG_VALID_MASK_B_COLS_ADDR 32'h58
`define REG_POOL_WINDOW_ADDR  32'h3E
`define REG_ACTIVATION_CSR_ADDR 32'h3A
`define REG_MATRIX_A_STRIDE_ADDR 32'h28
`define REG_MATRIX_B_STRIDE_ADDR 32'h32
`define REG_MATRIX_C_STRIDE_ADDR 32'h36
`define REG_ACCUM_ACTIONS_ADDR 32'h24

module tpu_q53_tb;

  // Inputs
  reg clk;
  reg clk_mem;
  reg reset;
  reg resetn;
  reg [`REG_ADDRWIDTH-1:0] PADDR;
  reg PWRITE;
  reg PSEL;
  reg PENABLE;
  reg [`REG_DATAWIDTH-1:0] PWDATA;
  reg [`AWIDTH-1:0] bram_addr_a_ext;
  reg [`DESIGN_SIZE*`DWIDTH-1:0] bram_wdata_a_ext;
  reg [`DESIGN_SIZE-1:0] bram_we_a_ext;
  reg [`AWIDTH-1:0] bram_addr_b_ext;
  reg [`DESIGN_SIZE*`DWIDTH-1:0] bram_wdata_b_ext;
  reg [`DESIGN_SIZE-1:0] bram_we_b_ext;

  // Outputs
  wire [`REG_DATAWIDTH-1:0] PRDATA;
  wire PREADY;
  wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_rdata_a_ext;
  wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_rdata_b_ext;

  // Function to convert float to Q5.3 format
  function [7:0] float_to_q5_3;
    input real float_num;
    real scaled;
    integer int_part;
    begin
      // Scale by 2^3 (8) to get the fixed-point representation
      scaled = float_num * 8.0;
      
      // Convert to integer (with rounding)
      int_part = $rtoi(scaled >= 0 ? scaled + 0.5 : scaled - 0.5);
      
      // Saturate if out of range
      if (int_part > 127) int_part = 127;       // Max positive (15.875)
      if (int_part < -128) int_part = -128;     // Min negative (-16.0)
      
      // Convert to 8-bit Q5.3
      float_to_q5_3 = int_part[7:0];
    end
  endfunction

  // Function to convert Q5.3 to float for display
  function real q5_3_to_float;
    input [7:0] q5_3_num;
    real float_result;
    begin
      // Convert from 2's complement to real, then divide by 2^3 (8)
      float_result = $signed(q5_3_num) / 8.0;
      q5_3_to_float = float_result;
    end
  endfunction

  // Instantiate the Unit Under Test (UUT)
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
    .PRDATA(PRDATA),
    .PREADY(PREADY),
    .bram_addr_a_ext(bram_addr_a_ext),
    .bram_rdata_a_ext(bram_rdata_a_ext),
    .bram_wdata_a_ext(bram_wdata_a_ext),
    .bram_we_a_ext(bram_we_a_ext),
    .bram_addr_b_ext(bram_addr_b_ext),
    .bram_rdata_b_ext(bram_rdata_b_ext),
    .bram_wdata_b_ext(bram_wdata_b_ext),
    .bram_we_b_ext(bram_we_b_ext)
  );

  // Clock generation with 10ns period (100MHz)
  initial begin
    clk = 0;
    clk_mem = 0;
    forever begin
      #5 clk = ~clk;
      #5 clk_mem = ~clk_mem;
    end
  end

  // APB Write function
  task apb_write;
    input [`REG_ADDRWIDTH-1:0] addr;
    input [`REG_DATAWIDTH-1:0] data;
    begin
      @(posedge clk);
      PADDR = addr;
      PWDATA = data;
      PWRITE = 1'b1;
      PSEL = 1'b1;
      @(posedge clk);
      PENABLE = 1'b1;
      @(posedge clk);
      while (!PREADY) @(posedge clk);
      PSEL = 1'b0;
      PENABLE = 1'b0;
    end
  endtask

  // APB Read function
  task apb_read;
    input [`REG_ADDRWIDTH-1:0] addr;
    output [`REG_DATAWIDTH-1:0] data;
    begin
      @(posedge clk);
      PADDR = addr;
      PWRITE = 1'b0;
      PSEL = 1'b1;
      @(posedge clk);
      PENABLE = 1'b1;
      @(posedge clk);
      while (!PREADY) @(posedge clk);
      data = PRDATA;
      PSEL = 1'b0;
      PENABLE = 1'b0;
    end
  endtask

  // BRAM Write function for a full row
  task bram_write_row;
    input is_matrix_a;
    input [`AWIDTH-1:0] addr;
    input [16*8-1:0] values; // Array of 16 Q5.3 values
    begin
      @(posedge clk_mem);
      
      if (is_matrix_a) begin
        bram_addr_a_ext = addr;
        bram_wdata_a_ext = values;
        bram_we_a_ext = {`DESIGN_SIZE{1'b1}};
      end else begin
        bram_addr_b_ext = addr;
        bram_wdata_b_ext = values;
        bram_we_b_ext = {`DESIGN_SIZE{1'b1}};
      end
      
      @(posedge clk_mem);
      
      // Reset write enable
      bram_we_a_ext = {`DESIGN_SIZE{1'b0}};
      bram_we_b_ext = {`DESIGN_SIZE{1'b0}};
    end
  endtask

  // BRAM Read function
  task bram_read;
    input is_matrix_a;
    input [`AWIDTH-1:0] addr;
    output [`DESIGN_SIZE*`DWIDTH-1:0] data;
    begin
      @(posedge clk_mem);
      
      if (is_matrix_a) begin
        bram_addr_a_ext = addr;
        bram_we_a_ext = {`DESIGN_SIZE{1'b0}};
      end else begin
        bram_addr_b_ext = addr;
        bram_we_b_ext = {`DESIGN_SIZE{1'b0}};
      end
      
      @(posedge clk_mem);
      @(posedge clk_mem); // Extra cycle for read data to be available
      
      if (is_matrix_a)
        data = bram_rdata_a_ext;
      else
        data = bram_rdata_b_ext;
    end
  endtask

  // Wait for TPU done
  task wait_for_tpu_done;
    reg [`REG_DATAWIDTH-1:0] status;
    begin
      status = 0;
      while (status[31] != 1'b1) begin
        apb_read(`REG_STDN_TPU_ADDR, status);
        #100; // Prevent infinite loop in simulation
      end
    end
  endtask

  // Test variables
  reg [`REG_DATAWIDTH-1:0] read_data;
  integer i;
  reg [16*8-1:0] row_data; // Row of Q5.3 values
  reg [`DESIGN_SIZE*`DWIDTH-1:0] read_row_data;
  
  // Main test
  initial begin
    // Initialize Inputs
    reset = 1;
    resetn = 0;
    PADDR = 0;
    PWRITE = 0;
    PSEL = 0;
    PENABLE = 0;
    PWDATA = 0;
    bram_addr_a_ext = 0;
    bram_wdata_a_ext = 0;
    bram_we_a_ext = 0;
    bram_addr_b_ext = 0;
    bram_wdata_b_ext = 0;
    bram_we_b_ext = 0;

    // Reset for a few cycles
    #100;
    reset = 0;
    resetn = 1;
    #100;

    $display("=== TPU Q5.3 Fixed-Point Support Testbench ===");

    // Test 1: Matrix multiplication with Q5.3 values
    $display("\n--- Test 1: Matrix Multiplication with Q5.3 Values ---");
    
    // Set validity masks - ensure all 16 elements are valid
    apb_write(`REG_VALID_MASK_A_ROWS_ADDR, 32'hFFFF);  // All rows valid
    apb_write(`REG_VALID_MASK_A_COLS_ADDR, 32'hFFFF);  // All columns valid
    apb_write(`REG_VALID_MASK_B_ROWS_ADDR, 32'hFFFF);  // All rows valid
    apb_write(`REG_VALID_MASK_B_COLS_ADDR, 32'hFFFF);  // All columns valid
    
    // Enable matrix multiplication only
    apb_write(`REG_ENABLES_ADDR, 32'h1);  // Enable MatMul
    
    // Set matrix addresses - ensure they're properly aligned
    apb_write(`REG_MATRIX_A_ADDR, 32'h0);  // Matrix A at address 0
    apb_write(`REG_MATRIX_B_ADDR, 32'h10); // Matrix B at address 16
    apb_write(`REG_MATRIX_C_ADDR, 32'h20); // Matrix C (result) at address 32
    
    // Set matrix strides - critical for proper data addressing
    apb_write(`REG_MATRIX_A_STRIDE_ADDR, 32'h1);  // Matrix A stride
    apb_write(`REG_MATRIX_B_STRIDE_ADDR, 32'h1);  // Matrix B stride
    apb_write(`REG_MATRIX_C_STRIDE_ADDR, 32'h1);  // Matrix C stride
    
    // Set accumulation control - ensure we're not using accumulation for this test
    apb_write(`REG_ACCUM_ACTIONS_ADDR, 32'h0);  // No accumulation actions
    
    // Create a simple input vector (activated inputs)
    $display("Writing Input Vector in Q5.3 format:");
    
    // Row of all 1.0 values for simplicity
    row_data = 0; // Initialize
    for (i = 0; i < 16; i = i + 1) begin
      row_data[i*8 +: 8] = float_to_q5_3(1.0); // All inputs = 1.0
      $display("A[%0d] = %f (Q5.3: 0x%h)", i, 1.0, float_to_q5_3(1.0));
    end
    
    // Write the input vector at address 0
    bram_write_row(1, 0, row_data);  // 1 for matrix A
    
    // Create weights (16 weights from 0.5 to 8.0 in increments of 0.5)
    $display("\nWriting Weight Vector in Q5.3 format:");
    
    row_data = 0; // Initialize
    for (i = 0; i < 16; i = i + 1) begin
      real weight_val;
      weight_val = 0.5 * (i + 1);  // 0.5, 1.0, 1.5, ..., 8.0
      row_data[i*8 +: 8] = float_to_q5_3(weight_val);
      $display("B[%0d] = %f (Q5.3: 0x%h)", i, weight_val, float_to_q5_3(weight_val));
    end
    
    // Write the weight vector at address 16
    bram_write_row(0, 16, row_data);  // 0 for matrix B
    
    // Make sure we have enough delay for memory writes to complete
    #100;
    
    // Start the TPU
    $display("\nStarting Matrix Multiplication...");
    apb_write(`REG_STDN_TPU_ADDR, 32'h1);
    
    // Wait for TPU to finish
    wait_for_tpu_done();
    $display("Matrix Multiplication Complete!");
    
    // Make sure we have enough delay for output to be ready
    #100;
    
    // Read result vector
    $display("\nReading Result Vector in Q5.3 format:");
    bram_read(1, 32, read_row_data);  // Reading from matrix C (stored in A's space)
    
    // Display the result
    for (i = 0; i < 16; i = i + 1) begin
      $display("C[%0d] = %f (Q5.3: 0x%h)", 
              i, 
              q5_3_to_float(read_row_data[i*8 +: 8]),
              read_row_data[i*8 +: 8]);
    end
    
    // Expected result for this multiplication would be:
    // Sum of all weights = 0.5 + 1.0 + 1.5 + ... + 8.0 = 68.0
    $display("\nExpected result should be around 68.0 (or may saturate to 15.875 in Q5.3)");
    
    // Reset TPU start and wait a bit
    apb_write(`REG_STDN_TPU_ADDR, 32'h0);
    #200;
    
    // Test 2: Matrix multiplication with ReLU activation
    $display("\n--- Test 2: Matrix Multiplication with ReLU Activation ---");
    
    // Enable matrix multiplication and activation
    apb_write(`REG_ENABLES_ADDR, 32'h9);  // Enable MatMul and Activation
    
    // Set activation type to ReLU (0)
    apb_write(`REG_ACTIVATION_CSR_ADDR, 32'h0);
    
    // Create an input vector with mixed positive and negative values
    $display("\nWriting Input Vector with mixed values in Q5.3 format:");
    
    row_data = 0; // Initialize
    for (i = 0; i < 16; i = i + 1) begin
      real input_val;
      // Alternate positive and negative values
      input_val = (i % 2 == 0) ? 1.0 : -1.0;
      row_data[i*8 +: 8] = float_to_q5_3(input_val);
      $display("A[%0d] = %f (Q5.3: 0x%h)", i, input_val, float_to_q5_3(input_val));
    end
    
    // Write the input vector
    bram_write_row(1, 0, row_data);
    
    // Use the same weights as before
    
    // Make sure we have enough delay for memory writes to complete
    #100;
    
    // Start the TPU
    $display("\nStarting Matrix Multiplication with ReLU...");
    apb_write(`REG_STDN_TPU_ADDR, 32'h1);
    
    // Wait for TPU to finish
    wait_for_tpu_done();
    $display("Computation Complete!");
    
    // Make sure we have enough delay for output to be ready
    #100;
    
    // Read result vector
    $display("\nReading Result Vector with ReLU applied in Q5.3 format:");
    bram_read(1, 32, read_row_data);
    
    // Display the result
    for (i = 0; i < 16; i = i + 1) begin
      $display("C[%0d] = %f (Q5.3: 0x%h)", 
              i, 
              q5_3_to_float(read_row_data[i*8 +: 8]),
              read_row_data[i*8 +: 8]);
    end
    
    // Reset TPU start and wait a bit
    apb_write(`REG_STDN_TPU_ADDR, 32'h0);
    #200;
    
    // Test 3: Matrix multiplication with Tanh activation
    $display("\n--- Test 3: Matrix Multiplication with Tanh Activation ---");
    
    // Enable matrix multiplication and activation
    apb_write(`REG_ENABLES_ADDR, 32'h9);  // Enable MatMul and Activation
    
    // Set activation type to Tanh (1)
    apb_write(`REG_ACTIVATION_CSR_ADDR, 32'h1);
    
    // Wait enough time for the enable to take effect
    #100;
    
    // Start the TPU (using the same input data)
    $display("\nStarting Matrix Multiplication with Tanh...");
    apb_write(`REG_STDN_TPU_ADDR, 32'h1);
    
    // Wait for TPU to finish
    wait_for_tpu_done();
    $display("Computation Complete!");
    
    // Make sure we have enough delay for output to be ready
    #100;
    
    // Read result vector
    $display("\nReading Result Vector with Tanh applied in Q5.3 format:");
    bram_read(1, 32, read_row_data);
    
    // Display the result
    for (i = 0; i < 16; i = i + 1) begin
      $display("C[%0d] = %f (Q5.3: 0x%h)", 
              i, 
              q5_3_to_float(read_row_data[i*8 +: 8]),
              read_row_data[i*8 +: 8]);
    end
    
    $display("\n=== Q5.3 Fixed-Point Support Tests Completed ===");
    
    // End simulation
    #1000;
    $finish;
  end

  // Monitor for errors/timeouts
  initial begin
    // Set timeout for simulation
    #1000000;
    $display("Simulation timeout!");
    $finish;
  end

endmodule