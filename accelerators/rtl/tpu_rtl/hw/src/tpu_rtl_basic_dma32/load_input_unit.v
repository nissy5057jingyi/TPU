`timescale 1ns/1ps

module load_input_unit
#(
parameter ADDR_LEN = 64,
parameter ADDR_WIDTH = 5,
parameter DMA_DATA_WIDTH = 32,
parameter DATA_WIDTH = 8,
parameter BRAM_INDEX = 1,
parameter IN_WIDTH = 8,
parameter OUT_WIDTH = 16,
parameter DESIGN_SIZE = 16
)
(
  input wire clk,
  input wire rst,
  input wire start_load,
  output wire loading,
  input wire [95 : 0] conf_regs,
  output wire read_ctrl_valid,
  input wire read_ctrl_ready,
  output wire [66 : 0] read_ctrl_data,
  input wire read_chnl_valid,
  output wire read_chnl_ready,
  input wire [DMA_DATA_WIDTH-1 : 0] read_chnl_data,

  // BRAM output signals
  output wire [BRAM_INDEX+ADDR_WIDTH-1 : 0] mem_addr,
  output wire mem_data_valid,
  output wire [DMA_DATA_WIDTH-1 : 0] mem_data
);

  localparam IN_WORD_PER_DMA_BEAT = (DMA_DATA_WIDTH/IN_WIDTH) >> 1;
  localparam idle = 0;
  localparam snd_rd_req = 1;
  localparam wait_rd_rply = 2;
  localparam rd_data = 3;

  localparam NUM_BRAMS = 2;
  reg [3:0] state_reg;
  reg [3:0] state_next;

  wire [31:0] data_length;
  wire [2:0] data_size;

  reg [31:0] rcvd_data;
  reg increment_rcvd_data;

  reg dma_read_ctrl_valid_int;
  reg dma_read_chnl_ready_int;

  reg [31:0] dma_read_ctrl_data_index_int;
  reg [31:0] dma_read_ctrl_data_length_int;
  reg [2:0]  dma_read_ctrl_data_size_int;

  reg [DMA_DATA_WIDTH-1:0] dma_read_chnl_data_int;

  // Signals to write to systolic memory 
  reg loading_int;
  reg incr_bram_indx;
  reg incr_wr_addr;
  reg rst_wr_addr;

  // Systolic memory signals
  reg [BRAM_INDEX+ADDR_WIDTH-1 : 0] mem_addr_int;
  reg [ADDR_WIDTH-1 : 0] wr_addr;
  reg [BRAM_INDEX-1 : 0] bram_index;

  wire [2:0] op_mode;
  wire [7:0] matrix_size;
  wire [7:0] vector_size;
  wire [15:0] west_vec_size;
  
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
    if(rst == 1'b0)
      rcvd_data <= 0;
    else begin
      if (increment_rcvd_data == 1'b1)
        rcvd_data <= rcvd_data + 1;
    end
  end

  always @(posedge clk) begin
    if (rst == 1'b0) begin
      bram_index <= 0;
      wr_addr <= 0;
    end
    else begin 
      if (incr_bram_indx == 1'b1) begin
        if (bram_index == 1'b1)
          bram_index <= 1'b0;
        else
          bram_index <= bram_index + 1;
      end
      if (incr_wr_addr == 1'b1)
        wr_addr <= wr_addr + 1;
      if (rst_wr_addr == 1'b1)
        wr_addr <= 0;
    end
  end

  // Next state logic
  always @(*) begin
    dma_read_chnl_ready_int = 1'b0;
    dma_read_ctrl_valid_int = 1'b0;
    dma_read_ctrl_data_index_int = 0;
    dma_read_ctrl_data_length_int = 0;
    dma_read_ctrl_data_size_int = 0;
    dma_read_chnl_data_int = 0;
    increment_rcvd_data = 1'b0;
    loading_int = 1'b0;
    state_next = state_reg;

    case (state_reg)
      idle: begin
        if (start_load) begin
           state_next = snd_rd_req;
        end
      end

      snd_rd_req: begin
        dma_read_ctrl_valid_int = 1'b1;
        dma_read_ctrl_data_length_int = data_length;
        dma_read_ctrl_data_size_int = data_size;
        dma_read_ctrl_data_index_int = 0;
        if (read_ctrl_ready == 1'b1) begin
          state_next = wait_rd_rply;
        end
      end

      wait_rd_rply: begin
        dma_read_chnl_ready_int = 1'b1;
        if (read_chnl_valid == 1'b1) begin
          loading_int = 1'b1;
          dma_read_chnl_data_int = read_chnl_data;
          increment_rcvd_data = 1'b1;
          state_next = rd_data;
        end
      end

      rd_data: begin
        dma_read_chnl_ready_int = 1'b1;
        if (read_chnl_valid == 1'b1) begin
          loading_int = 1'b1;
          dma_read_chnl_data_int = read_chnl_data;
          increment_rcvd_data = 1'b1;
          if (rcvd_data == data_length - 1) begin
            state_next = idle;
          end
        end
      end
    endcase
  end
 
  always @(*) begin
    if (rst == 1'b0) begin
      mem_addr_int = 0;
      incr_bram_indx = 1'b0;
      incr_wr_addr = 1'b0;
      rst_wr_addr = 1'b0;
    end
    else if (loading == 1'b1) begin
      mem_addr_int = {bram_index, wr_addr};
      // op_mode mmul
      if (op_mode == 0 || op_mode == 1) begin
        incr_bram_indx = 1'b1;
        if (bram_index == NUM_BRAMS - 1)
          incr_wr_addr = 1'b1;
        else
          incr_wr_addr = 1'b0;
      end
      // op_mode vect-mat-mul
      else begin
        if (rcvd_data < west_vec_size - 1) begin
          incr_wr_addr = 1'b1;
          incr_bram_indx = 1'b0;
        end
        else if (rcvd_data == west_vec_size - 1) begin
          rst_wr_addr = 1'b1;
          incr_bram_indx = 1'b1;
        end
        else begin
          incr_bram_indx = 1'b0;
          rst_wr_addr = 1'b0;
          incr_wr_addr = 1'b1;
        end
      end
    end
    else begin
      incr_wr_addr = 1'b0;
      incr_bram_indx = 1'b0;
      mem_addr_int = 0;
      rst_wr_addr = 1'b0;
    end
  end

  assign read_ctrl_valid = dma_read_ctrl_valid_int;
  assign read_chnl_ready = dma_read_chnl_ready_int;
  assign read_ctrl_data = {dma_read_ctrl_data_size_int, dma_read_ctrl_data_length_int, dma_read_ctrl_data_index_int};
  assign data_length = conf_regs[31 : 0];
  assign loading = loading_int;
  assign data_size = 2'b01; // 32-bit

  assign matrix_size = conf_regs[39 : 32];
  assign vector_size = conf_regs[47 : 40];
  assign west_vec_size = (matrix_size * vector_size) >> IN_WORD_PER_DMA_BEAT;
  assign op_mode = 0;
  assign mem_data = dma_read_chnl_data_int;
  assign mem_data_valid = loading_int;
  assign mem_addr = mem_addr_int;
 
endmodule