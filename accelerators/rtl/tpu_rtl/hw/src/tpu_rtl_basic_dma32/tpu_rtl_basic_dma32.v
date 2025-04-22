//////////////////////////////////////
// Overview
//////////////////////////////////////
// atpu_rtl_basic_dma32     (Top-level DMA interface module)
// |--- load_input_unit     (DMA input interface)
// |--- store_output_unit   (DMA output interface)
// |--- systolic_in_buff    (Local memory buffer for input)
// |    |--- dpram_mem_core (Dual-port RAM wrapper)
// |         |--- dpram     (Dual-port RAM implementation)
// |--- systolic_out_buff   (Local memory buffer for output)
// |    |--- dpram_mem_core (Dual-port RAM wrapper)
// |         |--- dpram     (Dual-port RAM implementation)
// |--- tpu_top            (TPU top-level design)
//     |--- ram            matrix_A    (Stores activations matrix)
//     |--- ram            matrix_B    (Stores weights matrix)
//     |--- control        u_control   (Controls TPU operation state machine)
//     |--- cfg            u_cfg       (Configures/observes registers using APB interface)
//     |--- matmul_16x16_systolic u_matmul    (Systolic 16x16 matrix multiplication unit)
//     |    |--- output_logic                 (Shifts out matrix multiplication results)
//     |    |--- systolic_data_setup          (Shifts in matrix multiplication inputs)
//     |    |--- systolic_pe_matrix           (16x16 matrix of processing elements)
//     |         |--- processing_element      (Individual PE in the array)
//     |              |--- seq_mac            (MAC block inside each PE)
//     |                   |--- qmult         (Multiplier inside each MAC)
//     |                   |--- qadd          (Adder inside each MAC)
//     |--- norm           u_norm      (Normalizes data using mean and variance)
//     |--- pool           u_pool      (Performs pooling operations)
//     |--- activation     u_activation(Applies activation functions - ReLU/TanH)
module atpu_rtl_basic_dma32 (
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
    input         conf_done;

    input         dma_read_ctrl_ready;
    output        dma_read_ctrl_valid;
    output [31:0] dma_read_ctrl_data_index;
    output [31:0] dma_read_ctrl_data_length;
    output [2:0]  dma_read_ctrl_data_size;
    output [4:0]  dma_read_ctrl_data_user;

    output        dma_read_chnl_ready;
    input         dma_read_chnl_valid;
    input [31:0]  dma_read_chnl_data;

    input         dma_write_ctrl_ready;
    output        dma_write_ctrl_valid;
    output [31:0] dma_write_ctrl_data_index;
    output [31:0] dma_write_ctrl_data_length;
    output [2:0]  dma_write_ctrl_data_size;
    output [4:0]  dma_write_ctrl_data_user;

    input         dma_write_chnl_ready;
    output        dma_write_chnl_valid;
    output [31:0] dma_write_chnl_data;

    output        acc_done;
    output [31:0] debug;

    // State definitions
    localparam IDLE = 0;
    localparam INIT_LOAD = 1;
    localparam WAIT_FOR_COMPLETION = 2;
    localparam DONE = 3;
    
    // State registers
    reg [2:0] state;
    reg [2:0] next_state;
    
    // Control signals
    reg start_tpu_reg;
    wire done_tpu;
    reg acc_done_reg;
    reg start_load;
    wire loading;
    
    // DMA interface signals
    wire [66:0] read_ctrl_data;
    wire [66:0] write_ctrl_data;
    
    // Memory interface signals
    wire [`AWIDTH-1:0] bram_addr_a;
    wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_rdata_a;
    wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_wdata_a;
    wire [`DESIGN_SIZE-1:0] bram_we_a;
    wire [`AWIDTH-1:0] bram_addr_b;
    wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_rdata_b;
    wire [`DESIGN_SIZE*`DWIDTH-1:0] bram_wdata_b;
    wire [`DESIGN_SIZE-1:0] bram_we_b;
    
    // Connection between modules
    wire [`BRAM_INDEX+`ADDR_WIDTH-1:0] systolic_mem_addr;
    wire systolic_mem_valid;
    wire [31:0] systolic_mem_data;
    
    wire systolic_1_valid;
    wire systolic_1_read;
    wire [31:0] systolic_1_data;
    wire [`ADDR_WIDTH-1:0] systolic_1_addr;
    
    wire systolic_2_valid;
    wire systolic_2_read;
    wire [31:0] systolic_2_data;
    wire [`ADDR_WIDTH-1:0] systolic_2_addr;
    
    wire [`ADDR_WIDTH-1:0] out_mem_addr;
    wire out_mem_valid;
    wire [31:0] out_mem_data;
    
    wire store_valid;
    wire store_ready;
    wire [31:0] store_data;
    wire [`ADDR_WIDTH-1:0] store_addr;
    
    // Configuration registers for TPU
    wire [95:0] tpu_conf_regs;
    assign tpu_conf_regs = {conf_info_reg2, conf_info_reg1, conf_info_reg0};
    
    // State machine
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end
    
    always @(*) begin
        next_state = state;
        start_tpu_reg = 1'b0;
        acc_done_reg = 1'b0;
        start_load = 1'b0;
        
        case (state)
            IDLE: begin
                if (conf_done) begin
                    next_state = INIT_LOAD;
                end
            end
            
            INIT_LOAD: begin
                start_load = 1'b1;
                if (loading) begin
                    start_tpu_reg = 1'b1;
                    next_state = WAIT_FOR_COMPLETION;
                end
            end
            
            WAIT_FOR_COMPLETION: begin
                if (done_tpu) begin
                    next_state = DONE;
                    acc_done_reg = 1'b1;
                end
            end
            
            DONE: begin
                if (!conf_done) begin
                    next_state = IDLE;
                    acc_done_reg = 1'b0;
                end else begin
                    acc_done_reg = 1'b1;
                end
            end
        endcase
    end
    
    // Load input unit
    load_input_unit #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DMA_DATA_WIDTH(32),
        .BRAM_INDEX(`BRAM_INDEX)
    ) load_unit_inst (
        .clk(clk),
        .rst(rst),
        .start_load(start_load),
        .loading(loading),
        .conf_regs(tpu_conf_regs),
        .read_ctrl_valid(dma_read_ctrl_valid),
        .read_ctrl_ready(dma_read_ctrl_ready),
        .read_ctrl_data(read_ctrl_data),
        .read_chnl_valid(dma_read_chnl_valid),
        .read_chnl_ready(dma_read_chnl_ready),
        .read_chnl_data(dma_read_chnl_data),
        .mem_addr(systolic_mem_addr),
        .mem_data_valid(systolic_mem_valid),
        .mem_data(systolic_mem_data)
    );
    
    // Input buffer
    systolic_in_buff #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DMA_DATA_WIDTH(32),
        .BRAM_INDEX(`BRAM_INDEX)
    ) in_buff_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(systolic_mem_valid),
        .in_addr(systolic_mem_addr),
        .in_data(systolic_mem_data),
        .out1_valid(systolic_1_valid),
        .out1_ready(systolic_1_read),
        .out1_data(systolic_1_data),
        .out1_addr(systolic_1_addr),
        .out2_valid(systolic_2_valid),
        .out2_ready(systolic_2_read),
        .out2_data(systolic_2_data),
        .out2_addr(systolic_2_addr)
    );
    
    // TPU Core
    tpu_top u_tpu_top (
        .clk(clk),
        .rst(rst),
        .start_tpu(start_tpu_reg),
        .conf_info_reg0(conf_info_reg0),
        .conf_info_reg1(conf_info_reg1),
        .conf_info_reg2(conf_info_reg2),
        .conf_info_reg3(conf_info_reg3),
        .conf_info_reg4(conf_info_reg4),
        .bram_addr_a(bram_addr_a),
        .bram_rdata_a(bram_rdata_a),
        .bram_wdata_a(bram_wdata_a),
        .bram_we_a(bram_we_a),
        .bram_addr_b(bram_addr_b),
        .bram_rdata_b(bram_rdata_b),
        .bram_wdata_b(bram_wdata_b),
        .bram_we_b(bram_we_b),
        .done_tpu(done_tpu),
        .input_data(systolic_1_data),
        .input_data_valid(systolic_1_valid),
        .input_data_ready(systolic_1_read),
        .output_data(out_mem_data),
        .output_data_valid(out_mem_valid),
        .output_data_ready(1'b1)
    );
    
    // Output buffer
    systolic_out_buff #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DMA_DATA_WIDTH(32)
    ) out_buff_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(out_mem_valid),
        .in_addr(out_mem_addr),
        .in_data(out_mem_data),
        .out_valid(store_valid),
        .out_ready(store_ready),
        .out_addr(store_addr),
        .out_data(store_data)
    );
    
    // Store output unit
    store_output_unit #(
        .ADDR_WIDTH(`ADDR_WIDTH),
        .DMA_DATA_WIDTH(32)
    ) store_unit_inst (
        .clk(clk),
        .rst(rst),
        .conf_regs(tpu_conf_regs),
        .in_valid(store_valid),
        .in_ready(store_ready),
        .in_addr(store_addr),
        .in_data(store_data),
        .write_ctrl_ready(dma_write_ctrl_ready),
        .write_ctrl_valid(dma_write_ctrl_valid),
        .write_ctrl_data(write_ctrl_data),
        .write_chnl_ready(dma_write_chnl_ready),
        .write_chnl_valid(dma_write_chnl_valid),
        .write_chnl_data(dma_write_chnl_data),
        .done(done_store)
    );

    // DMA control signals
    assign dma_read_ctrl_data_size = read_ctrl_data[66:64];
    assign dma_read_ctrl_data_length = read_ctrl_data[63:32];
    assign dma_read_ctrl_data_index = read_ctrl_data[31:0];
    assign dma_read_ctrl_data_user = 5'b0; // Not used
    
    assign dma_write_ctrl_data_size = write_ctrl_data[66:64];
    assign dma_write_ctrl_data_length = write_ctrl_data[63:32];
    assign dma_write_ctrl_data_index = write_ctrl_data[31:0];
    assign dma_write_ctrl_data_user = 5'b0; // Not used
    
    // Final outputs
    assign acc_done = acc_done_reg;
    assign debug = {28'h0, state};

endmodule