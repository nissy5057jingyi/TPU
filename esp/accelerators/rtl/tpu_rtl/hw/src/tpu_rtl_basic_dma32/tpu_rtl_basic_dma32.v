module tpu_rtl_basic_dma32 (
    clk,
    rst,
    dma_read_chnl_valid,
    dma_read_chnl_data,
    dma_read_chnl_ready,
    data_in_reg,        // Specifies number of input elements
    data_out_reg,       // Specifies number of output elements
    activation_reg,     // Selects activation function (ReLU/TanH)
    pooling_reg,        // Configures pooling operation (1x1, 2x2, 4x4)
    norm_reg,           // Enables and configures normalization mode
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

    // Configuration registers with descriptive names
    input [31:0]  data_in_reg;      // Specifies number of input elements
    input [31:0]  data_out_reg;     // Specifies number of output elements
    input [31:0]  activation_reg;   // Selects activation function (ReLU/TanH)
    input [31:0]  pooling_reg;      // Configures pooling operation (1x1, 2x2, 4x4)
    input [31:0]  norm_reg;         // Enables and configures normalization mode
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
    wire read_ctrl_valid;
    wire [66:0] write_ctrl_data;
    wire write_ctrl_valid;
    
    // Memory interface signals
    parameter AWIDTH = 5;
    parameter DWIDTH = 8;
    parameter DESIGN_SIZE = 16;
    parameter BRAM_INDEX = 1;
    parameter ADDR_WIDTH = 5;
    
    wire [AWIDTH-1:0] bram_addr_a;
    wire [DESIGN_SIZE*DWIDTH-1:0] bram_rdata_a;
    wire [DESIGN_SIZE*DWIDTH-1:0] bram_wdata_a;
    wire [DESIGN_SIZE-1:0] bram_we_a;
    wire [AWIDTH-1:0] bram_addr_b;
    wire [DESIGN_SIZE*DWIDTH-1:0] bram_rdata_b;
    wire [DESIGN_SIZE*DWIDTH-1:0] bram_wdata_b;
    wire [DESIGN_SIZE-1:0] bram_we_b;
    
    // Connection between modules
    wire [BRAM_INDEX+ADDR_WIDTH-1:0] systolic_mem_addr;
    wire systolic_mem_valid;
    wire [31:0] systolic_mem_data;
    
    wire systolic_1_valid;
    wire systolic_1_read;
    wire [31:0] systolic_1_data;
    wire [ADDR_WIDTH-1:0] systolic_1_addr;
    
    wire systolic_2_valid;
    wire systolic_2_read;
    wire [31:0] systolic_2_data;
    wire [ADDR_WIDTH-1:0] systolic_2_addr;
    
    wire [ADDR_WIDTH-1:0] out_mem_addr;
    wire out_mem_valid;
    wire [31:0] out_mem_data;
    
    wire store_valid;
    wire store_ready;
    wire [31:0] store_data;
    wire [ADDR_WIDTH-1:0] store_addr;
    
    // APB interface signals
    wire [31:0] PADDR;
    wire [31:0] PWDATA;
    wire PWRITE;
    wire PSEL;
    wire PENABLE;
    wire [31:0] PRDATA;
    wire PREADY;
    
    // State machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
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
    
    // Instantiate load_input_unit
    load_input_unit #(
        .ADDR_LEN(64),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DMA_DATA_WIDTH(32),
        .DATA_WIDTH(DWIDTH),
        .BRAM_INDEX(BRAM_INDEX),
        .IN_WIDTH(DWIDTH),
        .OUT_WIDTH(DWIDTH*2),
        .DESIGN_SIZE(DESIGN_SIZE)
    ) load_input_inst (
        .clk(clk),
        .rst(rst),
        .start_load(start_load),
        .loading(loading),
        .conf_regs({activation_reg, data_out_reg, data_in_reg}),  
        .read_ctrl_valid(read_ctrl_valid),
        .read_ctrl_ready(dma_read_ctrl_ready),
        .read_ctrl_data(read_ctrl_data),
        .read_chnl_valid(dma_read_chnl_valid),
        .read_chnl_ready(dma_read_chnl_ready),
        .read_chnl_data(dma_read_chnl_data),
        .mem_addr(systolic_mem_addr),
        .mem_data_valid(systolic_mem_valid),
        .mem_data(systolic_mem_data)
    );
    
    // Instantiate systolic_in_buff
    systolic_in_buff #(
        .ADDR_LEN(64),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DMA_DATA_WIDTH(32),
        .DATA_WIDTH(DWIDTH),
        .BRAM_INDEX(BRAM_INDEX),
        .DESIGN_SIZE(DESIGN_SIZE)
    ) systolic_in_buff_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(systolic_mem_valid),
        .in_ready(), 
        .in_addr(systolic_mem_addr),
        .in_data(systolic_mem_data),
        .out1_valid(systolic_1_valid),
        .out1_ready(1'b1),  
        .out1_addr(systolic_1_addr),
        .out1_data(systolic_1_data),
        .out2_valid(systolic_2_valid),
        .out2_ready(1'b1),  
        .out2_addr(systolic_2_addr),
        .out2_data(systolic_2_data)
    );
    
    // Port A multiplexing
    reg [AWIDTH-1:0] bram_addr_a_mux;
    reg [DESIGN_SIZE*DWIDTH-1:0] bram_wdata_a_mux;
    reg [DESIGN_SIZE-1:0] bram_we_a_mux;
    
    always @(*) begin
        if (loading) begin
            bram_addr_a_mux = {{(AWIDTH-ADDR_WIDTH){1'b0}}, systolic_1_addr};
            bram_wdata_a_mux = {{(DESIGN_SIZE-1)*DWIDTH{1'b0}}, systolic_1_data};
            bram_we_a_mux = {DESIGN_SIZE{systolic_1_valid}};
        end else begin
            bram_addr_a_mux = {{(AWIDTH-ADDR_WIDTH){1'b0}}, store_addr};
            bram_wdata_a_mux = {DESIGN_SIZE*DWIDTH{1'b0}};
            bram_we_a_mux = {DESIGN_SIZE{1'b0}};
        end
    end
    
    // Port B multiplexing
    reg [AWIDTH-1:0] bram_addr_b_mux;
    reg [DESIGN_SIZE*DWIDTH-1:0] bram_wdata_b_mux;
    reg [DESIGN_SIZE-1:0] bram_we_b_mux;
    
    always @(*) begin
        if (loading) begin
            bram_addr_b_mux = {{(AWIDTH-ADDR_WIDTH){1'b0}}, systolic_2_addr};
            bram_wdata_b_mux = {{(DESIGN_SIZE-1)*DWIDTH{1'b0}}, systolic_2_data};
            bram_we_b_mux = {DESIGN_SIZE{systolic_2_valid}};
        end else begin
            bram_addr_b_mux = {{(AWIDTH-ADDR_WIDTH){1'b0}}, out_mem_addr};
            bram_wdata_b_mux = {DESIGN_SIZE*DWIDTH{1'b0}};
            bram_we_b_mux = {DESIGN_SIZE{1'b0}};
        end
    end

    // Instantiate esp_tpu_controller
    esp_tpu_controller #(
        .REG_ADDRWIDTH(8),
        .REG_DATAWIDTH(32)
    ) esp_tpu_controller_inst (
        .clk(clk),
        .rst_n(~rst), 
        .data_in_reg(data_in_reg),       
        .data_out_reg(data_out_reg),       
        .activation_reg(activation_reg),     
        .pooling_reg(pooling_reg),        
        .norm_reg(norm_reg),           
        .reg_addr(8'h0),          
        .reg_write_en(1'b0),      
        .reg_read_en(1'b0),       
        .reg_read_data(),         
        .done_tpu_from_hw(done_tpu),
        .PCLK(clk),
        .PRESETn(~rst),
        .PADDR(PADDR[7:0]),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY)
    );
    
    // Instantiate tpu_top
    tpu_top tpu_top_inst (
        .clk(clk),
        .clk_mem(clk),
        .reset(rst),
        .resetn(~rst),
        .PADDR(PADDR[7:0]),
        .PWRITE(PWRITE),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .bram_addr_a_ext(bram_addr_a_mux),
        .bram_rdata_a_ext(bram_rdata_a),
        .bram_wdata_a_ext(bram_wdata_a_mux),
        .bram_we_a_ext(bram_we_a_mux),
        .bram_addr_b_ext(bram_addr_b_mux),
        .bram_rdata_b_ext(bram_rdata_b),
        .bram_wdata_b_ext(bram_wdata_b_mux),
        .bram_we_b_ext(bram_we_b_mux)
    );
    
    // Instantiate systolic_out_buff
    systolic_out_buff #(
        .ADDR_LEN(64),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DMA_DATA_WIDTH(32),
        .DATA_WIDTH(DWIDTH),
        .BRAM_INDEX(BRAM_INDEX),
        .DESIGN_SIZE(DESIGN_SIZE)
    ) systolic_out_buff_inst (
        .clk(clk),
        .rst(rst),
        .in_valid(out_mem_valid),
        .in_ready(),  
        .in_addr(out_mem_addr),
        .in_data(out_mem_data),
        .out_valid(store_valid),
        .out_ready(store_ready),
        .out_addr(store_addr),
        .out_data(store_data)
    );
    
    // Instantiate store_output_unit
    store_output_unit #(
        .ADDR_LEN(64),
        .ADDR_WIDTH(ADDR_WIDTH),
        .DMA_DATA_WIDTH(32),
        .DATA_WIDTH(DWIDTH),
        .BRAM_INDEX(BRAM_INDEX),
        .DESIGN_SIZE(DESIGN_SIZE)
    ) store_output_inst (
        .clk(clk),
        .rst(rst),
        .conf_regs({pooling_reg, norm_reg, data_out_reg}), 
        .in_valid(store_valid),
        .in_ready(store_ready),
        .in_addr(store_addr),
        .in_data(store_data),
        .write_ctrl_valid(write_ctrl_valid),
        .write_ctrl_ready(dma_write_ctrl_ready),
        .write_ctrl_data(write_ctrl_data),
        .write_chnl_valid(dma_write_chnl_valid),
        .write_chnl_ready(dma_write_chnl_ready),
        .write_chnl_data(dma_write_chnl_data),
        .done(done_tpu)
    );
    
    // DMA control signals assignment
    assign dma_read_ctrl_valid = read_ctrl_valid;
    assign dma_read_ctrl_data_size = read_ctrl_data[66:64];
    assign dma_read_ctrl_data_length = read_ctrl_data[63:32];
    assign dma_read_ctrl_data_index = read_ctrl_data[31:0];
    assign dma_read_ctrl_data_user = 5'b0; 
    
    assign dma_write_ctrl_valid = write_ctrl_valid;
    assign dma_write_ctrl_data_size = write_ctrl_data[66:64];
    assign dma_write_ctrl_data_length = write_ctrl_data[63:32];
    assign dma_write_ctrl_data_index = write_ctrl_data[31:0];
    assign dma_write_ctrl_data_user = 5'b0;
    
    // Final output assignments
    assign acc_done = acc_done_reg;
    assign debug = {28'h0, state};

endmodule