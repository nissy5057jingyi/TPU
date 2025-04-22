module atpu_rtl_basic_dma64 (
    clk,
    rst,
    dma_read_chnl_valid,
    dma_read_chnl_data,
    dma_read_chnl_ready,
    /* <<--params-list-->> */
conf_info_reg8,
conf_info_reg9,
conf_info_reg4,
conf_info_reg5,
conf_info_reg6,
conf_info_reg7,
conf_info_reg0,
conf_info_reg1,
conf_info_reg2,
conf_info_reg3,
conf_info_reg10,
    conf_done,
    acc_done,
    debug,
    dma_read_ctrl_valid,
    dma_read_ctrl_data_index,
    dma_read_ctrl_data_length,
    dma_read_ctrl_data_size,
    dma_read_ctrl_data_user,
    dma_read_ctrl_ready,
    dma_write_ctrl_valid,
    dma_write_ctrl_data_index,
    dma_write_ctrl_data_length,
    dma_write_ctrl_data_size,
    dma_write_ctrl_data_user,
    dma_write_ctrl_ready,
    dma_write_chnl_valid,
    dma_write_chnl_data,
    dma_write_chnl_ready
);

    input clk;
    input rst;

    /* <<--params-def-->> */
   input [31:0]  conf_info_reg8;
   input [31:0]  conf_info_reg9;
   input [31:0]  conf_info_reg4;
   input [31:0]  conf_info_reg5;
   input [31:0]  conf_info_reg6;
   input [31:0]  conf_info_reg7;
   input [31:0]  conf_info_reg0;
   input [31:0]  conf_info_reg1;
   input [31:0]  conf_info_reg2;
   input [31:0]  conf_info_reg3;
   input [31:0]  conf_info_reg10;
    input conf_done;

    input dma_read_ctrl_ready;
    output dma_read_ctrl_valid;
    output [31:0] dma_read_ctrl_data_index;
    output [31:0] dma_read_ctrl_data_length;
    output [2:0] dma_read_ctrl_data_size;
    output [4:0] dma_read_ctrl_data_user;

    output dma_read_chnl_ready;
    input dma_read_chnl_valid;
    input [63:0] dma_read_chnl_data;

    input dma_write_ctrl_ready;
    output dma_write_ctrl_valid;
    output [31:0] dma_write_ctrl_data_index;
    output [31:0] dma_write_ctrl_data_length;
    output [2:0] dma_write_ctrl_data_size;
    output [4:0] dma_write_ctrl_data_user;

    input dma_write_chnl_ready;
    output dma_write_chnl_valid;
    output [63:0] dma_write_chnl_data;

    output acc_done;
    output [31:0] debug;

    reg acc_done;

    assign dma_read_ctrl_valid  = 1'b0;
    assign dma_read_chnl_ready  = 1'b1;
    assign dma_write_ctrl_valid = 1'b0;
    assign dma_write_chnl_valid = 1'b0;
    assign debug                = 32'd0;

    assign acc_done             = conf_done;

endmodule
