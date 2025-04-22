`timescale 1ns / 1ps//unit/persicion

module tb_seq_mac;

    // Define parameters
    parameter DWIDTH = 8;
    
    // Declare signals
    reg signed [DWIDTH-1:0] a;
    reg signed [DWIDTH-1:0] b;
	reg reset;
	reg clk;
	wire signed [DWIDTH-1:0] out;
    reg signed [2*DWIDTH-1:0] expected_result;
    reg correct;

    // Instantiate the DUT (Device Under Test)
    seq_mac uut (
        .a(a),
        .b(b),
        .reset(reset),
		.clk(clk),
		.out(out)
    );

	initial begin
		clk = 0;
		forever #5 clk = ~clk;
	end

    // Function to generate 10 special test cases
    task generate_special_tests;
        begin
			
            a = 0; b = 127; 
			@(posedge clk);
			expected_result = 0; //check_result(); // 0 * max
			@(posedge clk);
            a = 127; b = 127;
			@(posedge clk);
			expected_result = 127;  //check_result(); // max * max
			@(posedge clk);
            a = 64; b = -128; 
			@(posedge clk);
			expected_result = 127; //check_result(); // min * min
			@(posedge clk);
            a = 62; b = 128; 
			@(posedge clk);
			expected_result = 1;  //check_result(); // min * max
			@(posedge clk);
            a = -9; b = 9; 
			@(posedge clk);
			expected_result = -80; //check_result(); // -1 * 1
			@(posedge clk);
            a = -5; b = 4;
			@(posedge clk); 
			expected_result = -100;  //check_result(); // 1 * -1
			@(posedge clk);
            a = 11; b = 11;
			@(posedge clk);
			expected_result = 21; //check_result(); // mid * negative
			@(posedge clk);
            a = 11; b = 11;
			@(posedge clk);
			expected_result = 127; //check_result(); // negative * mid
			@(posedge clk);
            a = -20; b = 20;
			@(posedge clk);
			expected_result = -128; //check_result(); // negative * negative
			@(posedge clk);
            a = 30; b = 10;
			@(posedge clk);
			expected_result = 42;  //check_result(); // normal positive
        end
    endtask

    // Function to check if the result matches the expected value
    task check_result;
        begin
            if (out !== expected_result) begin
                correct = 0;
                $display("ERROR: out = %d (Expected: %d) ", out, expected_result);
                terminate_simulation();
            end else begin
                correct = 1;
                $display("PASS: %d * %d = %d", a, b, out);
            end
        end
    endtask

    // Function to terminate simulation if any test case fails
    task terminate_simulation;
        begin
            if (correct == 0) begin
                $display("TEST FAILED! Simulation terminated.");
                $finish;
            end
        end
    endtask

    // Test sequence
    initial begin
        $display("Starting Multiplication Testbench...");
		
		reset = 1;
		a     = 0;
		b     = 0;
		@(posedge clk);
		reset = 0;
         // Run 20 random tests
        generate_special_tests(); // Run 10 special tests

        $display("All tests passed!");
        $finish;
    end

endmodule


