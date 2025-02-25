`timescale 1ns/1ps

module norm_tb();

// Set datawidth to 16 for Q8.8 testing
`define DWIDTH 16
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

// Helper function to convert Q8.8 to decimal for display
function real q8_8_to_decimal;
    input [15:0] q8_8_val;
    begin
        q8_8_to_decimal = $itor(q8_8_val) / 256.0;
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
    $display("\n==== Q8.8 NORMALIZATION TEST ====\n");
    
    // Apply reset for a few cycles
    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);
    
    // Set test values in Q8.8 format
    mean = 16'h0140;       // 1.25 in Q8.8 (1*256 + 0.25*256 = 320 = 0x140)
    inv_var = 16'h0180;    // 1.5 in Q8.8 (1*256 + 0.5*256 = 384 = 0x180)
    
    // Fill input data with a simple pattern
    begin
        integer i;
        for (i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            // Values from 3.5 to 7.0 in Q8.8 format
            inp_data[i*`DWIDTH +: `DWIDTH] = 16'h0380 + i*16'h0040; // 3.5 + i*0.25 in Q8.8
        end
        stored_inp_data = inp_data; // Store for later comparison
    end
    
    $display("Test Parameters:");
    $display("  Mean = 0x%h (%.4f in decimal)", mean, q8_8_to_decimal(mean));
    $display("  Inv_var = 0x%h (%.4f in decimal)", inv_var, q8_8_to_decimal(inv_var));
    $display("  Q8.8 format: 8 bits integer, 8 bits fraction");
    
    // Print a few sample expected values (with Q16.16 intermediate results)
    $display("\nSample expected calculations:");
    begin
        integer i;
        reg [15:0] in_val;
        reg [31:0] q16_16_result; // Q16.16 intermediate result
        reg [15:0] q8_8_result;   // Q8.8 final result
        
        for (i = 0; i < 5; i = i + 1) begin
            in_val = 16'h0380 + i*16'h0040; // Input value (3.5 + i*0.25)
            
            // Calculate (in_val - mean) * inv_var with Q16.16 precision
            q16_16_result = (in_val - mean) * inv_var;
            
            // Round to Q8.8 (shift right by 8 bits)
            q8_8_result = q16_16_result[23:8]; // Take middle 16 bits
            
            $display("  Element[%0d]: Input=0x%h (%.4f)", 
                    i, in_val, q8_8_to_decimal(in_val));
            $display("    Step 1: (0x%h - 0x%h) = 0x%h (%.4f - %.4f = %.4f)", 
                    in_val, mean, (in_val - mean), 
                    q8_8_to_decimal(in_val), q8_8_to_decimal(mean), 
                    q8_8_to_decimal(in_val - mean));
            $display("    Step 2: Q16.16 result = 0x%h * 0x%h = 0x%h", 
                    (in_val - mean), inv_var, q16_16_result);
            $display("    Step 3: Q8.8 result = 0x%h (%.4f in decimal)", 
                    q8_8_result, q8_8_to_decimal(q8_8_result));
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
            reg [15:0] in_val;
            reg [15:0] out_val;
            reg [31:0] q16_16_result;
            reg [15:0] q8_8_result;
            string is_correct;
            real tolerance = 0.01; // Tolerance for floating point comparison
            
            for (i = 0; i < 8; i = i + 1) begin
                in_val = stored_inp_data[i*`DWIDTH +: `DWIDTH];
                out_val = out_data[i*`DWIDTH +: `DWIDTH];
                
                // Calculate expected value
                q16_16_result = (in_val - mean) * inv_var;
                q8_8_result = q16_16_result[23:8]; // Take middle 16 bits for rounding to Q8.8
                
                // Check if output is close to expected value
                if (q8_8_to_decimal(out_val) - q8_8_to_decimal(q8_8_result) < tolerance &&
                    q8_8_to_decimal(q8_8_result) - q8_8_to_decimal(out_val) < tolerance)
                    is_correct = "YES";
                else
                    is_correct = "NO";
                
                $display("%0d\t0x%h\t%.4f\t0x%h\t%.4f\t0x%h\t%.4f\t%s", 
                        i, in_val, q8_8_to_decimal(in_val),
                        out_val, q8_8_to_decimal(out_val),
                        q8_8_result, q8_8_to_decimal(q8_8_result),
                        is_correct);
                        
                // Debug - print intermediate calculation details if incorrect
                if (is_correct == "NO") begin
                    $display("  DEBUG: Q16.16 intermediate = 0x%h", q16_16_result);
                    $display("         Mean subtraction = 0x%h (%.4f)", 
                            (in_val - mean), q8_8_to_decimal(in_val - mean));
                    $display("         Variance applied = 0x%h * 0x%h", 
                            (in_val - mean), inv_var);
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
    
    // Look at internal module states
    $display("\nInternal Module Values (first element):");
    $display("  Input data: 0x%h (%.4f)", 
            stored_inp_data[0 +: `DWIDTH], q8_8_to_decimal(stored_inp_data[0 +: `DWIDTH]));
    $display("  Mean applied: 0x%h (%.4f)", 
            uut.mean_applied_data[0 +: `DWIDTH], q8_8_to_decimal(uut.mean_applied_data[0 +: `DWIDTH]));
    $display("  Variance applied: 0x%h (%.4f)", 
            uut.variance_applied_data[0 +: `DWIDTH], q8_8_to_decimal(uut.variance_applied_data[0 +: `DWIDTH]));
    $display("  Output data: 0x%h (%.4f)", 
            out_data[0 +: `DWIDTH], q8_8_to_decimal(out_data[0 +: `DWIDTH]));
            
    // Calculate expected Q16.16 result for validation
    begin
        reg [31:0] q16_16_expected;
        q16_16_expected = (stored_inp_data[0 +: `DWIDTH] - mean) * inv_var;
        $display("  Expected Q16.16 (intermediate): 0x%h", q16_16_expected);
        $display("  Expected Q8.8 (final): 0x%h (%.4f)", 
                q16_16_expected[23:8], q8_8_to_decimal(q16_16_expected[23:8]));
    end
    
    $display("\nSimulation completed");
    $finish;
end

endmodule