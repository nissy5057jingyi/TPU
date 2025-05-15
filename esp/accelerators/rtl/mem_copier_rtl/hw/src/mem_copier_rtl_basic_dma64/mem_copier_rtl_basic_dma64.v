module simple_ram64 #(
    parameter DEPTH = 128
)(
    input clk,
    input [6:0] addr,
    input [63:0] din,
    input we,
    output reg [63:0] dout
);

    reg [63:0] mem [0:DEPTH-1];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= din;
        dout <= mem[addr];
    end

endmodule

module men_copier_rtl_basic_dma64 (
    input clk,
    input rst,
    input conf_done,
    input [31:0] conf_info_data_in,
    output reg acc_done,
    output [31:0] debug,

    input dma_read_ctrl_ready,
    output reg dma_read_ctrl_valid,
    output reg [31:0] dma_read_ctrl_data_index,
    output reg [31:0] dma_read_ctrl_data_length,
    output [2:0] dma_read_ctrl_data_size,
    output [5:0] dma_read_ctrl_data_user,

    input dma_read_chnl_valid,
    output dma_read_chnl_ready,
    input [63:0] dma_read_chnl_data,

    input dma_write_ctrl_ready,
    output reg dma_write_ctrl_valid,
    output reg [31:0] dma_write_ctrl_data_index,
    output reg [31:0] dma_write_ctrl_data_length,
    output [2:0] dma_write_ctrl_data_size,
    output [5:0] dma_write_ctrl_data_user,

    input dma_write_chnl_ready,
    output dma_write_chnl_valid,
    output [63:0] dma_write_chnl_data
);

    // State definitions - simplified for reliability
    localparam IDLE = 0, START_RD = 1, WAIT_RD = 2, START_WR = 3, WAIT_WR = 4, DONE = 5;
    reg [2:0] state_reg, state_next;

    // Data counters
    reg [6:0] rd_count, wr_count;
    wire [6:0] total_words;
    assign total_words = conf_info_data_in[0] ? conf_info_data_in[31:1] + 1 : conf_info_data_in[31:1];

    // RAM I/F
    reg ram_we;
    reg [6:0] ram_wr_addr, ram_rd_addr;
    reg [63:0] ram_din;
    wire [63:0] ram_dout;
    reg [63:0] write_data;

    // RAM instance
    simple_ram64 u_ram (
        .clk(clk),
        .addr((state_reg == WAIT_RD) ? ram_wr_addr : ram_rd_addr),
        .din(ram_din),
        .we(ram_we),
        .dout(ram_dout)
    );

    // DMA settings
    assign dma_read_ctrl_data_size = 3'b011;
    assign dma_write_ctrl_data_size = 3'b011;
    assign dma_read_ctrl_data_user = 6'b000000;
    assign dma_write_ctrl_data_user = 6'b000000;

    // DMA handshaking
    assign dma_read_chnl_ready = (state_reg == WAIT_RD);
    assign dma_write_chnl_valid = (state_reg == WAIT_WR);
    assign dma_write_chnl_data = write_data;

    // Debug output
    assign debug = {28'd0, state_reg};

    // State register
    always @(posedge clk) begin
        if (rst == 1'b0) begin
            state_reg <= IDLE;
        end else begin
            state_reg <= state_next;
        end
    end

    // Next state logic - separate from outputs
    always @(*) begin
        state_next = state_reg;

        case (state_reg)
            IDLE: begin
                if (conf_done) begin
                    state_next = START_RD;
                end
            end

            START_RD: begin
                if (dma_read_ctrl_ready) begin
                    state_next = WAIT_RD;
                end
            end

            WAIT_RD: begin
                if (rd_count >= total_words) begin
                    state_next = START_WR;
                end
            end

            START_WR: begin
                if (dma_write_ctrl_ready) begin
                    state_next = WAIT_WR;
                end
            end

            WAIT_WR: begin
                if (wr_count >= total_words) begin
                    state_next = DONE;
                end
            end

            DONE: begin
                state_next = IDLE;
            end

            default: begin
                state_next = IDLE;
            end
        endcase
    end

    // Output and datapath logic - separate from state transitions
    always @(posedge clk) begin
        if (rst == 1'b0) begin
            acc_done <= 0;
            rd_count <= 0;
            wr_count <= 0;
            ram_we <= 0;
            dma_read_ctrl_valid <= 0;
            dma_write_ctrl_valid <= 0;
            dma_read_ctrl_data_index <= 0;
            dma_read_ctrl_data_length <= 0;
            dma_write_ctrl_data_index <= 0;
            dma_write_ctrl_data_length <= 0;
            ram_wr_addr <= 0;
            ram_rd_addr <= 0;
            ram_din <= 0;
            write_data <= 0;
        end else begin
            // Default values
            ram_we <= 0;
            acc_done <= 0;
            
            case (state_reg)
                IDLE: begin
                    rd_count <= 0;
                    wr_count <= 0;
                    dma_read_ctrl_valid <= 0;
                    dma_write_ctrl_valid <= 0;
                end

                START_RD: begin
                    dma_read_ctrl_valid <= 1;
                    dma_read_ctrl_data_index <= 0;
                    dma_read_ctrl_data_length <= total_words;
                end

                WAIT_RD: begin
                    dma_read_ctrl_valid <= 0;
                    if (dma_read_chnl_valid) begin
                        ram_din <= dma_read_chnl_data;
                        ram_wr_addr <= rd_count;
                        ram_we <= 1;
                        rd_count <= rd_count + 1;
                    end
                end

                START_WR: begin
                    dma_write_ctrl_valid <= 1;
                    dma_write_ctrl_data_index <= 0;
                    dma_write_ctrl_data_length <= total_words;
                    ram_rd_addr <= 0;
                end

                WAIT_WR: begin
                    dma_write_ctrl_valid <= 0;
                    
                    // First data word should be pre-loaded
                    if (state_next == WAIT_WR && state_reg == START_WR) begin
                        write_data <= ram_dout;
                    end
                    
                    // Update on write channel ready
                    if (dma_write_chnl_ready) begin
                        wr_count <= wr_count + 1;
                        ram_rd_addr <= wr_count + 1;
                        // Load next data on next cycle
                        write_data <= ram_dout;
                    end
                end

                DONE: begin
                    acc_done <= 1;
                end
            endcase
        end
    end

endmodule