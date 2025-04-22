`timescale 1ns / 1ps//unit/persicion

module tb_qmult;

    // Define parameters
    parameter DWIDTH = 8;
    
    // Declare signals
    reg signed [DWIDTH-1:0] i_multiplicand;
    reg signed [DWIDTH-1:0] i_multiplier;
    wire signed [2*DWIDTH-1:0] o_result;
    reg signed [2*DWIDTH-1:0] expected_result;
    reg correct;

    // Instantiate the DUT (Device Under Test)
    qmult uut (
        .i_multiplicand(i_multiplicand),
        .i_multiplier(i_multiplier),
        .o_result(o_result)
    );

    // Function to generate 20 random test cases
    task generate_random_tests;
        integer i;
        begin
            for (i = 0; i < 20; i = i + 1) begin
                i_multiplicand = $random % (1 << (DWIDTH-1)); // Generate signed 8-bit value
                i_multiplier = $random % (1 << (DWIDTH-1));   // Generate signed 8-bit value
                expected_result = i_multiplicand * i_multiplier;
                #10;
                check_result();
            end
        end
    endtask

    // Function to generate 10 special test cases
    task generate_special_tests;
        begin
            i_multiplicand = 0; i_multiplier = 127; expected_result = 0; #10; check_result(); // 0 * max
            i_multiplicand = 127; i_multiplier = 127; expected_result = 16129; #10; check_result(); // max * max
            i_multiplicand = -128; i_multiplier = -128; expected_result = 16384; #10; check_result(); // min * min
            i_multiplicand = -128; i_multiplier = 127; expected_result = -16256; #10; check_result(); // min * max
            i_multiplicand = -1; i_multiplier = 1; expected_result = -1; #10; check_result(); // -1 * 1
            i_multiplicand = 1; i_multiplier = -1; expected_result = -1; #10; check_result(); // 1 * -1
            i_multiplicand = 64; i_multiplier = -2; expected_result = -128; #10; check_result(); // mid * negative
            i_multiplicand = -64; i_multiplier = 2; expected_result = -128; #10; check_result(); // negative * mid
            i_multiplicand = -1; i_multiplier = -1; expected_result = 1; #10; check_result(); // negative * negative
            i_multiplicand = 2; i_multiplier = 3; expected_result = 6; #10; check_result(); // normal positive
        end
    endtask

    // Function to check if the result matches the expected value
    task check_result;
        begin
            if (o_result !== expected_result) begin
                correct = 0;
                $display("ERROR: %d * %d = %d (Expected: %d)", i_multiplicand, i_multiplier, o_result, expected_result);
                terminate_simulation();
            end else begin
                correct = 1;
                $display("PASS: %d * %d = %d", i_multiplicand, i_multiplier, o_result);
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

        generate_random_tests(); // Run 20 random tests
        generate_special_tests(); // Run 10 special tests

        $display("All tests passed!");
        $finish;
    end

endmodule


