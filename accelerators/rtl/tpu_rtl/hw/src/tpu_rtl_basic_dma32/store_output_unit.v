module store_output_unit
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

  input wire [95 : 0] conf_regs,
  // BRAM output signals
  input wire in_valid,
  output wire in_ready,
  output wire [ADDR_WIDTH-1 : 0] in_addr,
  input wire [DMA_DATA_WIDTH-1 : 0] in_data,

  output wire write_ctrl_valid,
  input wire write_ctrl_ready,
  output wire [66 : 0] write_ctrl_data,

  output wire write_chnl_valid,
  input wire write_chnl_ready,
  output wire [DMA_DATA_WIDTH-1 : 0] write_chnl_data,
  output done
);

  localparam idle = 0;
  localparam snd_wr_req = 1;
  localparam wr_data = 2;

  wire [31 : 0] out_data_length;
  wire [31 : 0] out_data_index;
  wire [1 : 0] out_data_size;

  reg [3:0] state_reg;
  reg [3:0] state_next;
  
  reg [31:0] snd_data;
  reg [ADDR_WIDTH-1 : 0] rd_addr_int;

  reg dma_write_chnl_valid_int;
  reg dma_write_ctrl_valid_int;
  reg [DMA_DATA_WIDTH-1 : 0] dma_write_chnl_data_int;
  reg [31 : 0] dma_write_ctrl_data_index_int;
  reg [31 : 0] dma_write_ctrl_data_length_int;
  reg [2 : 0] dma_write_ctrl_data_size_int;
  reg increment_snd_data;
  reg incr_rd_buff_addr;
  reg read_in_buff;
  reg done_int;

  // State register
  always @(posedge clk) begin
    if(rst == 1'b0) begin
      state_reg <= 0;
    end
    else begin
      state_reg <= state_next;
    end
  end

  always @(posedge clk) begin
    if(rst == 1'b0) begin
      snd_data <= 0;
      rd_addr_int <= 0;
    end
    else begin
      if (increment_snd_data == 1'b1) begin
        snd_data <= snd_data + 1;
      end
      if(incr_rd_buff_addr == 1'b1) begin
        rd_addr_int <= rd_addr_int + 1;
      end
    end
  end

  // Next state logic
  always @(*) begin
    dma_write_chnl_valid_int = 1'b0;
    dma_write_chnl_data_int = 0;
    dma_write_ctrl_valid_int = 1'b0;
    dma_write_ctrl_data_index_int = 32'h00000000;
    dma_write_ctrl_data_length_int = 32'h00000010;
    dma_write_ctrl_data_size_int = 2'b01;
    increment_snd_data = 1'b0;
    incr_rd_buff_addr = 1'b0;
    read_in_buff = 1'b0;
    done_int = 1'b0;
    state_next = state_reg;

    case (state_reg)
      idle: begin
        if (in_valid) begin
           state_next = snd_wr_req;
        end
      end

      snd_wr_req: begin
        dma_write_ctrl_valid_int = 1'b1;
        dma_write_ctrl_data_length_int = out_data_length;
        dma_write_ctrl_data_size_int = out_data_size;
        dma_write_ctrl_data_index_int = out_data_index;
        if (write_ctrl_ready == 1'b1) begin
          incr_rd_buff_addr = 1'b1;
          read_in_buff = 1'b1;
          state_next = wr_data;
        end
      end

      wr_data: begin
        dma_write_chnl_data_int = in_data;
        dma_write_chnl_valid_int = 1'b1;
        if (write_chnl_ready == 1'b1) begin
          if (in_valid == 1'b1) begin
            increment_snd_data = 1'b1;
            incr_rd_buff_addr = 1'b1;
            read_in_buff = 1'b1;
          end
        end 
        if (snd_data == out_data_length - 1) begin
            state_next = idle;
            done_int = 1'b1;
        end
      end
    endcase
  end

  assign write_ctrl_valid = dma_write_ctrl_valid_int;
  assign write_ctrl_data = {dma_write_ctrl_data_size_int, dma_write_ctrl_data_length_int, dma_write_ctrl_data_index_int};
  
  assign write_chnl_valid = dma_write_chnl_valid_int;
  assign write_chnl_data = dma_write_chnl_data_int;

  assign out_data_length = conf_regs[95 : 64];
  assign out_data_index = conf_regs[31 : 0];
  assign out_data_size = 2'b01; // 32-bit

  assign in_ready = read_in_buff;
  assign in_addr = rd_addr_int;
  assign done = done_int;

endmodule