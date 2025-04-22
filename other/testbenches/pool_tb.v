`timescale 1ns / 1ps

// Define module parameters
`define DWIDTH 16       // Using 16-bit width for Q8.8 fixed-point
`define DESIGN_SIZE 16  // As defined in the original code
`define MAX_BITS_POOL 3 // As defined in the original code
`define MASK_WIDTH 16   // As defined in the original code

module tb_pool;
  // Inputs
  reg clk;
  reg reset;
  reg enable_pool;
  reg in_data_available;
  reg [`MAX_BITS_POOL-1:0] pool_window_size;
  reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data;
  reg [`MASK_WIDTH-1:0] validity_mask;
  
  // Outputs
  wire [`DESIGN_SIZE*`DWIDTH-1:0] out_data;
  wire out_data_available;
  wire done_pool;
  
  // Variables for iteration
  integer i;
  reg [`DWIDTH-1:0] expected_val;
  reg signed [`DWIDTH:0] sum2; // Extra bit for sum to avoid overflow
  reg signed [`DWIDTH:0] sum4; // Extra bit for sum to avoid overflow
  
  // Helper function to print Q8.8 numbers
  function void print_q8_8;
    input [`DWIDTH-1:0] value;
    begin
      if (value[`DWIDTH-1]) // Check sign bit
        $write("-");
      else
        $write("+");
        
      $write("%d.%03d", 
        value[`DWIDTH-2:8],                    // Integer part (7 bits)
        (value[7:0] * 1000) / 256);           // Fractional part converted to decimal
    end
  endfunction
  
  // Helper function to generate Q8.8 fixed-point number
  function [`DWIDTH-1:0] q8_8;
    input integer int_part;
    input integer frac_part; // 0-255 representing 0-0.996
    reg [`DWIDTH-1:0] result;
    begin
      if (int_part < 0 || (int_part == 0 && frac_part < 0)) begin
        result = (((~((-int_part) << 8)) + 1) & 16'h7F00) | (((~(-frac_part)) + 1) & 16'h00FF);
        result = result | 16'h8000; // Set sign bit
      end
      else begin
        result = ((int_part & 16'h7F) << 8) | (frac_part & 16'hFF);
      end
      q8_8 = result;
    end
  endfunction
  
  // Instantiate the Unit Under Test (UUT)
  pool uut (
    .clk(clk),
    .reset(reset),
    .enable_pool(enable_pool),
    .in_data_available(in_data_available),
    .pool_window_size(pool_window_size),
    .inp_data(inp_data),
    .out_data(out_data),
    .out_data_available(out_data_available),
    .validity_mask(validity_mask),
    .done_pool(done_pool)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
  end
  
  // Task to show debug info
  task show_debug_info;
    begin
      $display("Debug: enable_pool=%b, in_data_available=%b, pool_window_size=%d", 
               enable_pool, in_data_available, pool_window_size);
      $display("Debug: out_data_available=%b, done_pool=%b", 
               out_data_available, done_pool);
    end
  endtask
  
  // Task to run a single test
  task run_test;
    input [128*8-1:0] test_name;  // Allow for long test name string
    input [`MAX_BITS_POOL-1:0] window_size;
    input enable;
    begin
      // Print test header
      $display("\n======= %0s =======", test_name);
      
      // Configure the test parameters
      enable_pool = enable;
      pool_window_size = window_size;
      
      // Reset the module
      reset = 1;
      in_data_available = 0;
      #20;
      reset = 0;
      #10;
      
      // Apply input data and wait for processing
      in_data_available = 1;
      #20;  // Give time for the module to register the input data
      
      // Keep data available for entire processing time
      #200;
      
      // Check signals
      show_debug_info();
      
      // End data input
      in_data_available = 0;
      #50;
      
      // Output data information
      $display("Input data:");
      for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        $write("Element %d: %h (", i, inp_data[i*`DWIDTH +: `DWIDTH]);
        print_q8_8(inp_data[i*`DWIDTH +: `DWIDTH]);
        $display(")");
      end
      
      if (enable && window_size == 1) begin
        $display("\nOutput data (should be the same as input since window_size = 1):");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
          $write("Element %d: %h (", i, out_data[i*`DWIDTH +: `DWIDTH]);
          print_q8_8(out_data[i*`DWIDTH +: `DWIDTH]);
          $display(")");
        end
      end
      else if (enable && window_size == 2) begin
        $display("\nOutput data (after 2x2 pooling, should have half as many elements):");
        for(i = 0; i < `DESIGN_SIZE/2; i = i + 1) begin
          $write("Element %d: %h (", i, out_data[i*`DWIDTH +: `DWIDTH]);
          print_q8_8(out_data[i*`DWIDTH +: `DWIDTH]);
          $display(") - Average of inputs %d and %d", i*2, i*2+1);
          
          // Compute expected value for verification using signed arithmetic
          sum2 = $signed(inp_data[(i*2)*`DWIDTH +: `DWIDTH]) + 
                 $signed(inp_data[(i*2+1)*`DWIDTH +: `DWIDTH]);
          expected_val = sum2 >>> 1; // Arithmetic right shift
          
          $write("  Expected: %h (", expected_val);
          print_q8_8(expected_val);
          $display(")");
        end
      end
      else if (enable && window_size == 4) begin
        $display("\nOutput data (after 4x4 pooling, should have quarter as many elements):");
        for(i = 0; i < `DESIGN_SIZE/4; i = i + 1) begin
          $write("Element %d: %h (", i, out_data[i*`DWIDTH +: `DWIDTH]);
          print_q8_8(out_data[i*`DWIDTH +: `DWIDTH]);
          $display(") - Average of inputs %d, %d, %d, and %d", i*4, i*4+1, i*4+2, i*4+3);
          
          // Compute expected value for verification using signed arithmetic
          sum4 = $signed(inp_data[(i*4)*`DWIDTH +: `DWIDTH]) + 
                 $signed(inp_data[(i*4+1)*`DWIDTH +: `DWIDTH]) + 
                 $signed(inp_data[(i*4+2)*`DWIDTH +: `DWIDTH]) + 
                 $signed(inp_data[(i*4+3)*`DWIDTH +: `DWIDTH]);
          expected_val = sum4 >>> 2; // Arithmetic right shift
          
          $write("  Expected: %h (", expected_val);
          print_q8_8(expected_val);
          $display(")");
        end
      end
      else if (!enable) begin
        $display("\nOutput data (should be same as input since enable_pool = 0):");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
          $write("Element %d: %h (", i, out_data[i*`DWIDTH +: `DWIDTH]);
          print_q8_8(out_data[i*`DWIDTH +: `DWIDTH]);
          $display(")");
        end
      end
    end
  endtask
  
  // Test sequence
  initial begin
    // Initialize inputs
    reset = 1;
    enable_pool = 0;
    in_data_available = 0;
    pool_window_size = 1;
    inp_data = 0;
    validity_mask = {`MASK_WIDTH{1'b1}}; // All elements valid
    
    // Reset phase
    #20;
    reset = 0;
    #10;
    
    // Test Case 1: Basic functionality check with pool_window_size = 1 (no pooling)
    // Set input data with interesting Q8.8 fixed-point values
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
      inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(i, i*16); // Values like 0.0, 1.0625, 2.125, etc.
    end
    run_test("Test Case 1: No Pooling (window size = 1)", 1, 1);
    
    // Test Case 2: Pooling with window size = 2
    // Set input data with Q8.8 values that will demonstrate averaging
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
      // Create a pattern where adjacent elements have values that average nicely
      if (i % 2 == 0)
        inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(i/2, 0);     // Even indices: 0.0, 1.0, 2.0, etc.
      else
        inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(i/2, 128);   // Odd indices: 0.5, 1.5, 2.5, etc.
    end
    run_test("Test Case 2: Pooling with window size = 2", 2, 1);
    
    // Test Case 3: Pooling with window size = 4
    // Set input data with Q8.8 values that will demonstrate 4x4 pooling
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
      inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(i/4, (i%4)*64); // Creates groups of 4 with increasing values
    end
    run_test("Test Case 3: Pooling with window size = 4", 4, 1);
    
    // Test Case 4: Testing enable_pool = 0 (bypass mode)
    // Set input data
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
      inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(i, 0); // Simple values 0.0, 1.0, 2.0, etc.
    end
    run_test("Test Case 4: Testing bypass mode (enable_pool = 0)", 2, 0);
    
    // Test Case 5: Testing with negative values
    // Set input data with negative Q8.8 values
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
      if(i % 2 == 0)
        inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(-((i/2)+1), 0);    // Even indices: -1.0, -2.0, etc.
      else
        inp_data[i*`DWIDTH +: `DWIDTH] = q8_8(-((i/2)+1), 128);  // Odd indices: -0.5, -1.5, etc.
    end
    run_test("Test Case 5: Testing with negative values", 2, 1);
    
    // End simulation
    #100;
    $finish;
  end
endmodule