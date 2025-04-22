
`define DWIDTH 8
module processing_element(
	reset, 
	clk, 
	in_a,
	in_b, 
	out_a, 
	out_b, 
	out_c
	);
   
   `ifdef complex_dsp
	//in this mode, the processing unit use DSP slice to perform calculation
	// DSP slice is special block used in FPGA ,used to execute multiplication
	input reset;
	input clk;
	input  [`DWIDTH-1:0] in_a;
	input  [18:0] in_b;
	output reg [`DWIDTH-1:0] out_a;
	output [18:0] out_b;
	output [`DWIDTH-1:0] out_c;  //reduced precision
   
	wire [18:0] scanout;
	wire [63:0] chainout; //unconnected
	wire [63:0] result;
	wire [17:0] ax;
	wire [18:0] ay; //unconnected
	wire [35:0] bx;
	wire [63:0] chainin; //unconnected
	wire [18:0] scanin;
	wire [11:0] mode_sigs;
   
	assign mode_sigs = 12'b010101010101;  //Any value of mode_sigs (structural, not functional, correctness)
	assign ax = {{(18-`DWIDTH){1'b0}}, in_a};
	//assign ay = {{(19-`DWIDTH){1'b0}}, in_b};
	assign bx = 36'b0;
	assign scanin = in_b;
   
	 //We will instantiate DSP slices with input chaining.
	 //Input chaining is only supported in the 18x19 mode or the 27x27 mode.
	 //We will use the input chain provided by the DSP for the B input. For A, the chain will be manual.
   
	 mult_add_int_18x19 u_pe(
	   .clk(clk),
	   .reset(reset),
	   .mode_sigs(mode_sigs),
	   .ax(ax),
	   .ay(ay),
	   .bx(bx),
	   .chainin(chainin),
	   .scanin(scanin),
	   .result(result),
	   .chainout(chainout),
	   .scanout(scanout)
	 );
   
	always @(posedge clk)begin
	   if(reset) begin
		 out_a<=0;
	   end
	   else begin  
		 out_a<=in_a;
	   end
	end
   
	assign out_b = scanout;
	assign out_c = result[`DWIDTH-1:0];
   
   `else
   
	input reset;
	input clk;
	input  [`DWIDTH-1:0] in_a;
	input  [`DWIDTH-1:0] in_b;
	output reg [`DWIDTH-1:0] out_a;
	output reg [`DWIDTH-1:0] out_b;
	output [`DWIDTH-1:0] out_c;  //reduced precision
   
	wire [`DWIDTH-1:0] out_mac;
   
	assign out_c = out_mac;
   
	seq_mac u_mac(.a(in_a), .b(in_b), .out(out_mac), .reset(reset), .clk(clk));
   
	always @(posedge clk)begin
	   if(reset) begin
		 out_a<=0;
		 out_b<=0;
	   end
	   else begin  
		 out_a<=in_a;
		 out_b<=in_b;
	   end
	end
   
   `endif
	
   endmodule
