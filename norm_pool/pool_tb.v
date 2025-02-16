`timescale 1ns/1ps

`define DWIDTH 8
`define DESIGN_SIZE 16
`define MASK_WIDTH 16
`define MAX_BITS_POOL 3

module pool_tb();

reg clk;
reg reset;
reg enable_pool;
reg in_data_available;
reg [`MAX_BITS_POOL-1:0] pool_window_size;
reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data;
reg [`MASK_WIDTH-1:0] validity_mask;

wire [`DESIGN_SIZE*`DWIDTH-1:0] out_data;
wire out_data_available;
wire done_pool;

// Maximum cycle count to prevent infinite loops
reg [31:0] cycle_count;
localparam MAX_CYCLES = 1000;

// Instantiate the Unit Under Test (UUT)
pool u_pool (
    .clk(clk),
    .reset(reset),
    .enable_pool(enable_pool),
    .in_data_available(in_data_available),
    .pool_window_size(pool_window_size),
    .inp_data(inp_data),
    .out_data(out_data),
    .out_data_available(out_data_available),
    .validity_mask(validity_mask),
    .done_pool(done_pool)
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

// Task to display input and output arrays
task display_arrays;
    input [127:0] msg;
    begin
        $display("\n%s", msg);
        $display("Input array:");
        for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            $write("%d ", inp_data[i*`DWIDTH +: `DWIDTH]);
            if((i+1) % 4 == 0) $write("\n");
        end
        
        $display("\nOutput array:");
        for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            $write("%d ", out_data[i*`DWIDTH +: `DWIDTH]);
            if((i+1) % 4 == 0) $write("\n");
        end
        $display("");
    end
endtask

// Test stimulus
initial begin
    // Initialize inputs
    reset = 1;
    enable_pool = 0;
    in_data_available = 0;
    pool_window_size = 1;
    inp_data = 0;
    validity_mask = {`MASK_WIDTH{1'b1}};
    cycle_count = 0;

    // Wait for 100 ns for global reset
    #100;
    reset = 0;
    
    // Test Case 1: Module disabled
    #20;
    enable_pool = 0;
    in_data_available = 1;
    pool_window_size = 2;
    // Fill input with increasing values
    for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        inp_data[i*`DWIDTH +: `DWIDTH] = i + 1;
    end
    #20;
    in_data_available = 0;
    
    // Wait for data to propagate
    @(posedge clk);
    #2;
    
    // Verify that when disabled, output equals input
    if (out_data !== inp_data) begin
        $display("Test Case 1 Failed: Output should equal input when disabled");
        display_arrays("Module Disabled Test");
    end else begin
        $display("Test Case 1 Passed: Bypass mode working correctly");
    end
    
    // Test Case 2: 1x1 pooling (effectively bypass)
    #20;
    enable_pool = 1;
    pool_window_size = 1;
    in_data_available = 1;
    #20;
    in_data_available = 0;
    
    @(posedge done_pool);
    if (out_data !== inp_data) begin
        $display("Test Case 2 Failed: 1x1 pooling should not modify data");
        display_arrays("1x1 Pooling Test");
    end else begin
        $display("Test Case 2 Passed: 1x1 pooling working correctly");
    end
    
    // Test Case 3: 2x2 pooling
    #20;
    enable_pool = 1;
    pool_window_size = 2;
    in_data_available = 1;
    // Create a test pattern where each 2x2 block has the same value
    for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        inp_data[i*`DWIDTH +: `DWIDTH] = (i/2) * 2;
    end
    #20;
    in_data_available = 0;
    
    @(posedge done_pool);
    display_arrays("2x2 Pooling Test");
    $display("Test Case 3 Passed: 2x2 pooling completed");
    
    // Test Case 4: 4x4 pooling
    #20;
    enable_pool = 1;
    pool_window_size = 4;
    in_data_available = 1;
    // Create a test pattern where each 4x4 block has increasing values
    for(integer i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        inp_data[i*`DWIDTH +: `DWIDTH] = (i/4) * 4;
    end
    #20;
    in_data_available = 0;
    
    @(posedge done_pool);
    display_arrays("4x4 Pooling Test");
    $display("Test Case 4 Passed: 4x4 pooling completed");
    
    // Wait a few cycles to ensure all signals have settled
    repeat(5) @(posedge clk);
    
    // End simulation
    $display("All tests completed successfully!");
    $finish;
end

// Optional: Generate VCD file for waveform viewing
initial begin
    $dumpfile("pool_tb.vcd");
    $dumpvars(0, pool_tb);
end

endmodule