`timescale 1ns / 1ps

module tb_ram;

// Parameters
parameter AWIDTH = 10;
parameter DESIGN_SIZE = 16;
parameter DWIDTH = 8;

// Ports
reg [AWIDTH-1:0] addr0;
reg [AWIDTH-1:0] addr1;
reg [DESIGN_SIZE*DWIDTH-1:0] d0;
reg [DESIGN_SIZE*DWIDTH-1:0] d1;
reg [DESIGN_SIZE-1:0] we0;
reg [DESIGN_SIZE-1:0] we1;
wire [DESIGN_SIZE*DWIDTH-1:0] q0;
wire [DESIGN_SIZE*DWIDTH-1:0] q1;
reg clk;

integer i;
integer j;
// Instantiate DUT
ram uut (
    .addr0(addr0),
    .addr1(addr1),
    .d0(d0),
    .d1(d1),
    .we0(we0),
    .we1(we1),
    .q0(q0),
    .q1(q1),
    .clk(clk)
);

// Clock generation
always #5 clk = ~clk;

// Stimulus
initial begin
    clk = 0;
    addr0 = 0;
    addr1 = 0;
    d0 = 0;
    d1 = 0;
    we0 = 0;
    we1 = {DESIGN_SIZE{1'b1}}; // Set `we1` high for all bits

    // Initialize d1 with random values and set addr1 from 0 to 15
    $display("Starting RAM Test...");
    for (i = 0; i < DESIGN_SIZE; i = i + 1) begin
        @(posedge clk);
        addr1 = i;  // Set address from 0 to 15
        for (j = 0; j < DESIGN_SIZE; j = j + 1) begin
            d1[j*DWIDTH +: DWIDTH] = $urandom_range(0, 255); // Random 8-bit data
        end
        $display("Written to addr1 = %0d, Data = %h", addr1, d1);
    end

    // Read back data


    $display("RAM Test Completed.");
    $finish;
end

endmodule

