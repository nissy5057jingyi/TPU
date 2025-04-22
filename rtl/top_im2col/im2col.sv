module im2col #(
    parameter INPUT_WIDTH  = 4,
    parameter INPUT_HEIGHT = 4,
    parameter KERNEL_SIZE  = 3,
    parameter DWIDTH       = 8
)(
    input  logic clk,
    input  logic rst,

    // 写入接口
    input  logic write_en,
    input  logic [$clog2(INPUT_WIDTH)-1:0]  write_x,
    input  logic [$clog2(INPUT_HEIGHT)-1:0] write_y,
    input  logic [DWIDTH-1:0] write_data,

    // 控制接口
    input  logic start,

    // 输出接口
    output logic valid,
    output logic [(DWIDTH*KERNEL_SIZE*KERNEL_SIZE)-1:0] data_out
);

    // 参数计算
    localparam OUTPUT_WIDTH  = INPUT_WIDTH  - KERNEL_SIZE + 1;
    localparam OUTPUT_HEIGHT = INPUT_HEIGHT - KERNEL_SIZE + 1;

    // 存储图像数据（模拟BRAM）
    logic [DWIDTH-1:0] input_mem[0:INPUT_HEIGHT-1][0:INPUT_WIDTH-1];

    // 写数据到内存
    always_ff @(posedge clk) begin
        if (write_en) begin
            input_mem[write_y][write_x] <= write_data;
        end
    end

    // 状态机
    typedef enum logic [1:0] {IDLE, LOAD, OUTPUT, DONE} state_t;
    state_t state, next_state;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // 控制信号和坐标
    logic [31:0] win_x, win_y;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            win_x <= 0;
            win_y <= 0;
        end else if (state == OUTPUT) begin
            if (win_x < OUTPUT_WIDTH - 1) begin
                win_x <= win_x + 1;
            end else begin
                win_x <= 0;
                win_y <= win_y + 1;
            end
        end else if (state == IDLE && start) begin
            win_x <= 0;
            win_y <= 0;
        end
    end

    // patch flatten 输出构建
    logic [(DWIDTH*KERNEL_SIZE*KERNEL_SIZE)-1:0] patch;
    assign data_out = patch;

    integer i, j;
    always_ff @(posedge clk) begin
        if (state == LOAD) begin
            for (i = 0; i < KERNEL_SIZE; i++) begin
                for (j = 0; j < KERNEL_SIZE; j++) begin
                    patch[(i*KERNEL_SIZE + j)*DWIDTH +: DWIDTH] <= input_mem[win_y + i][win_x + j];
                end
            end
        end
    end

    // 状态转移与 valid 信号
    always_comb begin
        next_state = state;
        valid = 0;
        case (state)
            IDLE: begin
                if (start)
                    next_state = LOAD;
            end
            LOAD: begin
                next_state = OUTPUT;
            end
            OUTPUT: begin
                valid = 1;
                if (win_x == OUTPUT_WIDTH - 1 && win_y == OUTPUT_HEIGHT - 1)
                    next_state = DONE;
                else
                    next_state = LOAD;
            end
            DONE: begin
                valid = 0;
            end
        endcase
    end

endmodule

