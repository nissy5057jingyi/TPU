`timescale 1ns / 1ps

module tb_dpram_original;
  // Parameters
  parameter AWIDTH = 10;
  parameter DWIDTH = 16;  // Updated to 16 for Q8.8 fixed-point
  parameter NUM_WORDS = 1024;
  
  // Inputs
  reg clk;
  reg [AWIDTH-1:0] address_a;
  reg [AWIDTH-1:0] address_b;
  reg wren_a;
  reg wren_b;
  reg [DWIDTH-1:0] data_a;
  reg [DWIDTH-1:0] data_b;
  
  // Outputs
  wire [DWIDTH-1:0] out_a;
  wire [DWIDTH-1:0] out_b;
  
  // Helper function to print Q8.8 numbers
  function automatic void print_q8_8;
    input [DWIDTH-1:0] value;
    begin
      if (value[DWIDTH-1]) // Check sign bit
        $write("-");
      else
        $write("+");
        
      $write("%d.%02d", 
        value[DWIDTH-2:8],                       // Integer part (7 bits)
        (value[7:0] * 100) / 256);              // Fractional part converted to decimal
    end
  endfunction
  
  // Instantiate the Unit Under Test (UUT)
  dpram_original #(
    .AWIDTH(AWIDTH),
    .DWIDTH(DWIDTH),
    .NUM_WORDS(NUM_WORDS)
  ) uut (
    .clk(clk),
    .address_a(address_a),
    .address_b(address_b),
    .wren_a(wren_a),
    .wren_b(wren_b),
    .data_a(data_a),
    .data_b(data_b),
    .out_a(out_a),
    .out_b(out_b)
  );
  
  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 100MHz clock
  end
  
  // Test sequence
  initial begin
    // Initialize inputs
    address_a = 0;
    address_b = 0;
    wren_a = 0;
    wren_b = 0;
    data_a = 0;
    data_b = 0;
    
    // Wait for global reset
    #100;
    
    // Test case 1: Write to port A, read from port A
    $display("Test case 1: Write to port A, read from port A");
    address_a = 10'h5;
    data_a = 16'h0280;  // 2.5 in Q8.8 (2*256 + 0.5*256)
    wren_a = 1;
    #10;
    wren_a = 0;
    #10;
    $write("Address: %h, Data written: %h (", address_a, data_a);
    print_q8_8(data_a);
    $write("), Data read: %h (", out_a);
    print_q8_8(out_a);
    $display(")");
    
    // Test case 2: Write to port B, read from port B
    $display("\nTest case 2: Write to port B, read from port B");
    address_b = 10'hA;
    data_b = 16'hFF80;  // -0.5 in Q8.8 (1's complement of 0.5 + 1)
    wren_b = 1;
    #10;
    wren_b = 0;
    #10;
    $write("Address: %h, Data written: %h (", address_b, data_b);
    print_q8_8(data_b);
    $write("), Data read: %h (", out_b);
    print_q8_8(out_b);
    $display(")");
    
    // Test case 3: Write to port A, read from port B (same address)
    $display("\nTest case 3: Write to port A, read from port B (same address)");
    address_a = 10'h15;
    data_a = 16'h0320;  // 3.125 in Q8.8 (3*256 + 0.125*256)
    wren_a = 1;
    #10;
    wren_a = 0;
    address_b = 10'h15;
    #10;
    $write("Address A: %h, Data written A: %h (", address_a, data_a);
    print_q8_8(data_a);
    $write("), Address B: %h, Data read B: %h (", address_b, out_b);
    print_q8_8(out_b);
    $display(")");
    
    // Test case 4: Simultaneous write to both ports (different addresses)
    $display("\nTest case 4: Simultaneous write to both ports (different addresses)");
    address_a = 10'h20;
    data_a = 16'h0100;  // 1.0 in Q8.8
    wren_a = 1;
    address_b = 10'h21;
    data_b = 16'h0180;  // 1.5 in Q8.8
    wren_b = 1;
    #10;
    wren_a = 0;
    wren_b = 0;
    #10;
    $write("Address A: %h, Data written A: %h (", address_a, data_a);
    print_q8_8(data_a);
    $write("), Data read A: %h (", out_a);
    print_q8_8(out_a);
    $display(")");
    
    $write("Address B: %h, Data written B: %h (", address_b, data_b);
    print_q8_8(data_b);
    $write("), Data read B: %h (", out_b);
    print_q8_8(out_b);
    $display(")");
    
    // Test case 5: Simultaneous write to both ports (same address) - behavior depends on implementation
    $display("\nTest case 5: Simultaneous write to both ports (same address)");
    address_a = 10'h30;
    data_a = 16'h0400;  // 4.0 in Q8.8
    wren_a = 1;
    address_b = 10'h30;
    data_b = 16'h0500;  // 5.0 in Q8.8
    wren_b = 1;
    #10;
    wren_a = 0;
    wren_b = 0;
    #10;
    $write("Address A/B: %h, Data written A: %h (", address_a, data_a);
    print_q8_8(data_a);
    $write("), Data written B: %h (", data_b);
    print_q8_8(data_b);
    $display(")");
    
    $write("Data read A: %h (", out_a);
    print_q8_8(out_a);
    $write("), Data read B: %h (", out_b);
    print_q8_8(out_b);
    $display(")");
    
    // End simulation
    #100;
    $finish;
  end
endmodule