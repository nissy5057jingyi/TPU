`timescale 1ns/1ps
`define DWIDTH 8

module tb_processing_element;

  // Testbench signals
  reg clk, reset;
  reg [`DWIDTH-1:0] in_a;
  reg [18:0] in_b;
  wire [`DWIDTH-1:0] out_a;
  wire [18:0] out_b;
  wire [`DWIDTH-1:0] out_c;

  // Instantiate the processing element
  processing_element uut (
    .reset(reset),
    .clk(clk),
    .in_a(in_a),
    .in_b(in_b),
    .out_a(out_a),
    .out_b(out_b),
    .out_c(out_c)
  );

  // Clock generation
  always #5 clk = ~clk; // 10ns clock period

  // Monitor Task
  task monitor;
    $display("Time=%0t | reset=%b | in_a=%d | in_b=%d | out_a=%d | out_b=%d | out_c=%d", 
              $time, reset, in_a, in_b, out_a, out_b, out_c);
  endtask

  // Task for generating random inputs
  task random_stimulus;
    integer i;
    begin
      for (i = 0; i < 20; i = i + 1) begin
        in_a = $random % 256;  // 8-bit random number
        in_b = $random % 256; // 19-bit random number
        @(posedge clk);
        monitor;
      end
    end
  endtask

  // Task for generating specific inputs
  task specific_stimulus;
    begin
      in_a = 8'd15;  in_b = 19'd10;  @(posedge clk); monitor; // Example case 1
      in_a = 8'd45;  in_b = -3;  @(posedge clk); monitor; // Example case 2
      in_a = 8'd10;  in_b = -2; @(posedge clk); monitor; // Example case 3
    end
  endtask

  // Test Sequence
  initial begin
    // Initialize
    clk = 0;
    reset = 1;
    in_a = 0;
    in_b = 0;

    // Apply reset
    #10 reset = 0;
    #10 reset = 1;
    #10 reset = 0;

    // Run test tasks
	specific_stimulus();
    random_stimulus();


    // End simulation
    #50 $finish;
  end

endmodule
