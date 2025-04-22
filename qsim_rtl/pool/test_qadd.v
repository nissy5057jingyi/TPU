`timescale 1ns / 1ps

module tb_qadd;


    parameter DWIDTH = 8;
    

    reg signed [2*DWIDTH-1:0] a;
    reg signed [2*DWIDTH-1:0] b;
    wire signed [2*DWIDTH-1:0] c;


    qadd uut (
        .a(a),
        .b(b),
        .c(c)
    );


    initial begin
        
        $display("Time\t a\t + b\t = c");
        $monitor("%0t\t %h\t + %h\t = %h", $time, a, b, c);

        
        repeat (10) begin
            a = $random % (1 << (2*DWIDTH-3)); // 
            b = $random % (1 << (2*DWIDTH-3)); // 
            #10; 
        end

        // end simulation
        #10;
        $finish;
    end

endmodule

