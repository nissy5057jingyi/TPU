`timescale 1ns/1ps

module systolic_out_buff
#(
parameter ADDR_LEN = 64,
parameter ADDR_WIDTH = 5,
parameter DMA_DATA_WIDTH = 32,
parameter DATA_WIDTH = 8,
parameter BRAM_INDEX = 1,
parameter DESIGN_SIZE = 16
)
(
  input wire clk,
  input wire rst,
  input wire in_valid,
  output wire in_ready,
  input wire [ADDR_WIDTH-1 : 0] in_addr,
  input wire [DMA_DATA_WIDTH-1 : 0] in_data,
  output wire out_valid,
  input wire out_ready,
  input wire [ADDR_WIDTH-1 : 0] out_addr,
  output wire [DMA_DATA_WIDTH-1 : 0] out_data
);

  reg we_1;
  reg re_1;
  wire [4 : 0] buff_in_addr;
  wire [4 : 0] buff_out_addr;

  reg [ADDR_WIDTH-1 : 0] buff_1_size;

  dpram_mem_core mem_out (.clk(clk), .wen(we_1), .waddr(buff_in_addr), .d_in(in_data),
                          .ren(re_1), .raddr(buff_out_addr), .d_out(out_data));

  always @(posedge clk) begin
    if (rst == 1'b0) begin
      buff_1_size <= 0;
    end
    else begin
      if (we_1 == 1'b1 && re_1 == 1'b0)
        buff_1_size <= buff_1_size + 1;
      else if (we_1 == 1'b0 && re_1 == 1'b1 && buff_1_size > 0)
        buff_1_size <= buff_1_size - 1;
    end
  end

  always @(*) begin
    if (rst == 1'b0) begin
      we_1 = 1'b0;
    end
    else begin
      if (in_valid == 1'b1)
        we_1 = 1'b1; 
      else
        we_1 = 1'b0;
    end
  end

  always @(*) begin
    if (rst == 1'b0) begin
      re_1 = 1'b0;
    end
    else begin
      if (out_ready == 1'b1)
        re_1 = 1'b1;
      else
        re_1 = 1'b0;
    end
  end

  assign out_valid = (buff_1_size > 0) ? 1'b1 : 1'b0;
  assign in_ready = 1'b1; // Always ready to accept input

  assign buff_in_addr = {{(5-ADDR_WIDTH){1'b0}}, in_addr};
  assign buff_out_addr = {{(5-ADDR_WIDTH){1'b0}}, out_addr};
  
endmodule