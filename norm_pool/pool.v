////////////////////////////////////////////////
// Pooling block
////////////////////////////////////////////////

module pool(
    input enable_pool,
    input in_data_available,
	  input [`MAX_BITS_POOL-1:0] pool_window_size,
    input [`DESIGN_SIZE*`DWIDTH-1:0] inp_data,
    output [`DESIGN_SIZE*`DWIDTH-1:0] out_data,
    output out_data_available,
    input [`MASK_WIDTH-1:0] validity_mask,
    output done_pool,
    input clk,
    input reset
);

reg in_data_available_flopped;
reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data_flopped;

reg [`DESIGN_SIZE*`DWIDTH-1:0] out_data_temp;
reg done_pool_temp;
reg out_data_available_temp;
reg [31:0] i,j;
reg [31:0] cycle_count;

always @(posedge clk) begin
	if (reset || ~enable_pool || ~in_data_available) begin
		out_data_temp <= 0;
		done_pool_temp <= 0;
		out_data_available_temp <= 0;
		cycle_count <= 0;
    in_data_available_flopped <= in_data_available;
    inp_data_flopped <= inp_data;
	end

	else if (in_data_available) begin
    cycle_count <= cycle_count + 1;
		out_data_available_temp <= 1;

		case (pool_window_size)
			1: begin
				out_data_temp <= inp_data;
			end
			2: begin
				for (i = 0; i < `DESIGN_SIZE/2; i = i + 8) begin
					out_data_temp[ i +: 8] <= (inp_data[i*2 +: 8]  + inp_data[i*2 + 8 +: 8]) >> 1; 
				end
			end
			4: begin	
				for (i = 0; i < `DESIGN_SIZE/4; i = i + 8) begin
					//TODO: If 3 adders are the critical path, break into 2 cycles
					out_data_temp[ i +: 8] <= (inp_data[i*4 +: 8]  + inp_data[i*4 + 8 +: 8] + inp_data[i*4 + 16 +: 8]  + inp_data[i*4 + 24 +: 8]) >> 2; 
				end
			end
		endcase			

        if(cycle_count==`DESIGN_SIZE) begin	 
            done_pool_temp <= 1'b1;	      
        end	  
	end
end

assign out_data = enable_pool ? out_data_temp : inp_data_flopped; 
assign out_data_available = enable_pool ? out_data_available_temp : in_data_available_flopped;
assign done_pool = enable_pool ? done_pool_temp : 1'b1;

//Adding a dummy signal to use validity_mask input, to make ODIN happy
wire [`MASK_WIDTH-1:0] dummy;
assign dummy = validity_mask;

endmodule
