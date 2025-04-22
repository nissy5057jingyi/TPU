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

reg [`DESIGN_SIZE*`DWIDTH-1:0] out_data_temp;
reg done_pool_temp;
reg out_data_available_temp;
reg [31:0] cycle_count;
reg [`DESIGN_SIZE*`DWIDTH-1:0] inp_data_flopped;
reg in_data_available_flopped;
reg [31:0] i;
reg signed [`DWIDTH:0] sum; // Extra bit for sum to avoid overflow

// Assign outputs
assign out_data = enable_pool ? out_data_temp : inp_data;
assign out_data_available = enable_pool ? out_data_available_temp : in_data_available;
assign done_pool = enable_pool ? done_pool_temp : 1'b1;

always @(posedge clk) begin
    if (reset || ~enable_pool) begin
        out_data_temp <= 0;
        done_pool_temp <= 0;
        out_data_available_temp <= 0;
        cycle_count <= 0;
        inp_data_flopped <= 0;
        in_data_available_flopped <= 0;
    end
    else if (in_data_available) begin
        // Store the input data when it becomes available
        inp_data_flopped <= inp_data;
        in_data_available_flopped <= in_data_available;
        cycle_count <= cycle_count + 1;
        
        // Start pooling operation based on window size
        case (pool_window_size)
            1: begin // No pooling - pass through
                out_data_temp <= inp_data;
                out_data_available_temp <= 1'b1;
            end
            
            2: begin // 2x2 pooling
                for (i = 0; i < `DESIGN_SIZE/2; i = i + 1) begin
                    // Properly handle signed values
                    sum = $signed(inp_data[(i*2)*`DWIDTH +: `DWIDTH]) + 
                          $signed(inp_data[(i*2+1)*`DWIDTH +: `DWIDTH]);
                    out_data_temp[i*`DWIDTH +: `DWIDTH] <= sum >>> 1; // Arithmetic right shift
                    
                    // Zero out the unused output elements
                    if (i >= `DESIGN_SIZE/2) begin
                        out_data_temp[i*`DWIDTH +: `DWIDTH] <= 0;
                    end
                end
                out_data_available_temp <= 1'b1;
            end
            
            4: begin // 4x4 pooling
                for (i = 0; i < `DESIGN_SIZE/4; i = i + 1) begin
                    // Properly handle signed values
                    sum = $signed(inp_data[(i*4)*`DWIDTH +: `DWIDTH]) + 
                          $signed(inp_data[(i*4+1)*`DWIDTH +: `DWIDTH]) + 
                          $signed(inp_data[(i*4+2)*`DWIDTH +: `DWIDTH]) + 
                          $signed(inp_data[(i*4+3)*`DWIDTH +: `DWIDTH]);
                    out_data_temp[i*`DWIDTH +: `DWIDTH] <= sum >>> 2; // Arithmetic right shift
                    
                    // Zero out the unused output elements
                    if (i >= `DESIGN_SIZE/4) begin
                        out_data_temp[i*`DWIDTH +: `DWIDTH] <= 0;
                    end
                end
                out_data_available_temp <= 1'b1;
            end
            
            default: begin
                out_data_temp <= inp_data; // Default to pass-through for unsupported window sizes
                out_data_available_temp <= 1'b1;
            end
        endcase
        
        // Set done signal when processing is complete
        if (cycle_count >= `DESIGN_SIZE-1) begin
            done_pool_temp <= 1'b1;
        end
    end
    else begin
        // Reset state when input data is no longer available
        if (done_pool_temp) begin
            cycle_count <= 0;
            done_pool_temp <= 0;
        end
    end
end

endmodule