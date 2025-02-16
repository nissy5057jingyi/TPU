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
integer i, j, x, y; // Add j and other loop variables

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
            $write("%3d ", inp_data[i*`DWIDTH +: `DWIDTH]);
            if((i+1) % 4 == 0) $write("\n");
        end
        
        $display("\nOutput array:");
        for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
            $write("%3d ", out_data[i*`DWIDTH +: `DWIDTH]);
            if((i+1) % 4 == 0) $write("\n");
        end
        $display("");
    end
endtask

// Helper task to calculate expected pooling results
task check_pooling_result;
    input [3:0] window_size;
    input [`DESIGN_SIZE*`DWIDTH-1:0] inp;
    input [`DESIGN_SIZE*`DWIDTH-1:0] outp;
    reg test_passed;
    integer sum, count;
    begin
        test_passed = 1;
        
        for(y = 0; y < `DESIGN_SIZE/window_size; y = y + 1) begin
            for(x = 0; x < `DESIGN_SIZE/window_size; x = x + 1) begin
                // Calculate expected average for this window
                sum = 0;
                for(i = 0; i < window_size; i = i + 1) begin
                    for(j = 0; j < window_size; j = j + 1) begin
                        sum = sum + inp[((y*window_size + i)*`DESIGN_SIZE + (x*window_size + j))*`DWIDTH +: `DWIDTH];
                    end
                end
                count = window_size * window_size;
                
                // Compare with actual output
                if(outp[(y*`DESIGN_SIZE + x)*`DWIDTH +: `DWIDTH] !== sum/count) begin
                    $display("Mismatch at (%0d,%0d): Expected %0d, Got %0d", 
                        x, y, sum/count, outp[(y*`DESIGN_SIZE + x)*`DWIDTH +: `DWIDTH]);
                    test_passed = 0;
                end
            end
        end
        
        if(test_passed)
            $display("Pooling test passed for window size %0d!", window_size);
        else
            $display("Pooling test failed for window size %0d", window_size);
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
    
    // Test Case 1: Module disabled (bypass mode)
    $display("\n=== Test Case 1: Module Disabled (Bypass Mode) ===");
    #20;
    enable_pool = 0;
    pool_window_size = 2;
    // Fill input with increasing values
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        inp_data[i*`DWIDTH +: `DWIDTH] = i + 1;
    end
    in_data_available = 1;
    repeat(5) @(posedge clk);
    display_arrays("Bypass Mode Test");
    
    if (out_data !== inp_data) begin
        $display("Test Case 1 Failed: Output should equal input when disabled");
    end else begin
        $display("Test Case 1 Passed: Bypass mode working correctly");
    end
    in_data_available = 0;
    
    // Test Case 2: 1x1 pooling
    $display("\n=== Test Case 2: 1x1 Pooling ===");
    #20;
    enable_pool = 1;
    pool_window_size = 1;
    in_data_available = 1;

    $display("Initial status:");
    $display("enable_pool = %b", enable_pool);
    $display("pool_window_size = %d", pool_window_size);
    $display("in_data_available = %b", in_data_available);
    $display("out_data_available = %b", out_data_available);
    
    repeat(10) @(posedge clk);
    display_arrays("1x1 Pooling Test");
    check_pooling_result(1, inp_data, out_data);
    in_data_available = 0;
    
    // Test Case 3: 2x2 pooling
    $display("\n=== Test Case 3: 2x2 Pooling ===");
    #20;
    enable_pool = 1;
    pool_window_size = 2;
    // Create a pattern where elements increase by 1
    for(i = 0; i < `DESIGN_SIZE; i = i + 1) begin
        inp_data[i*`DWIDTH +: `DWIDTH] = i;
    end
    in_data_available = 1;
    
    repeat(10) @(posedge clk);
    display_arrays("2x2 Pooling Test");
    check_pooling_result(2, inp_data, out_data);
    in_data_available = 0;
    
    // Test Case 4: 4x4 pooling
    $display("\n=== Test Case 4: 4x4 Pooling ===");
    #20;
    enable_pool = 1;
    pool_window_size = 4;
    in_data_available = 1;
    
    repeat(10) @(posedge clk);
    display_arrays("4x4 Pooling Test");
    check_pooling_result(4, inp_data, out_data);
    in_data_available = 0;
    
    repeat(5) @(posedge clk);
    $display("\nAll tests completed!");
    $finish;
end

endmodule