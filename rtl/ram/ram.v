`define AWIDTH 10
`define DESIGN_SIZE 16
`define DWIDTH 8
module ram (
	addr0, 
	d0, 
	we0, 
	q0,  
	addr1,
	d1,
	we1,
	q1,
	clk);

	input [`AWIDTH-1:0] addr0;
	input [`AWIDTH-1:0] addr1;
	input [`DESIGN_SIZE*`DWIDTH-1:0] d0;
	input [`DESIGN_SIZE*`DWIDTH-1:0] d1;
	input [`DESIGN_SIZE-1:0] we0;
	input [`DESIGN_SIZE-1:0] we1;
	output [`DESIGN_SIZE*`DWIDTH-1:0] q0;
	output [`DESIGN_SIZE*`DWIDTH-1:0] q1;
	input clk;

	genvar i; 

	generate
/*`ifdef QUARTUS
for (i=0;i<`DESIGN_SIZE;i=i+1) begin: gen_dp1
	end
`else*/
	for (i=0;i<`DESIGN_SIZE;i=i+1) begin
//`endif
		dpram_original #(.AWIDTH(`AWIDTH),.DWIDTH(`DWIDTH),.NUM_WORDS(1<<`AWIDTH)) dp1 (.clk(clk),.address_a(addr0),.address_b(addr1),.wren_a(we0[i]),.wren_b(we1[i]),.data_a(d0[i*`DWIDTH +: `DWIDTH]),.data_b(d1[i*`DWIDTH +: `DWIDTH]),.out_a(q0[i*`DWIDTH +: `DWIDTH]),.out_b(q1[i*`DWIDTH +: `DWIDTH]));
	end//1*2^10
	endgenerate
endmodule