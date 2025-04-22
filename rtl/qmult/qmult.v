`define DWIDTH 8
module qmult(i_multiplicand,i_multiplier,o_result);

	input signed [`DWIDTH-1:0] i_multiplicand;//signed extension allowed?
	input signed [`DWIDTH-1:0] i_multiplier;
	output signed [2*`DWIDTH-1:0] o_result;
	
	assign o_result = i_multiplicand * i_multiplier;// cloud cause overflow in mutilication ??how to solve
	//DW02_mult #(`DWIDTH,`DWIDTH) u_mult(.A(i_multiplicand), .B(i_multiplier), .TC(1'b1), .PRODUCT(o_result));
	
	endmodule