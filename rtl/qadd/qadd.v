module qadd(a,b,c);
`define DWIDTH 8

input signed [2*`DWIDTH-1:0] a;
input signed [2*`DWIDTH-1:0] b;
output signed [2*`DWIDTH-1:0] c;

assign c = a + b;
//DW01_add #(`DWIDTH) u_add(.A(a), .B(b), .CI(1'b0), .SUM(c), .CO());
endmodule
