// Complete alternative implementation of memory_copier_rtl_basic_dma32.v
// This version uses parameter instead of localparam and a different approach to state handling

module memory_copier_rtl_basic_dma32 (
    clk,
    rst,
    dma_read_chnl_valid,
    dma_read_chnl_data,
    dma_read_chnl_ready,
    /* <<--params-list-->> */
    conf_info_data_in,
    conf_info_enable,
    conf_info_data_out,
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
    input [31:0]  conf_info_data_in;
    input [31:0]  conf_info_enable;
    input [31:0]  conf_info_data_out;
    input conf_done;

    input dma_read_ctrl_ready;
    output dma_read_ctrl_valid;
    output [31:0] dma_read_ctrl_data_index;
    output [31:0] dma_read_ctrl_data_length;
    output [2:0] dma_read_ctrl_data_size;
    output [4:0] dma_read_ctrl_data_user;

    output dma_read_chnl_ready;
    input dma_read_chnl_valid;
    input [31:0] dma_read_chnl_data;

    input dma_write_ctrl_ready;
    output dma_write_ctrl_valid;
    output [31:0] dma_write_ctrl_data_index;
    output [31:0] dma_write_ctrl_data_length;
    output [2:0] dma_write_ctrl_data_size;
    output [4:0] dma_write_ctrl_data_user;

    input dma_write_chnl_ready;
    output dma_write_chnl_valid;
    output [31:0] dma_write_chnl_data;

    output acc_done;
    output [31:0] debug;

    // Using parameter instead of localparam - Parameters are visible across module hierarchy
    parameter STATE_IDLE = 3'd0;
    parameter STATE_INIT_READ = 3'd1;
    parameter STATE_READING = 3'd2;
    parameter STATE_INIT_WRITE = 3'd3;
    parameter STATE_WRITING = 3'd4;
    parameter STATE_DONE = 3'd5;

    // DMA size encodings
    parameter BYTE = 3'b000;   // 8-bit
    parameter HWORD = 3'b001;  // 16-bit
    parameter WORD = 3'b010;   // 32-bit
    parameter DWORD = 3'b011;  // 64-bit

    // Register declarations
    reg [2:0] state;
    reg [31:0] buffer [0:2047];  // Buffer for 32-bit data
    reg [31:0] read_count;
    reg [31:0] write_count;
    reg [31:0] total_elements;
    reg acc_done;
    reg dma_read_ctrl_valid;
    reg dma_read_chnl_ready;
    reg dma_write_ctrl_valid;
    reg dma_write_chnl_valid;
    reg [31:0] dma_write_chnl_data;
    reg [31:0] dma_read_ctrl_data_index;
    reg [31:0] dma_read_ctrl_data_length;
    reg [2:0] dma_read_ctrl_data_size;
    reg [4:0] dma_read_ctrl_data_user;
    reg [31:0] dma_write_ctrl_data_index;
    reg [31:0] dma_write_ctrl_data_length;
    reg [2:0] dma_write_ctrl_data_size;
    reg [4:0] dma_write_ctrl_data_user;
    reg [31:0] debug;

    // Main FSM
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            // Reset state
            state <= STATE_IDLE;
            dma_read_ctrl_valid <= 1'b0;
            dma_read_chnl_ready <= 1'b0;
            dma_write_ctrl_valid <= 1'b0;
            dma_write_chnl_valid <= 1'b0;
            acc_done <= 1'b0;
            debug <= 32'd0;
            read_count <= 32'd0;
            write_count <= 32'd0;
            total_elements <= 32'd0;
        end else begin
            case (state)
                STATE_IDLE: begin
                    // Wait for configuration to be done
                    if (conf_done && conf_info_enable) begin
                        // Initialize parameters for DMA read
                        total_elements <= conf_info_data_out * conf_info_data_out;
                        state <= STATE_INIT_READ;
                        debug <= 32'd1; // Debug: entered INIT_READ state
                    end else begin
                        acc_done <= 1'b0;
                    end
                end

                STATE_INIT_READ: begin
                    // Setup DMA read request
                    dma_read_ctrl_valid <= 1'b1;
                    dma_read_ctrl_data_index <= 32'd0; // Start from offset 0
                    dma_read_ctrl_data_length <= total_elements; // Read all elements
                    dma_read_ctrl_data_size <= WORD; // 32-bit data
                    dma_read_ctrl_data_user <= 5'd0; // Default user field
                    
                    if (dma_read_ctrl_ready && dma_read_ctrl_valid) begin
                        // DMA read request accepted
                        dma_read_ctrl_valid <= 1'b0;
                        dma_read_chnl_ready <= 1'b1;
                        state <= STATE_READING;
                        debug <= 32'd2; // Debug: entered READING state
                    end
                end

                STATE_READING: begin
                    // Process incoming data
                    if (dma_read_chnl_valid && dma_read_chnl_ready) begin
                        // Store data in buffer
                        buffer[read_count] <= dma_read_chnl_data;
                        read_count <= read_count + 1;
                        
                        // Check if all data is read
                        if (read_count == total_elements - 1) begin
                            dma_read_chnl_ready <= 1'b0;
                            state <= STATE_INIT_WRITE;
                            debug <= 32'd3; // Debug: entered INIT_WRITE state
                        end
                    end
                end

                STATE_INIT_WRITE: begin
                    // Setup DMA write request
                    dma_write_ctrl_valid <= 1'b1;
                    dma_write_ctrl_data_index <= total_elements; // Start writing at offset after read data
                    dma_write_ctrl_data_length <= total_elements; // Write all elements
                    dma_write_ctrl_data_size <= WORD; // 32-bit data
                    dma_write_ctrl_data_user <= 5'd0; // Default user field
                    
                    if (dma_write_ctrl_ready && dma_write_ctrl_valid) begin
                        // DMA write request accepted
                        dma_write_ctrl_valid <= 1'b0;
                        state <= STATE_WRITING;
                        debug <= 32'd4; // Debug: entered WRITING state
                    end
                end

                STATE_WRITING: begin
                    // Send data to be written
                    dma_write_chnl_valid <= 1'b1;
                    dma_write_chnl_data <= buffer[write_count];
                    
                    if (dma_write_chnl_ready && dma_write_chnl_valid) begin
                        write_count <= write_count + 1;
                        
                        // Check if all data is written
                        if (write_count == total_elements - 1) begin
                            dma_write_chnl_valid <= 1'b0;
                            state <= STATE_DONE;
                            debug <= 32'd5; // Debug: entered DONE state
                        end
                    end
                end

                STATE_DONE: begin
                    // Signal completion
                    acc_done <= 1'b1;
                    state <= STATE_IDLE;
                    read_count <= 32'd0;
                    write_count <= 32'd0;
                    debug <= 32'd0;
                end

                default: begin
                    state <= STATE_IDLE;
                end
            endcase
        end
    end

endmodule