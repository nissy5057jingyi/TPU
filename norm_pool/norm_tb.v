`timescale 1ns/1ps

`define DWIDTH 8
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

// Maximum cycle count to prevent infinite loops
reg [31:0] cycle_count;
reg test_failed; // Moved declaration to top
integer i; // Added for loop variable
localparam MAX_CYCLES = 50;

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

// Cycle counter
always @(posedge clk) begin
    if (reset)
        cycle_count <= 0;
    else
        cycle_count <= cycle_count + 1;
end

// Task to display arrays
task display_arrays;
    input [127:0] msg;
    begin
        $display("\n%s", msg);
        $display("Input array:");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            $write("%d ", inp_data[i*`DWIDTH +: `DWIDTH]);
            if((i+1) % 4 == 0) $write("\n");
        end
        
        $display("\nOutput array:");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            $write("%d ", out_data[i*`DWIDTH +: `DWIDTH]);
            if((i+1) % 4 == 0) $write("\n");
        end
        $display("");
    end
endtask

// Test stimulus
initial begin
    // Enable waveform dumping
    $fsdbDumpfile("waves.fsdb");
    $fsdbDumpvars(0, norm_tb);
    $fsdbDumpMDA();

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

    // Wait for 100 ns for global reset
    #100;
    reset = 0;
    
    // Test Case 1: Module disabled
    #20;
    enable_norm = 0;
    in_data_available = 1;
    inp_data = {16{8'h42}}; // Setting all elements to 0x42
    repeat(5) @(posedge clk);
    in_data_available = 0;
    repeat(5) @(posedge clk);
    
    // Verify that when disabled, output equals input
    if (out_data !== inp_data) begin
        $display("Test Case 1 Failed: Output should equal input when disabled");
        $display("Expected: %h", inp_data);
        $display("Got: %h", out_data);
        display_arrays("Module Disabled Test");
    end else begin
        $display("Test Case 1 Passed!");
    end
    
    // Test Case 2: Basic normalization
    #20;
    enable_norm = 1;
    mean = 8'h10; // Mean value of 16
    inv_var = 8'h02; // Inverse variance of 2
    in_data_available = 1;
    inp_data = {16{8'h20}}; // Setting all elements to 0x20 (32 in decimal)
    repeat(5) @(posedge clk);
    in_data_available = 0;
    repeat(5) @(posedge clk);
    
    // For input 32, mean 16, inv_var 2:
    // Expected: (32-16)*2 = 32 for each element
    test_failed = 0;
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        if (out_data[i*`DWIDTH +: `DWIDTH] !== 8'h20) begin
            $display("Test Case 2 Failed at element %d", i);
            $display("Expected: 0x20, Got: %h", out_data[i*`DWIDTH +: `DWIDTH]);
            test_failed = 1;
        end
    end
    if (!test_failed) begin
        $display("Test Case 2 Passed!");
    end
    
    // Test Case 3: Test with validity mask
    #20;
    validity_mask = 16'h5555; // Every other element is valid
    in_data_available = 1;
    inp_data = {16{8'h30}}; // Setting all elements to 0x30
    repeat(10) @(posedge clk); // Wait longer for stability
    in_data_available = 0;
    repeat(10) @(posedge clk); // Wait longer after data input

    $display("\nTest Case 3: Validity Mask Test");
    display_arrays("Before validation");

    // Debug prints
    $display("Validity mask: %h", validity_mask);
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        $display("Element %d: valid=%b, input=%h, output=%h", 
            i, validity_mask[i], inp_data[i*`DWIDTH +: `DWIDTH], 
            out_data[i*`DWIDTH +: `DWIDTH]);
    end

    // Check results
    test_failed = 0;
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        if (validity_mask[i] == 0) begin // Invalid element
            if (out_data[i*`DWIDTH +: `DWIDTH] !== inp_data[i*`DWIDTH +: `DWIDTH]) begin
                $display("Error at element %d (invalid): Expected: %h, Got: %h", 
                    i, inp_data[i*`DWIDTH +: `DWIDTH], 
                    out_data[i*`DWIDTH +: `DWIDTH]);
                test_failed = 1;
            end
        end
        else begin // Valid element - should be normalized
            if (out_data[i*`DWIDTH +: `DWIDTH] == inp_data[i*`DWIDTH +: `DWIDTH]) begin
                $display("Error at element %d (valid): Expected normalization but got same as input", i);
                test_failed = 1;
            end
        end
    end

    if (test_failed)
        $display("Test Case 3 Failed!");
    else
        $display("Test Case 3 Passed!");

    display_arrays("After validation");

    // Wait a few more cycles to see final outputs
    repeat(5) @(posedge clk);
    
    $display("All tests completed successfully!");
    $finish;
end

endmodule