module systolic_in_buff
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
  input wire [BRAM_INDEX+ADDR_WIDTH-1 : 0] in_addr,
  input wire [DMA_DATA_WIDTH-1 : 0] in_data,
  output wire out1_valid,
  input wire out1_ready,
  input wire [4 : 0] out1_addr,
  output wire [DMA_DATA_WIDTH-1 : 0] out1_data,
  output wire out2_valid,
  input wire out2_ready,
  input wire [4: 0] out2_addr,
  output wire [DMA_DATA_WIDTH-1 : 0] out2_data
);

  reg we_1;
  reg we_2;
  reg re_1;
  reg re_2;

  wire [BRAM_INDEX-1 : 0] bram_sel;
  reg [ADDR_WIDTH-1 : 0] buff_1_size;
  reg [ADDR_WIDTH-1 : 0] buff_2_size;
  wire [4 : 0] buff_addr;

  wire full_1;
  wire full_2;
  wire empty_1;
  wire empty_2;

  wire out_1_valid_int;
  wire out_2_valid_int;
 
  wire [DMA_DATA_WIDTH-1 : 0] out_1_data_int;
  wire [DMA_DATA_WIDTH-1 : 0] out_2_data_int;
  
  // Fracturable mem with 2 write and 2 read ports
  // In systolic mode: (a) single write port to transfer inputs from DMA --> mem
  //                  : (b) two read ports to transfer from mem --> Tile North and west
  dpram_mem_core mem_west (.clk(clk), .wen(we_1), .waddr(buff_addr), .d_in(in_data),
                  .ren(re_1), .raddr(out1_addr), .d_out(out1_data));

  dpram_mem_core mem_north (.clk(clk), .wen(we_2), .waddr(buff_addr), .d_in(in_data),
                  .ren(re_2), .raddr(out2_addr), .d_out(out2_data));

  always @(posedge clk) begin
    if (rst == 1'b0) begin
      buff_1_size <= 0;
      buff_2_size <= 0;
    end
    else begin
      if (we_1 == 1'b1 && re_1 == 1'b0)
        buff_1_size <= buff_1_size + 1;
      else if (we_1 == 1'b0 && re_1 == 1'b1 && buff_1_size > 0)
        buff_1_size <= buff_1_size - 1;
      if (we_2 == 1'b1 && re_2 == 1'b0)
        buff_2_size <= buff_2_size + 1;
      else if (we_2 == 1'b0 && re_2 == 1'b1 && buff_2_size > 0)
        buff_2_size <= buff_2_size - 1;
    end
  end

  always @(*) begin
    if (rst == 1'b0) begin
      we_1 = 1'b0;
      we_2 = 1'b0;
    end
    else begin
      we_1 = 1'b0;
      we_2 = 1'b0;
      if (in_valid == 1'b1) begin
        if (bram_sel == 0) begin
          we_1 = 1'b1;
          we_2 = 1'b0;
        end
        if (bram_sel == 1) begin
          we_1 = 1'b0;
          we_2 = 1'b1;
        end
      end
      else begin
        we_1 = 1'b0;
        we_2 = 1'b0;
      end
    end
  end 

  always @(*) begin
    if (rst == 1'b0) begin
      re_1 = 1'b0;
      re_2 = 1'b0;
    end
    else begin
      if (out1_ready == 1'b1)
        re_1 = 1'b1;
      else
        re_1 = 1'b0;
      if (out2_ready == 1'b1)
        re_2 = 1'b1;
      else
        re_2 = 1'b0;
    end
  end

  assign out1_valid = (buff_1_size > 0) ? 1'b1 : 1'b0;
  assign out2_valid = (buff_2_size > 0) ? 1'b1 : 1'b0;

  assign bram_sel = in_addr[BRAM_INDEX+ADDR_WIDTH-1 -: BRAM_INDEX];
  assign buff_addr = {{(5-ADDR_WIDTH){1'b0}}, in_addr[ADDR_WIDTH-1:0]};
  assign in_ready = 1'b1; // Always ready to accept input
  
endmodule