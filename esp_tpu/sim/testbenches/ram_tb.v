`timescale 1ns / 1ps

module tb_ram;
  // Parameters
  parameter AWIDTH = 10;
  parameter DWIDTH = 8;   // Changed from 16 to 8 for Q5.3 fixed-point
  parameter DESIGN_SIZE = 16;
  
  // Inputs
  reg clk;
  reg [AWIDTH-1:0] addr0;
  reg [DESIGN_SIZE*DWIDTH-1:0] d0;
  reg [DESIGN_SIZE-1:0] we0;
  reg [AWIDTH-1:0] addr1;
  reg [DESIGN_SIZE*DWIDTH-1:0] d1;
  reg [DESIGN_SIZE-1:0] we1;
  
  // Outputs
  wire [DESIGN_SIZE*DWIDTH-1:0] q0;
  wire [DESIGN_SIZE*DWIDTH-1:0] q1;
  
  // Helper function to print Q5.3 numbers
  function automatic void print_q5_3;
    input [DWIDTH-1:0] value;
    begin
      if (value[DWIDTH-1]) // Check sign bit
        $write("-");
      else
        $write("+");
        
      $write("%d.%02d", 
        value[DWIDTH-2:3],                     // Integer part (4 bits)
        (value[2:0] * 100) / 8);              // Fractional part converted to decimal (3 bits)
    end
  endfunction
  
  // Instantiate the Unit Under Test (UUT)
  ram uut (
    .addr0(addr0),
    .d0(d0),
    .we0(we0),
    .q0(q0),
    .addr1(addr1),
    .d1(d1),
    .we1(we1),
    .q1(q1),
    .clk(clk)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
  end
  
  // Test sequence
  initial begin
    // Initialize inputs
    addr0 = 0;
    d0 = 0;
    we0 = 0;
    addr1 = 0;
    d1 = 0;
    we1 = 0;
    
    // Wait for global reset
    #100;
    
    // Test case 1: Write to all elements through port 0
    $display("Test case 1: Write to all elements through port 0");
    addr0 = 10'h5;
    for (integer i = 0; i < DESIGN_SIZE; i = i + 1) begin
      // Create different Q5.3 values for each element: 0.5, 1.0, 1.5, etc.
      d0[i*DWIDTH +: DWIDTH] = 8'h04 + (i * 8'h04); // 0.5 + i*0.5 in Q5.3
    end
    we0 = {DESIGN_SIZE{1'b1}}; // Enable write for all elements
    #10;
    we0 = 0;
    #10;
    $write("Address: %h, First element written: %h (", addr0, d0[DWIDTH-1:0]);
    print_q5_3(d0[DWIDTH-1:0]);
    $write("), First element read: %h (", q0[DWIDTH-1:0]);
    print_q5_3(q0[DWIDTH-1:0]);
    $display(")");
    
    // Test case 2: Read from all elements through port 1 (same address)
    $display("\nTest case 2: Read from all elements through port 1 (same address)");
    addr1 = 10'h5;
    #10;
    for (integer i = 0; i < DESIGN_SIZE; i = i + 1) begin
      $write("Element %d: Written data: %h (", i, d0[i*DWIDTH +: DWIDTH]);
      print_q5_3(d0[i*DWIDTH +: DWIDTH]);
      $write("), Read data: %h (", q1[i*DWIDTH +: DWIDTH]);
      print_q5_3(q1[i*DWIDTH +: DWIDTH]);
      $display(")");
    end
    
    // Test case 3: Write to a subset of elements through port 1
    $display("\nTest case 3: Write to a subset of elements through port 1");
    addr1 = 10'hA;
    for (integer i = 0; i < DESIGN_SIZE; i = i + 1) begin
      // Create negative Q5.3 values: -0.5, -1.0, -1.5, etc.
      d1[i*DWIDTH +: DWIDTH] = 8'hFC - (i * 8'h04); // -0.5 - i*0.5 in Q5.3
    end
    we1 = 16'h00FF; // Enable write for lower 8 elements only
    #10;
    we1 = 0;
    #10;
    $write("Address: %h, First element written: %h (", addr1, d1[DWIDTH-1:0]);
    print_q5_3(d1[DWIDTH-1:0]);
    $write("), First element read: %h (", q1[DWIDTH-1:0]);
    print_q5_3(q1[DWIDTH-1:0]);
    $display(")");
    
    // Test case 4: Read all elements from both ports (different addresses)
    $display("\nTest case 4: Read all elements from both ports (different addresses)");
    addr0 = 10'h5;
    addr1 = 10'hA;
    #10;
    $display("Port 0 (Address %h):", addr0);
    for (integer i = 0; i < DESIGN_SIZE; i = i + 1) begin
      $write("Element %d: %h (", i, q0[i*DWIDTH +: DWIDTH]);
      print_q5_3(q0[i*DWIDTH +: DWIDTH]);
      $display(")");
    end
    
    $display("\nPort 1 (Address %h):", addr1);
    for (integer i = 0; i < 8; i = i + 1) begin // Only check the ones we wrote to
      $write("Element %d: %h (", i, q1[i*DWIDTH +: DWIDTH]);
      print_q5_3(q1[i*DWIDTH +: DWIDTH]);
      $display(")");
    end
    
    // Test case 5: Simultaneous write to both ports (different addresses)
    $display("\nTest case 5: Simultaneous write to both ports (different addresses)");
    addr0 = 10'h15;
    for (integer i = 0; i < DESIGN_SIZE; i = i + 1) begin
      // Create Q5.3 values with non-zero fractional parts: 1.25, 2.25, 3.25, etc.
      d0[i*DWIDTH +: DWIDTH] = 8'h0A + (i * 8'h08); // 1.25 + i in Q5.3
    end
    we0 = 16'hFF00; // Upper 8 elements
    
    addr1 = 10'h20;
    for (integer i = 0; i < DESIGN_SIZE; i = i + 1) begin
      // Create mixed Q5.3 values: 4.75, 5.75, 6.75, etc.
      d1[i*DWIDTH +: DWIDTH] = 8'h26 + (i * 8'h08); // 4.75 + i in Q5.3
    end
    we1 = 16'h00FF; // Lower 8 elements
    #10;
    we0 = 0;
    we1 = 0;
    #10;
    
    // Verify writes
    $display("Verify port 0 write (Address %h):", addr0);
    for (integer i = 8; i < 16; i = i + 1) begin
      $write("Element %d: Written %h (", i, d0[i*DWIDTH +: DWIDTH]);
      print_q5_3(d0[i*DWIDTH +: DWIDTH]);
      $write("), Read %h (", q0[i*DWIDTH +: DWIDTH]);
      print_q5_3(q0[i*DWIDTH +: DWIDTH]);
      $display(")");
    end
    
    $display("\nVerify port 1 write (Address %h):", addr1);
    for (integer i = 0; i < 8; i = i + 1) begin
      $write("Element %d: Written %h (", i, d1[i*DWIDTH +: DWIDTH]);
      print_q5_3(d1[i*DWIDTH +: DWIDTH]);
      $write("), Read %h (", q1[i*DWIDTH +: DWIDTH]);
      print_q5_3(q1[i*DWIDTH +: DWIDTH]);
      $display(")");
    end
    
    // End simulation
    #100;
    $finish;
  end
endmodule