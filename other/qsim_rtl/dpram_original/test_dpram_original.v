`timescale 1ns / 1ps

module tb_dpram_original;

    parameter AWIDTH = 10;
    parameter DESIGN_SIZE = 16;
	parameter DWIDTH = 8;


	reg clk;
	reg [AWIDTH-1:0] address_a;
	reg [AWIDTH-1:0] address_b;
	reg wren_a;
	reg wren_b;
	reg [(DWIDTH-1):0] data_a;
	reg [(DWIDTH-1):0] data_b;
	wire [(DWIDTH-1):0] out_a;
	wire [(DWIDTH-1):0] out_b;

	integer i;
	integer file;

	reg [AWIDTH-1:0] write_addr [0:29];
	reg [AWIDTH-1:0] read_addr [0:29];
	reg [(DWIDTH-1):0] write_data_a [0:29];
	reg [(DWIDTH-1):0] write_data_b [0:29];

	dpram_original uut (
        .clk(clk),
        .address_a(address_a),
        .address_b(address_b),
		.wren_a(wren_a),
		.wren_b(wren_b),
		.data_a(data_a),
		.data_b(data_b),
		.out_a(out_a),
		.out_b(out_b)
    );

	always begin
		#5 clk = ~clk;
	end

	initial begin
		clk = 0;
		file = $fopen("ram_test_report.rpt", "w");
		
		// Step 1: Write data to RAM
		for (i = 0; i < 30; i = i + 1) begin
			write_addr[i] = $random % 1024; // Random address
			read_addr[i] = write_addr[i];  // Read address must match write address
			write_data_a[i] = $random % 128; // Small data to avoid large values
			write_data_b[i] = $random % 128;

			address_a = write_addr[i];
			address_b = write_addr[i] + 1; // Avoid completely identical addresses
			data_a = write_data_a[i];
			data_b = write_data_b[i];
			wren_a = 1;
			wren_b = 1;

			#10; // Wait one clock cycle

			$fwrite(file, "[Cycle %0d] Write: Addr A = %0d, Data A = %0d | Addr B = %0d, Data B = %0d\n",
			       i, address_a, data_a, address_b, data_b);
		end

		// Disable write
		wren_a = 0;
		wren_b = 0;

		// Step 2: Read data from RAM and compare
		for (i = 0; i < 30; i = i + 1) begin
			address_a = read_addr[i];
			address_b = read_addr[i] + 1;

			#10; // Wait one clock cycle

			if (out_a == write_data_a[i] && out_b == write_data_b[i]) begin
				$fwrite(file, "[Cycle %0d] Read Correct: Addr A = %0d, Data A = %0d | Addr B = %0d, Data B = %0d\n",
				       i, address_a, out_a, address_b, out_b);
			end else begin
				$fwrite(file, "[Cycle %0d] Read Error  : Addr A = %0d, Data A = %0d (Expected %0d) | Addr B = %0d, Data B = %0d (Expected %0d)\n",
				       i, address_a, out_a, write_data_a[i], address_b, out_b, write_data_b[i]);
			end
		end

		$fclose(file);
		$finish;
	end

endmodule
