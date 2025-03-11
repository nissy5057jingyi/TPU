`timescale 1ns/1ps

module norm_tb();

// Set datawidth to 8 for Q5.3 testing
`define DWIDTH 8
`define DESIGN_SIZE 32
`define MASK_WIDTH 32

// Test bench signals
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

// For tracking and displaying computation
reg [`DESIGN_SIZE*`DWIDTH-1:0] stored_inp_data;

// Instantiate the module under test
norm uut (
    .enable_norm(enable_norm),
    .mean(mean),
    .inv_var(inv_var),
    .in_data_available(in_data_available),
    .inp_data(inp_data),
    .out_data(out_data),
    .out_data_available(out_data_available),
    .validity_mask(validity_mask),
    .done_norm(done_norm),
    .clk(clk),
    .reset(reset)
);

// Clock generation
initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period (100MHz)
end

// Helper function to convert Q5.3 to decimal for display (handles signed values)
function real q5_3_to_decimal;
    input [7:0] q5_3_val;
    begin
        // Check if the value is negative (MSB is 1)
        if (q5_3_val[7] == 1'b1) begin
            // Convert 2's complement to decimal and divide by 8
            q5_3_to_decimal = $itor($signed(q5_3_val)) / 8.0;
        end else begin
            q5_3_to_decimal = $itor(q5_3_val) / 8.0;
        end
    end
endfunction

// Helper function to apply standard rounding for expected results
// This matches our new implementation's rounding behavior
function [7:0] apply_standard_rounding;
    input [15:0] q10_6_result;
    begin
        reg [7:0] shifted_value;
        reg [2:0] bits_shifted_out;
        
        // Extract main bits and fractional bits
        shifted_value = q10_6_result[10:3];
        bits_shifted_out = q10_6_result[2:0];
        
        // Apply standard rounding logic
        if (q10_6_result[15]) begin // Negative case
            if (bits_shifted_out >= 3'b100) begin // Fraction >= 0.5
                apply_standard_rounding = shifted_value - 8'd1; // Round down
            end else begin
                apply_standard_rounding = shifted_value; // Round up (toward zero)
            end
        end else begin // Positive case
            if (bits_shifted_out >= 3'b100) begin // Fraction >= 0.5
                apply_standard_rounding = shifted_value + 8'd1; // Round up
            end else begin
                apply_standard_rounding = shifted_value; // Round down (toward zero)
            end
        end
    end
endfunction

// Test sequence
initial begin
    // Initialize all inputs
    reset = 1;
    enable_norm = 0;
    mean = 0;
    inv_var = 0;
    in_data_available = 0;
    inp_data = 0;
    validity_mask = {`MASK_WIDTH{1'b1}}; // All elements valid
    
    // Display header
    $display("\n==== Q5.3 NORMALIZATION TEST WITH STANDARD ROUNDING ====\n");
    
    // Apply reset for a few cycles
    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);
    
    // Set test values in Q5.3 format
    mean = 8'h04;       // 0.5 in Q5.3 (0.5*8 = 4 = 0x04)
    inv_var = 8'h0C;    // 1.5 in Q5.3 (1*8 + 0.5*8 = 12 = 0x0C)
    
    // Fill input data with values ranging from -2.25 to 1.5 in steps of 0.125
    begin
        integer i;
        real current_val;
        reg [7:0] q5_3_val;
        
        for (i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            // Calculate the decimal value: -2.25 + i*0.125
            current_val = -2.25 + i * 0.125;
            
            // Convert to Q5.3 (multiply by 8)
            if (current_val < 0) begin
                // For negative values, convert to 2's complement
                q5_3_val = 8'hFF & ((~(8'd0 - $rtoi(current_val * 8.0))) + 1);
            end else begin
                q5_3_val = 8'd0 + $rtoi(current_val * 8.0);
            end
            
            // Store in input data array
            inp_data[i*`DWIDTH +: `DWIDTH] = q5_3_val;
            
            // Print the first few values to verify conversion
            if (i < 8) begin
                $display("Input[%0d]: %.3f decimal => 0x%h Q5.3 format", 
                        i, current_val, q5_3_val);
            end
        end
        
        stored_inp_data = inp_data; // Store for later comparison
    end
    
    $display("Test Parameters:");
    $display("  Mean = 0x%h (%.4f in decimal)", mean, q5_3_to_decimal(mean));
    $display("  Inv_var = 0x%h (%.4f in decimal)", inv_var, q5_3_to_decimal(inv_var));
    $display("  Q5.3 format: 1 sign bit, 4 bits integer, 3 bits fraction");
    $display("  Rounding: Standard rounding (away from zero if fraction >= 0.5)");
    
    // Print sample expected values including both negative and positive inputs
    $display("\nSample expected calculations with standard rounding:");
    begin
        integer i;
        integer sample_indices[5] = '{0, 8, 16, 24, 30}; // Specifically chosen to show range
        reg [7:0] in_val;
        reg [15:0] q10_6_result; // Q10.6 intermediate result
        reg [7:0] q5_3_result;   // Q5.3 final result
        
        for (i = 0; i < 5; i = i + 1) begin
            in_val = inp_data[sample_indices[i]*`DWIDTH +: `DWIDTH];
            
            // Calculate (in_val - mean) * inv_var with Q10.6 precision
            q10_6_result = ($signed(in_val) - $signed(mean)) * $signed(inv_var);
            
            // Apply standard rounding
            q5_3_result = apply_standard_rounding(q10_6_result);
            
            $display("  Element[%0d]: Input=0x%h (%.4f)", 
                    sample_indices[i], in_val, q5_3_to_decimal(in_val));
            $display("    Step 1: (0x%h - 0x%h) = 0x%h (%.4f - %.4f = %.4f)", 
                    in_val, mean, ($signed(in_val) - $signed(mean)), 
                    q5_3_to_decimal(in_val), q5_3_to_decimal(mean), 
                    q5_3_to_decimal($signed(in_val) - $signed(mean)));
            $display("    Step 2: Q10.6 result = 0x%h * 0x%h = 0x%h", 
                    ($signed(in_val) - $signed(mean)), inv_var, q10_6_result);
            $display("    Step 3: Q5.3 result with standard rounding = 0x%h (%.4f in decimal)", 
                    q5_3_result, q5_3_to_decimal(q5_3_result));
        end
    end
    
    // Enable normalization and make input data available
    enable_norm = 1;
    in_data_available = 1;
    @(posedge clk);
    
    // Keep data available for a few cycles to ensure it's processed
    repeat(2) @(posedge clk);
    in_data_available = 0;
    
    // Wait for out_data_available or timeout
    begin
        integer timeout;
        timeout = 0;
        while (!out_data_available && timeout < 100) begin
            @(posedge clk);
            timeout = timeout + 1;
        end
        
        if (timeout >= 100) begin
            $display("\n!!! TIMEOUT WAITING FOR out_data_available !!!");
            $display("Module internal state:");
            $display("  enable_norm = %b", enable_norm);
            $display("  cycle_count = %d", uut.cycle_count);
            $display("  out_data_available_internal = %b", uut.out_data_available_internal);
            $display("  norm_in_progress = %b", uut.norm_in_progress);
        end
    end
    
    // Add a few more cycles to ensure processing completes
    repeat(5) @(posedge clk);
    
    // Print actual output values and verify
    if (out_data_available) begin
        $display("\nRESULTS (first 8 elements):");
        $display("i\tInput (hex)\tInput (dec)\tOutput (hex)\tOutput (dec)\tExpected (hex)\tExpected (dec)\tCorrect?");
        $display("---------------------------------------------------------------------------------------------------------------");
        
        begin
            integer i;
            reg [7:0] in_val;
            reg [7:0] out_val;
            reg [15:0] q10_6_result;
            reg [7:0] q5_3_result;
            string is_correct;
            real tolerance = 0.05; // Tolerance for floating point comparison
            
            for (i = 0; i < 8; i = i + 1) begin
                in_val = stored_inp_data[i*`DWIDTH +: `DWIDTH];
                out_val = out_data[i*`DWIDTH +: `DWIDTH];
                
                // Calculate expected value with standard rounding
                q10_6_result = ($signed(in_val) - $signed(mean)) * $signed(inv_var);
                q5_3_result = apply_standard_rounding(q10_6_result);
                
                // Check if output is close to expected value
                if (q5_3_to_decimal(out_val) - q5_3_to_decimal(q5_3_result) < tolerance &&
                    q5_3_to_decimal(q5_3_result) - q5_3_to_decimal(out_val) < tolerance)
                    is_correct = "YES";
                else
                    is_correct = "NO";
                
                $display("%0d\t0x%h\t%.4f\t0x%h\t%.4f\t0x%h\t%.4f\t%s", 
                        i, in_val, q5_3_to_decimal(in_val),
                        out_val, q5_3_to_decimal(out_val),
                        q5_3_result, q5_3_to_decimal(q5_3_result),
                        is_correct);
                        
                // Debug - print intermediate calculation details if incorrect
                if (is_correct == "NO") begin
                    $display("  DEBUG: Q10.6 intermediate = 0x%h", q10_6_result);
                    $display("         Fractional bits = 0x%h", q10_6_result[2:0]);
                    $display("         Mean subtraction = 0x%h (%.4f)", 
                            (in_val - mean), q5_3_to_decimal(in_val - mean));
                    $display("         Expected with std rounding = 0x%h", q5_3_result);
                    $display("         Module calculated = 0x%h", out_val);
                end
            end
        end
    end else begin
        $display("\n!!! NO OUTPUT DATA AVAILABLE !!!");
    end
    
    // Summary
    $display("\nNormalization Module Status:");
    $display("  out_data_available = %b", out_data_available);
    $display("  done_norm = %b", done_norm);
    $display("  cycle_count = %0d", uut.cycle_count);
    
    // Look at internal module states for both a negative and positive input
    $display("\nInternal Module Values (examining two elements):");
    
    // Negative example (first element, should be -2.25)
    $display("NEGATIVE EXAMPLE (index 0, value -2.25):");
    $display("  Input data: 0x%h (%.4f)", 
            stored_inp_data[0 +: `DWIDTH], q5_3_to_decimal(stored_inp_data[0 +: `DWIDTH]));
    $display("  Mean applied: 0x%h (%.4f)", 
            uut.mean_applied_data[0 +: `DWIDTH], q5_3_to_decimal(uut.mean_applied_data[0 +: `DWIDTH]));
    $display("  Variance applied: 0x%h (%.4f)", 
            uut.variance_applied_data[0 +: `DWIDTH], q5_3_to_decimal(uut.variance_applied_data[0 +: `DWIDTH]));
    $display("  Output data: 0x%h (%.4f)", 
            out_data[0 +: `DWIDTH], q5_3_to_decimal(out_data[0 +: `DWIDTH]));
            
    // Calculate expected Q10.6 result for validation (negative example)
    begin
        reg [15:0] q10_6_expected;
        q10_6_expected = ($signed(stored_inp_data[0 +: `DWIDTH]) - $signed(mean)) * $signed(inv_var);
        $display("  Expected Q10.6 (intermediate): 0x%h", q10_6_expected);
        $display("  Expected Q5.3 with standard rounding: 0x%h (%.4f)", 
                apply_standard_rounding(q10_6_expected), 
                q5_3_to_decimal(apply_standard_rounding(q10_6_expected)));
    end
    
    // Positive example (element 30, should be 1.5)
    $display("\nPOSITIVE EXAMPLE (index 30, value 1.5):");
    $display("  Input data: 0x%h (%.4f)", 
            stored_inp_data[30*`DWIDTH +: `DWIDTH], q5_3_to_decimal(stored_inp_data[30*`DWIDTH +: `DWIDTH]));
    $display("  Mean applied: 0x%h (%.4f)", 
            uut.mean_applied_data[30*`DWIDTH +: `DWIDTH], q5_3_to_decimal(uut.mean_applied_data[30*`DWIDTH +: `DWIDTH]));
    $display("  Variance applied: 0x%h (%.4f)", 
            uut.variance_applied_data[30*`DWIDTH +: `DWIDTH], q5_3_to_decimal(uut.variance_applied_data[30*`DWIDTH +: `DWIDTH]));
    $display("  Output data: 0x%h (%.4f)", 
            out_data[30*`DWIDTH +: `DWIDTH], q5_3_to_decimal(out_data[30*`DWIDTH +: `DWIDTH]));
            
    // Calculate expected Q10.6 result for validation (positive example)
    begin
        reg [15:0] q10_6_expected;
        q10_6_expected = ($signed(stored_inp_data[30*`DWIDTH +: `DWIDTH]) - $signed(mean)) * $signed(inv_var);
        $display("  Expected Q10.6 (intermediate): 0x%h", q10_6_expected);
        $display("  Expected Q5.3 with standard rounding: 0x%h (%.4f)", 
                apply_standard_rounding(q10_6_expected), 
                q5_3_to_decimal(apply_standard_rounding(q10_6_expected)));
    end
    
    $display("\nSimulation completed with standard rounding for negative numbers");
    $finish;
end

endmodule