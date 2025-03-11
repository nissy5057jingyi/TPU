//The width of the data. Changing to Q5.3 precision with sign bit. So, DWIDTH is 8
//This supports signed fixed-point arithmetic (1 sign bit, 4 integer bits, 3 fractional bits)
//To change to a floating point 16 version, change this to 16 and also
//change the datapath components (like adder and multiplier) to be floating point. 
`define DWIDTH 8

//This is the size of the matrix multiplier unit. In this design, we have a systolic
//matrix multiplication unit that can multiply 32x32 matrix with a 32x32 matrix.
`define DESIGN_SIZE 32
`define LOG2_DESIGN_SIZE 5
`define MAT_MUL_SIZE 32
`define MASK_WIDTH 32
`define LOG2_MAT_MUL_SIZE 5

//This it the size of the address bus, or the depth of the RAM. Each location of 
//the RAM is DWIDTH * MAT_MUL_SIZE wide. So, in this design, we use a total of
//1024 * 32 bytes of memory (i.e. 32 KB).
`define AWIDTH 10

//This is the number of clock cycles spent in the mac block
`define NUM_CYCLES_IN_MAC 3

//This defines the latency of accessing data from a block ram
`define MEM_ACCESS_LATENCY 1

//Data width and address width of the APB interface for registers
`define REG_DATAWIDTH 32
`define REG_ADDRWIDTH 8

//Width of the stride for each column in the matrices (same as ram address width)
`define ADDR_STRIDE_WIDTH 16

//Number of bits to specify the pooling window. We support 3 sizes.
`define MAX_BITS_POOL 3



////////////////////////////////////////////////
// Normalization block
////////////////////////////////////////////////

module norm(
    input enable_norm,
    input [`DWIDTH-1:0] mean,
    input [`DWIDTH-1:0] inv_var,
    input in_data_available,
    input [`DESIGN_SIZE*`DWIDTH-1:0] inp_data,
    output [`DESIGN_SIZE*`DWIDTH-1:0] out_data,
    output out_data_available,
    input [`MASK_WIDTH-1:0] validity_mask,
    output done_norm,
    input clk,
    input reset
);

reg out_data_available_internal;
wire [`DESIGN_SIZE*`DWIDTH-1:0] out_data_internal;
reg [`DESIGN_SIZE*`DWIDTH-1:0] mean_applied_data;
reg [`DESIGN_SIZE*`DWIDTH-1:0] variance_applied_data;
reg done_norm_internal;
reg norm_in_progress;
reg in_data_available_flopped;
reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data_flopped;

//Muxing logic to handle the case when this block is disabled
assign out_data_available = (enable_norm) ? out_data_available_internal : in_data_available_flopped;
assign out_data = (enable_norm) ? out_data_internal : inp_data_flopped;
assign done_norm = (enable_norm) ? done_norm_internal : 1'b1;

//inp_data will have multiple elements in it. the number of elements is the same as size of the matmul.
//on each clock edge, if in_data_available is 1, then we will normalize the inputs.

//the code uses the funky part-select syntax. example:
//wire [7:0] byteN = word[byte_num*8 +: 8];
//byte_num*8 is the starting point. 8 is the width is the part-select (has to be constant).in_data_available
//+: indicates the part-select increases from the starting point
//-: indicates the part-select decreases from the starting point
//another example:
//loc = 3;
//PA[loc -:4] = PA[loc+1 +:4];  // equivalent to PA[3:0] = PA[7:4];

reg [31:0] cycle_count;
reg [31:0] i;
always @(posedge clk) begin
    if ((reset || ~enable_norm)) begin
        mean_applied_data <= 0;
        variance_applied_data <= 0;
        out_data_available_internal <= 0;
        cycle_count <= 0;
        done_norm_internal <= 0;
        norm_in_progress <= 0;
        in_data_available_flopped <= in_data_available;
        inp_data_flopped <= inp_data;
    end else if (in_data_available || norm_in_progress) begin
        cycle_count <= cycle_count + 1;
        //Let's apply mean and variance as the input data comes in.
        //We have a pipeline here. First stage does the add (to apply the mean)
        //and second stage does the multiplication (to apply the variance).
        //Note: the following loop is not a loop across multiple columns of data.
        //This loop will run in 2 cycle on the same column of data that comes into 
        //this module in 1 clock.
        for (i = 0; i < `DESIGN_SIZE; i=i+1) begin
            if (validity_mask[i] == 1'b1) begin
                // Subtraction is signed
                mean_applied_data[i*`DWIDTH +: `DWIDTH] <= $signed(inp_data[i*`DWIDTH +: `DWIDTH]) - $signed(mean);
                // Signed multiplication with correct rounding for both positive and negative numbers
                begin
                    reg [15:0] temp_result;
                    reg [7:0] shifted_value;
                    reg [2:0] bits_shifted_out;
                    
                    // Calculate intermediate result (Q10.6 format)
                    temp_result = $signed(mean_applied_data[i*`DWIDTH +: `DWIDTH]) * $signed(inv_var);
                    
                    // Get bits being shifted out and main value
                    shifted_value = temp_result[15:3]; // Main 8 bits after shift
                    bits_shifted_out = temp_result[2:0]; // 3 LSBs that will be shifted out
                    

                    // Modified rounding logic for negative numbers
                    if (temp_result[15]) begin // Negative case (MSB=1)
                        // Standard rounding for negative numbers:
                        // - Round toward negative infinity (down) if fraction >= 0.5
                        // - Round toward zero (up) if fraction < 0.5
                        if (bits_shifted_out >= 3'b100) begin
                            variance_applied_data[i*`DWIDTH +: `DWIDTH] <= shifted_value - 8'd1;
                        end else begin
                            variance_applied_data[i*`DWIDTH +: `DWIDTH] <= shifted_value;
                        end
                    end else begin // Positive case (unchanged)
                        // Standard rounding for positive: round up if >= 0.5
                        if (bits_shifted_out >= 3'b100) begin
                            variance_applied_data[i*`DWIDTH +: `DWIDTH] <= shifted_value + 8'd1;
                        end else begin
                            variance_applied_data[i*`DWIDTH +: `DWIDTH] <= shifted_value;
                        end
                    end
                end
            end 
            else begin
                mean_applied_data[i*`DWIDTH +: `DWIDTH] <= (inp_data[i*`DWIDTH +: `DWIDTH]);
                variance_applied_data[i*`DWIDTH +: `DWIDTH] <= (mean_applied_data[i*`DWIDTH +: `DWIDTH]);
            end
        end

        //Out data is available starting with the second clock cycle because 
        //in the first cycle, we only apply the mean.
        if(cycle_count==2) begin
            out_data_available_internal <= 1;
        end

        //When we've normalized values N times, where N is the matmul
        //size, that means we're done. But there is one additional cycle
        //that is taken in the beginning (when we are applying the mean to the first
        //column of data). We can call this the Initiation Interval of the pipeline.
        //So, for a 4x4 matmul, this block takes 5 cycles.
        if(cycle_count==(`DESIGN_SIZE+1)) begin
            done_norm_internal <= 1'b1;
            norm_in_progress <= 0;
        end
        else begin
            norm_in_progress <= 1;
        end
    end
    else begin
        mean_applied_data <= 0;
        variance_applied_data <= 0;
        out_data_available_internal <= 0;
        cycle_count <= 0;
        done_norm_internal <= 0;
        norm_in_progress <= 0;
    end
end

assign out_data_internal = variance_applied_data;

endmodule