`timescale 1ns/1ps

module norm_tb();

// Set datawidth to 8 for int8 testing
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
    $display("\n==== INT8 NORMALIZATION TEST ====\n");
    
    // Apply reset for a few cycles
    repeat(5) @(posedge clk);
    reset = 0;
    @(posedge clk);
    
    // Set simple test values for int8
    mean = 8'd30;         // Mean = 10
    inv_var = 8'd2;       // Inverse variance = 2
    
    // Fill input data with a simple pattern
    begin
        integer i;
        for (i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            inp_data[i*`DWIDTH +: `DWIDTH] = 8'd20 + i; // Values start at 20 and increment
        end
    end
    
    $display("Test Parameters:");
    $display("  Mean = %0d", mean);
    $display("  Inv_var = %0d", inv_var);
    $display("  Input values start at %0d and increment by 1", 8'd20);
    $display("  Expected formula: (input - %0d) * %0d", mean, inv_var);
    
    // Print a few sample expected values
    $display("\nSample expected calculations:");
    begin
        integer i, in_val, expected;
        for (i = 0; i < 5; i = i + 1) begin
            in_val = 20 + i;
            expected = (in_val - mean) * inv_var;
            $display("  Element[%0d]: (%0d - %0d) * %0d = %0d", 
                    i, in_val, mean, inv_var, expected);
        end
    end
    
    // Enable normalization and make input data available
    enable_norm = 1;
    in_data_available = 1;
    @(posedge clk);
    
    // Keep in_data_available high for this cycle
    @(posedge clk);
    in_data_available = 0;
    
    // Wait for normalization to start processing
    repeat(5) @(posedge clk);
    
    // Monitor processing
    $display("\nModule state after 5 cycles:");
    $display("  cycle_count = %0d", uut.cycle_count);
    $display("  out_data_available = %0d", out_data_available);
    $display("  done_norm = %0d", done_norm);
    
    // Wait for the module to complete
    wait(done_norm || out_data_available);
    
    // Add a few extra cycles to ensure all processing is complete
    repeat(5) @(posedge clk);
    
    // Print actual output values and verify
    $display("\nRESULTS (first 10 elements):");
    $display("i\tInput\tOutput\tExpected\tCorrect?");
    $display("-------------------------------------------------");
    
    begin
        integer i, in_val, out_val, expected;
        string is_correct;
        
        for (i = 0; i < 10; i = i + 1) begin
            in_val = 20 + i;
            out_val = $signed(out_data[i*`DWIDTH +: `DWIDTH]);
            expected = (in_val - mean) * inv_var;
            
            if (out_val == expected)
                is_correct = "YES";
            else
                is_correct = "NO";
            
            $display("%0d\t%0d\t%0d\t%0d\t\t%s", 
                    i, in_val, out_val, expected, is_correct);
        end
    end
    
    // Summary
    $display("\nNormalization Module Status:");
    $display("  out_data_available = %b", out_data_available);
    $display("  done_norm = %b", done_norm);
    $display("  cycle_count = %0d", uut.cycle_count);
    
    $display("\nSimulation completed");
    $finish;
end

endmodule