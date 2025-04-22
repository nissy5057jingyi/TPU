`timescale 1ns / 1ps

module tb_matmul_16_16;

    // Parameters
    parameter DWIDTH = 8;
    parameter MAT_MUL_SIZE = 16;
    parameter AWIDTH = 10;
    parameter ADDR_STRIDE_WIDTH = 16;

    // Clock and reset
    reg clk;
    reg reset;
    reg pe_reset;
    
    // Control Signals
    reg start_mat_mul;
    wire done_mat_mul;

    // Memory addresses
    reg [AWIDTH-1:0] address_mat_a;
    reg [AWIDTH-1:0] address_mat_b;
    reg [AWIDTH-1:0] address_mat_c;
    reg [ADDR_STRIDE_WIDTH-1:0] address_stride_a;
    reg [ADDR_STRIDE_WIDTH-1:0] address_stride_b;
    reg [ADDR_STRIDE_WIDTH-1:0] address_stride_c;

    // Input Data
    reg [MAT_MUL_SIZE*DWIDTH-1:0] a_data;
    reg [MAT_MUL_SIZE*DWIDTH-1:0] b_data;
    wire [MAT_MUL_SIZE*DWIDTH-1:0] c_data_out;

    // Connectivity signals
    wire [MAT_MUL_SIZE*DWIDTH-1:0] a_data_out;
    wire [MAT_MUL_SIZE*DWIDTH-1:0] b_data_out;
    wire [AWIDTH-1:0] a_addr;
    wire [AWIDTH-1:0] b_addr;
    wire [AWIDTH-1:0] c_addr;
    wire c_data_available;

    // Validity masks
    reg [MAT_MUL_SIZE-1:0] validity_mask_a_rows;
    reg [MAT_MUL_SIZE-1:0] validity_mask_a_cols;
    reg [MAT_MUL_SIZE-1:0] validity_mask_b_rows;
    reg [MAT_MUL_SIZE-1:0] validity_mask_b_cols;

    // MatMul configuration
    reg [7:0] final_mat_mul_size;
    reg [7:0] a_loc;
    reg [7:0] b_loc;

    // Instantiate the DUT
    matmul_16_16_systolic uut (
        .clk(clk),
        .reset(reset),
        .pe_reset(pe_reset),
        .start_mat_mul(start_mat_mul),
        .done_mat_mul(done_mat_mul),
        .address_mat_a(address_mat_a),
        .address_mat_b(address_mat_b),
        .address_mat_c(address_mat_c),
        .address_stride_a(address_stride_a),
        .address_stride_b(address_stride_b),
        .address_stride_c(address_stride_c),
        .a_data(a_data),
        .b_data(b_data),
        .a_data_in(0),
        .b_data_in(0),
        .c_data_in(0),
        .c_data_out(c_data_out),
        .a_data_out(a_data_out),
        .b_data_out(b_data_out),
        .a_addr(a_addr),
        .b_addr(b_addr),
        .c_addr(c_addr),
        .c_data_available(c_data_available),
        .validity_mask_a_rows(validity_mask_a_rows),
        .validity_mask_a_cols(validity_mask_a_cols),
        .validity_mask_b_rows(validity_mask_b_rows),
        .validity_mask_b_cols(validity_mask_b_cols),
        .final_mat_mul_size(final_mat_mul_size),
        .a_loc(a_loc),
        .b_loc(b_loc)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Test sequence
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        pe_reset = 1;
        start_mat_mul = 0;
        address_mat_a = 0;
        address_mat_b = 0;
        address_mat_c = 0;
        address_stride_a = 16;
        address_stride_b = 16;
        address_stride_c = 16;
        final_mat_mul_size = 16;
        a_loc = 0;
        b_loc = 0;

        // Reset system
        #20 
		reset = 0;
        pe_reset = 0;
		validity_mask_a_rows = 16'b1111111111111111;
		validity_mask_a_cols = 16'b1111111111111111;
		validity_mask_b_rows = 16'b1111111111111111;
		validity_mask_b_cols = 16'b1111111111111111;
        // Load matrix A

		/*for (int i = 0; i < MAT_MUL_SIZE; i = i + 1) begin

            a_data = {16{8'h01}}; // Example: all elements = 1
            b_data = {16{8'h02}}; // Example: all elements = 2
			@(posedge clk);
		end*/
		

        // Start computation
        #20 start_mat_mul = 1;
		a_data = {16{8'h01}}; // Example: all elements = 1
        // Load matrix B
        b_data = {16{8'h02}}; // Example: all elements = 2、

        // Wait for computation to finish
        wait(done_mat_mul);

        // Output results
        $display("Matrix Multiplication Completed!");
        $display("C Data Output: %h", c_data_out);
        
        #100;
        $finish;
    end

endmodule
