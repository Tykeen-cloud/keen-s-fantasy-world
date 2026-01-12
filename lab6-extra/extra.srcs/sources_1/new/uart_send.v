`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/13 20:11:23
// Design Name: 
// Module Name: uart_send
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module uart_send (
    input  wire       clk,
    input  wire       rst,
    input  wire       valid,      // 外部发送请求：将 data 写入发送器
    input  wire       enter_en,   // 使能信号（你原来用于控制是否允许发送）
    input  wire [7:0] data,       // 要发送的字节，由外部提供
    output reg        dout,       // UART TX 输出
    output wire       tx_busy,    // 正在发送（busy=1）
    output wire       tx_done     // 一个字节发送完成（单拍）
);

    // 状态定义
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // 波特率计数：100MHz / 9600 ≈ 10416
    localparam integer CLK_PER_BIT = 10416;
    localparam integer CNT_WIDTH   = 14;

    reg [1:0] current_state = IDLE;
    reg [1:0] next_state    = IDLE;

    reg [CNT_WIDTH-1:0] bit_cnt = 0;      // 单个 bit 的计数器
    reg [3:0] data_index = 0;             // 当前正在发送第几位（0~7）
    reg [7:0] tx_data = 0;                // latch 住的数据，保证整个发送过程 data 稳定

    // valid_latched：在 IDLE 时捕获 valid & enter_en，避免 valid 与 data 同周期变化造成问题
    reg valid_latched = 0;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            valid_latched <= 0;
            tx_data <= 0;
        end
        else begin
            // 在 IDLE 且 valid && enter_en 时，锁存 data
            if (current_state == IDLE && valid && enter_en) begin
                valid_latched <= 1;
                tx_data <= data;
            end
            else if (current_state != IDLE) begin
                // 开始发送后清除 latch
                valid_latched <= 0;
            end
        end
    end

    // 一个 bit 是否结束
    wire bit_end = (bit_cnt == CLK_PER_BIT - 1);

    // tx_busy：在 START/DATA/STOP 时为 1
    assign tx_busy = (current_state != IDLE);

    // tx_done：STOP 结束的那个周期给一个脉冲
    reg tx_done_reg = 0;
    always @(posedge clk or posedge rst) begin
        if (rst)
            tx_done_reg <= 0;
        else if (current_state == STOP && bit_end)
            tx_done_reg <= 1;
        else
            tx_done_reg <= 0;
    end
    assign tx_done = tx_done_reg;

    // 状态寄存器
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    // 状态转移
    always @(*) begin
        case (current_state)
            IDLE: begin
                if (valid_latched)
                    next_state = START;
            end
            START: begin
                if (bit_end)
                    next_state = DATA;
            end
            DATA: begin
                if (bit_end && data_index == 7)
                    next_state = STOP;
            end
            STOP: begin
                if (bit_end)
                    next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // bit 计数器
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_cnt <= 0;
        end
        else begin
            if (bit_end)
                bit_cnt <= 0;
            else if (current_state != IDLE)
                bit_cnt <= bit_cnt + 1;
        end
    end

    // data_index（DATA 状态，每发完一个 bit 递增）
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_index <= 0;
        else if (current_state == IDLE)
            data_index <= 0;
        else if ((current_state == DATA) && bit_end)
            data_index <= data_index + 1;
    end

    // UART 输出逻辑：起始位 0、数据位 tx_data[data_index]、停止位 1
    always @(*) begin
        case (current_state)
            IDLE:    dout = 1'b1;                     // 线空闲为高
            START:   dout = 1'b0;                     // 起始位
            DATA:    dout = tx_data[data_index];      // 数据位
            STOP:    dout = 1'b1;                     // 停止位
            default: dout = 1'b1;
        endcase
    end

endmodule
