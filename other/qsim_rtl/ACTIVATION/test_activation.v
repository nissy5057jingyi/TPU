`timescale 1ns / 1ps

module activation_tb;

    // Parameters
    parameter DESIGN_SIZE = 16;
    parameter DWIDTH = 8;
    parameter MASK_WIDTH = 8;
	parameter IN_DATA_NUM = 1;
	parameter NOP_INP_NUM = DESIGN_SIZE-IN_DATA_NUM;
    
    // Testbench Signals
    reg activation_type;
    reg enable_activation;
    reg in_data_available;
    reg [DESIGN_SIZE*DWIDTH-1:0] inp_data;
    wire [DESIGN_SIZE*DWIDTH-1:0] out_data;
    wire out_data_available;
    reg [MASK_WIDTH-1:0] validity_mask;
    wire done_activation;
    reg clk;
    reg reset;

    // Instantiate the DUT (Device Under Test)
    activation uut (
        .activation_type(activation_type),
        .enable_activation(enable_activation),
        .in_data_available(in_data_available),
        .inp_data(inp_data),
        .out_data(out_data),
        .out_data_available(out_data_available),
        .validity_mask(validity_mask),
        .done_activation(done_activation),
        .clk(clk),
        .reset(reset)
    );

    // Clock Generation
    always #5 clk = ~clk;

    // Task for applying random stimulus
    task apply_random_stimulus;
        begin
            activation_type = $random % 2; // Randomly select ReLU or tanH
            enable_activation = 1;
            in_data_available = 1;
            inp_data = $random % 256;
            validity_mask = $random % 256;
            $display("[Random] Time=%0t, activation_type=%b, inp_data=%h, out_data=%h", $time, activation_type, inp_data, out_data);
            #10;
            in_data_available = 0;
        end
    endtask

    // Task for applying specific test cases
    task apply_specific_test_tanH;
        input [DESIGN_SIZE*DWIDTH-1:0] test_data;
        begin
            activation_type = 1;
            enable_activation = 1;
            in_data_available = 1;
            inp_data = test_data;
            validity_mask = {MASK_WIDTH{1'b1}}; // Set all bits to valid
            $display("[Specific] Time=%0t, activation_type=%b, inp_data=%h, out_data=%h", $time, activation_type, inp_data, out_data);
            #10;
            in_data_available = 0;
        end
    endtask

    // Initial block for simulation
    initial begin
        // Initialize signals
        clk = 0;
        reset = 1;
        enable_activation = 0;
        in_data_available = 0;
        inp_data = 0;
        validity_mask = 0;
        #20;
		@(posedge clk);
        reset = 0;
        
        // Apply random test cases
        repeat (20) apply_random_stimulus();
        
        // Apply specific test cases
        //apply_specific_test_tanH({NOP_INP_NUM*DWIDTH{1'b0}},{8'd15});
		apply_specific_test_tanH(256'd127);
        //apply_specific_test({16'd-100, 16'd50, 16'd-30, 16'd15, 16'd5, 16'd-25, 16'd90, 16'd-60});
        
        // Wait for completion
        #100;
        $stop;
    end

endmodule

