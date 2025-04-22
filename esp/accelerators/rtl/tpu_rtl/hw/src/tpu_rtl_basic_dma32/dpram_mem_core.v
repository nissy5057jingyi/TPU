module dpram_mem_core (
    input clk,
    input wen,
    input ren,
    input[0:4] waddr,
    input[0:4] raddr,
    input[0:31] d_in,
    output[0:31] d_out
);

  dpram memory (
    .wclk(clk),
    .wen(wen),
    .waddr(waddr),
    .data_in(d_in),
    .rclk(clk),
    .ren(ren),
    .raddr(raddr),
    .d_out(d_out)
  );

endmodule

module dpram (
    input wclk,
    input wen,
    input[0:4] waddr,
    input[0:31] data_in,
    input rclk,
    input ren,
    input[0:4] raddr,
    output[0:31] d_out
);

    reg[0:31] ram[0:31];
    reg[0:31] internal;

    assign d_out = internal;

    always @(posedge wclk) begin
        if(wen) begin
            ram[waddr] <= data_in;
        end
    end

    always @(posedge rclk) begin
        if(ren) begin
            internal <= ram[raddr];
        end
    end

endmodule