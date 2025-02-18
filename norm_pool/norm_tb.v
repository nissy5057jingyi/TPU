`timescale 1ns/1ps

`define DWIDTH 16
`define DESIGN_SIZE 16 
`define MASK_WIDTH 16

module norm_tb();

reg clk;
reg reset;
reg enable_norm;
reg [`DWIDTH-1:0] mean;
reg [`DWIDTH-1:0] inv_var;
reg in_data_available;
reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data;
reg [`MASK_WIDTH-1:0] validity_mask;

wire [`DESIGN_SIZE*`DWIDTH-1:0] out_data;
wire out_data_available;
wire done_norm;

// For test verification
reg [31:0] cycle_count;
integer i, j;
reg [`DWIDTH-1:0] matrix_input[0:`DESIGN_SIZE-1];
reg [`DWIDTH-1:0] expected_output[0:`DESIGN_SIZE-1];
real float_mean, float_var, float_inv_var;
reg test_failed;
integer seed;
reg [511:0] test_name; // Increased size from 64 to 128 bits to accommodate longer test names

// Storage for captured outputs
reg [`DESIGN_SIZE*`DWIDTH-1:0] captured_output;
reg output_captured;

// Instantiate the Unit Under Test (UUT)
norm u_norm (
    .clk(clk),
    .reset(reset),
    .enable_norm(enable_norm),
    .mean(mean),
    .inv_var(inv_var),
    .in_data_available(in_data_available),
    .inp_data(inp_data),
    .out_data(out_data),
    .out_data_available(out_data_available),
    .validity_mask(validity_mask),
    .done_norm(done_norm)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// Output capture process
// This captures the output when out_data_available is asserted
always @(posedge clk) begin
    if (out_data_available && !output_captured) begin
        captured_output <= out_data;
        output_captured <= 1;
        $display("Output captured at cycle %d", cycle_count);
    end
end

// Cycle counter
always @(posedge clk) begin
    if (reset)
        cycle_count <= 0;
    else
        cycle_count <= cycle_count + 1;
end

// Helper function to format and print values in signed format when appropriate
function [31:0] format_as_signed;
    input [`DWIDTH-1:0] value;
    reg [31:0] result;
    begin
        // If high bit is set and value is large (likely a negative number)
        if (value[`DWIDTH-1] && value > 32768) begin
            // Convert to signed representation by subtracting from 2^16
            result = value - 65536; // 2^16 = 65536
        end else begin
            result = value;
        end
        format_as_signed = result;
    end
endfunction

// Task to initialize random input data
task generate_random_input;
    begin
        // Generate random input values in a more controlled range
        // This helps generate more meaningful test cases that won't overflow
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            // Generate values between 1 and 100 (avoid large or negative values)
            // We're using modulo with absolute value to ensure positive numbers
            matrix_input[i] = ($random(seed) % 100 + 100) % 100 + 1;
            inp_data[i*`DWIDTH +: `DWIDTH] = matrix_input[i];
        end
    end
endtask

// Task to calculate mean and variance
task calculate_stats;
    input [`MASK_WIDTH-1:0] mask;
    output [`DWIDTH-1:0] calc_mean;
    output [`DWIDTH-1:0] calc_inv_var;
    
    real sum;
    real sum_squared_diff;
    integer valid_count;
    real variance;
    integer truncated_mean;
    integer signed_input, diff;
    integer signed_mean_display;
    
    begin
        // Calculate mean
        sum = 0;
        valid_count = 0;
        
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            if(mask[i]) begin
                // Convert to signed value for calculation if appropriate
                if (matrix_input[i][`DWIDTH-1] && `DWIDTH == 16) begin
                    sum = sum + $signed(matrix_input[i]);
                end else begin
                    sum = sum + matrix_input[i];
                end
                valid_count = valid_count + 1;
            end
        end
        
        if(valid_count > 0) begin
            float_mean = sum / valid_count;
        end else begin
            float_mean = 0;
        end
        
        // Truncate to integer to match hardware behavior
        truncated_mean = $rtoi(float_mean);
        
        // Calculate variance
        sum_squared_diff = 0;
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            if(mask[i]) begin
                // Convert to signed value if appropriate
                if (matrix_input[i][`DWIDTH-1] && `DWIDTH == 16) begin
                    signed_input = $signed(matrix_input[i]);
                end else begin
                    signed_input = matrix_input[i];
                end
                
                diff = signed_input - truncated_mean;
                sum_squared_diff = sum_squared_diff + (diff * diff);
            end
        end
        
        if(valid_count > 1 && sum_squared_diff > 0) begin
            variance = sum_squared_diff / valid_count;
            float_inv_var = 1.0 / $sqrt(variance + 0.001);
            
            // Round to nearest integer for hardware consistency
            calc_inv_var = $rtoi(float_inv_var + 0.5);
            
            // Ensure minimum value of 1 if non-zero (to avoid multiplication issues)
            if (float_inv_var > 0 && calc_inv_var == 0) begin
                calc_inv_var = 1;
            end
        end else begin
            variance = 0;
            float_inv_var = 0;
            calc_inv_var = 0;
        end
        
        // Convert mean to fixed-point representation
        calc_mean = truncated_mean;
        
        // Display with proper signed conversion
        if (calc_mean > 32768) begin
            signed_mean_display = calc_mean - 65536;
        end else begin
            signed_mean_display = calc_mean;
        end
        
        $display("Stats: Mean = %f (%d), Variance = %f, Inv_Var = %f (%d)", 
                float_mean, signed_mean_display, variance, float_inv_var, calc_inv_var);
    end
endtask

// Task to calculate expected outputs
task calculate_expected_outputs;
    input [`MASK_WIDTH-1:0] mask;
    input en_norm;
    
    reg [`DWIDTH-1:0] mean_applied_result;
    integer signed_mean_result;
    integer signed_final_value;
    reg [`DWIDTH-1:0] after_mean;
    begin
        if (!en_norm) begin
            // If normalization is disabled, expected output equals input
            for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
                expected_output[i] = matrix_input[i];
            end
        end else begin
            // If normalization is enabled, apply normalization
            // For near-zero inv_var values (common in normalized data), results will be zero
            // This matches the hardware behavior since small multiplication results in zero
            if (inv_var < 1) begin
                for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
                    if(mask[i]) begin
                        expected_output[i] = 0;
                    end else begin
                        // Keep original value for invalid elements
                        expected_output[i] = matrix_input[i];
                    end
                end
            end else begin
                // For larger inv_var values, perform the calculation as in hardware
                for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
                    if(mask[i]) begin
                        // Simulate the two pipeline stages exactly as in hardware
                        // First stage: Compute (inp - mean)
                        mean_applied_result = matrix_input[i] - mean;
                        
                        // Second stage: Multiply by inv_var
                        // All calculations in the DWIDTH range with proper wrapping
                        expected_output[i] = mean_applied_result * inv_var;
                    end else begin
                        // Keep original value for invalid elements
                        expected_output[i] = matrix_input[i];
                    end
                end
            end
        end
        
        // Debug print to verify calculations
        $display("Expected calculation debug:");
        $display("  mean=%0d, inv_var=%0d", (mean > 32768) ? (mean - 65536) : mean, inv_var);
        $display("  First few calculations:");
        for(i = 0; i < 3 && i < `DESIGN_SIZE; i = i + 1) begin
            if (mask[i]) begin
                // Calculate difference for display correctly
                after_mean = matrix_input[i] - mean;
                
                // Convert for display - intermediate value
                if (after_mean > 32768) begin
                    signed_mean_result = after_mean - 65536;
                end else begin
                    signed_mean_result = after_mean;
                end
                
                // Convert for display - final value
                if (expected_output[i] > 32768) begin
                    signed_final_value = expected_output[i] - 65536;
                end else begin
                    signed_final_value = expected_output[i];
                end
                
                $display("  Element %0d: input=%0d, after mean=%0d, final=%0d",
                    i, matrix_input[i], 
                    signed_mean_result,
                    signed_final_value);
            end
        end
    end
endtask

// Task to display arrays and expected values
task display_arrays;
    input [511:0] msg; // Increased size to match test_name size
    
    // Local variables for signed display
    integer signed_value;
    begin
        $display("\nResults for %0s", msg); // Fixed format to show complete test name
        
        $display("Input array:");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            if (matrix_input[i] > 32768) begin
                signed_value = matrix_input[i] - 65536;
                $write("%8d ", signed_value); // Fixed width of 8 characters
            end else begin
                $write("%8d ", matrix_input[i]); // Fixed width of 8 characters
            end
            if((i+1) % 4 == 0) $write("\n");
        end
        
        $display("\nExpected output array:");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            if (expected_output[i] > 32768) begin
                signed_value = expected_output[i] - 65536;
                $write("%8d ", signed_value); // Fixed width of 8 characters
            end else begin
                $write("%8d ", expected_output[i]); // Fixed width of 8 characters
            end
            if((i+1) % 4 == 0) $write("\n");
        end
        
        $display("\nActual output array:");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            if (captured_output[i*`DWIDTH +: `DWIDTH] > 32768) begin
                signed_value = captured_output[i*`DWIDTH +: `DWIDTH] - 65536;
                $write("%8d ", signed_value); // Fixed width of 8 characters
            end else begin
                $write("%8d ", captured_output[i*`DWIDTH +: `DWIDTH]); // Fixed width of 8 characters
            end
            if((i+1) % 4 == 0) $write("\n");
        end
        $display("");
    end
endtask

// Task to verify outputs
task verify_outputs;
    input [`MASK_WIDTH-1:0] mask;
    output test_result;
    
    // Local variables for signed display
    integer signed_expected, signed_actual;
    begin
        test_result = 0;
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            if(captured_output[i*`DWIDTH +: `DWIDTH] !== expected_output[i]) begin
                // Convert to signed representation for display
                if (expected_output[i] > 32768) begin
                    signed_expected = expected_output[i] - 65536;
                end else begin
                    signed_expected = expected_output[i];
                end
                
                if (captured_output[i*`DWIDTH +: `DWIDTH] > 32768) begin
                    signed_actual = captured_output[i*`DWIDTH +: `DWIDTH] - 65536;
                end else begin
                    signed_actual = captured_output[i*`DWIDTH +: `DWIDTH];
                end
                
                $display("Error at element %0d: Expected: %0d, Got: %0d", 
                    i, signed_expected, signed_actual);
                test_result = 1;
            end
        end
    end
endtask

// Task to run a full test
task run_test;
    input [511:0] test_name_input; // Increased size to accommodate longer test names
    input [`MASK_WIDTH-1:0] mask;
    input en_norm;
    begin
        test_name = test_name_input;
        $display("\n--- %0s ---", test_name); // Using %0s format to print full string
        
        // Reset everything
        reset = 1;
        @(posedge clk);
        @(posedge clk);
        reset = 0;
        
        enable_norm = en_norm;
        validity_mask = mask;
        output_captured = 0;
        
        // Generate random input
        generate_random_input();
        
        // Calculate statistics and expected outputs
        calculate_stats(mask, mean, inv_var);
        calculate_expected_outputs(mask, en_norm);
        
        // Apply inputs and maintain stability
        in_data_available = 1;
        // Keep input data available for a few cycles to ensure proper processing
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);
        in_data_available = 0;
        
        // Wait for output to be available 
        wait(out_data_available);
        // Wait for one clock cycle to ensure output is stable before capturing
        @(posedge clk);
        // Wait one more cycle to make sure output is captured
        @(posedge clk);
        
        // Wait for module to complete
        wait(done_norm);
        @(posedge clk);
        
        // Display results and verify
        display_arrays(test_name); // Passing the full test name
        verify_outputs(mask, test_failed);
        
        if(!test_failed) begin
            $display("%0s Passed!", test_name); // Using %0s format
        end else begin
            $display("%0s Failed! See errors above.", test_name); // Using %0s format
        end
        
        // Wait a bit before starting next test
        repeat(5) @(posedge clk);
    end
endtask

// Test stimulus
initial begin
    // Enable waveform dumping
    $dumpfile("norm_tb.vcd");
    $dumpvars(0, norm_tb);
    
    // Initialize random seed
    seed = 12345;

    // Initialize inputs
    reset = 1;
    enable_norm = 0;
    mean = 0;
    inv_var = 0;
    in_data_available = 0;
    inp_data = 0;
    validity_mask = {`MASK_WIDTH{1'b1}};
    cycle_count = 0;
    test_failed = 0;
    output_captured = 0;

    // Wait for 100 ns for global reset
    #100;
    reset = 0;
    
    //---------------------------------------------------------------
    // Test Case 1: Module disabled
    //---------------------------------------------------------------
    run_test("Test Case 1: Module Disabled", {`MASK_WIDTH{1'b1}}, 0);
    
    //---------------------------------------------------------------
    // Test Case 2: Basic normalization with random data
    //---------------------------------------------------------------
    run_test("Test Case 2: Basic Normalization", {`MASK_WIDTH{1'b1}}, 1);
    
    //---------------------------------------------------------------
    // Test Case 3: Normalization with alternating validity mask
    //---------------------------------------------------------------
    run_test("Test Case 3: Alternating Validity Mask", 16'b1010_1010_1010_1010, 1);
    
    //---------------------------------------------------------------
    // Test Case 4: Normalization with random validity mask
    //---------------------------------------------------------------
    run_test("Test Case 4: Random Validity Mask", 16'b1100_0011_1010_0101, 1);

    $display("\nAll tests completed!");
    $finish;
end

endmodule