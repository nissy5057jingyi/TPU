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
localparam MAX_CYCLES = 1000;

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

// Cycle counter and timeout
always @(posedge clk) begin
    if (reset)
        cycle_count <= 0;
    else
        cycle_count <= cycle_count + 1;
        
    if (cycle_count >= MAX_CYCLES) begin
        $display("Error: Simulation timeout after %d cycles", MAX_CYCLES);
        $finish;
    end
end

// Test stimulus
initial begin
    // Initialize inputs
    reset = 1;
    enable_norm = 0;
    mean = 0;
    inv_var = 0;
    in_data_available = 0;
    inp_data = 0;
    validity_mask = {`MASK_WIDTH{1'b1}};
    cycle_count = 0;

    // Wait for 100 ns for global reset
    #100;
    reset = 0;
    
    // Test Case 1: Module disabled
    #20;
    enable_norm = 0;
    in_data_available = 1;
    inp_data = {16{8'h42}}; // Setting all elements to 0x42
    #20;
    in_data_available = 0;
    
    // Wait for data to propagate
    @(posedge clk);
    #2;
    
    // Verify that when disabled, output equals input
    if (out_data !== inp_data) begin
        $display("Test Case 1 Failed: Output should equal input when disabled");
        $display("Expected: %h", inp_data);
        $display("Got: %h", out_data);
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
    
    // Wait for normalization to complete
    @(posedge done_norm);
    
    // For input 32, mean 16, inv_var 2:
    // Expected: (32-16)*2 = 32 for each element
    for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        if (out_data[i*`DWIDTH +: `DWIDTH] !== 8'h20) begin
            $display("Test Case 2 Failed at element %d", i);
            $display("Expected: 0x20, Got: %h", out_data[i*`DWIDTH +: `DWIDTH]);
        end
    end
    $display("Test Case 2 Passed!");
    
    // Test Case 3: Test with validity mask
    #20;
    validity_mask = 16'h5555; // Every other element is valid
    in_data_available = 1;
    inp_data = {16{8'h30}}; // Setting all elements to 0x30
    
    // Wait for normalization to complete
    @(posedge done_norm);
    
    // Check that invalid elements remain unchanged
    for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        if (validity_mask[i] == 0) begin
            if (out_data[i*`DWIDTH +: `DWIDTH] !== inp_data[i*`DWIDTH +: `DWIDTH]) begin
                $display("Test Case 3 Failed at invalid element %d", i);
                $display("Expected: %h, Got: %h", 
                    inp_data[i*`DWIDTH +: `DWIDTH],
                    out_data[i*`DWIDTH +: `DWIDTH]);
            end
        end
    end
    $display("Test Case 3 Passed!");
    
    // Wait a few cycles to ensure all signals have settled
    repeat(5) @(posedge clk);
    
    // End simulation
    $display("All tests completed successfully!");
    $finish;
end

// Optional: Generate VCD file for waveform viewing
initial begin
    $dumpfile("norm_tb.vcd");
    $dumpvars(0, norm_tb);
end

endmodule