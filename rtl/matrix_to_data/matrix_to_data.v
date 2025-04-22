module matrix_to_data #(
	parameter DWIDTH = 4,
	parameter SIZE = 16
) (
	input clk,
	input rst,
	input [DWIDTH-1:0] data_i,
	output [SIZE*DWIDTH-1:0] data_out
);
	reg [SIZE*DWIDTH-1:0] data_out_internal;
	reg [3:0]count_cycle;
	always@(posedge clk)begin
		if(rst) begin
			count_cycle <= 0;
		end
		else if (count_cycle == 15)begin
			count_cycle <= 0;
		end
		else begin
			count_cycle <= count_cycle + 1;
		end
	end
	always@(posedge clk)begin
		if(rst) begin
			data_out_internal <=0 ;
		end
		else begin
			data_out_internal <= {data_i,data_out_internal[(SIZE-1)*DESIGN_SIZE-1:0]} >> 4;
		end
	end
	assign data_out = (count_cycle == 15)?data_out_internal:'d0;


endmodule