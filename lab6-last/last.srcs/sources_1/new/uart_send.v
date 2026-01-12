`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 20:26:13
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
    input  wire       clk,        // 时钟：100MHz
    input  wire       rst,        // 异步复位
    
    input  wire       valid,      // 有效信号，高一个周期表示 data 有效
    input  wire [7:0] data_tosend,       // 待发送数据
    output reg        dout,       // UART 输出
    output wire       tx_busy,    // 正在发送标志
    output wire       tx_done     // 发送完成单脉冲
);

    // 状态定义
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    // 100MHz / 9600bps ≈ 10417
    localparam integer CLK_PER_BIT = 10416;
    localparam integer CNT_WIDTH   = 14; 

    reg [1:0] current_state = IDLE;
    reg [1:0] next_state    = IDLE;

    reg [CNT_WIDTH-1:0] bit_cnt = 0;  // 每 bit 的计数
    reg [3:0] data_index = 0;         // 发送第几位
    reg [9:0] tx_data = 0;            // 缓存要发的数据
    reg valid_r;
    always @(posedge clk or posedge rst) begin
        if (rst) valid_r <= 0;
        else     valid_r <= valid;
    end
    assign valid_d = valid_r;
   

    // 判断一个 bit 是否发送结束
    wire bit_end = (bit_cnt == CLK_PER_BIT - 1);

    // tx_busy：在发送起始位、数据位、停止位期间为 1
    assign tx_busy = (current_state != IDLE);

    // tx_done 单脉冲
    reg tx_done_reg = 0;
    always @(posedge clk or posedge rst) begin
        if (rst)
            tx_done_reg <= 0;
        else if (current_state == STOP && bit_end)
            tx_done_reg <= 1; // 停止位发送完产生单脉冲
        else
            tx_done_reg <= 0;
    end
    assign tx_done = tx_done_reg;
    
    // 状态转移
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    always @(*) begin
        case (current_state)
            IDLE: begin
                if (valid_d )
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

    // bit 计数器 + 数据索引
    always @(posedge clk or posedge rst) begin
    if (rst)
        tx_data <= 0;
    else if (current_state == IDLE && next_state == START)
        tx_data <= data_tosend;
end
always @(posedge clk or posedge rst) begin
    if (rst)
        bit_cnt <= 0;
    else if (bit_end)
        bit_cnt <= 0;
    else if (current_state != IDLE)
        bit_cnt <= bit_cnt + 1;
end
always @(posedge clk or posedge rst) begin
    if (rst)
        data_index <= 0;
    else if (current_state == DATA && bit_end)
        data_index <= data_index + 1;
    else if (current_state == IDLE)
        data_index <= 0;
end

    // UART 输出逻辑
    always @(*) begin
        case (current_state)
            IDLE:  dout = 1'b1;                    // 空闲高电平
            START: dout = 1'b0;                    // 起始位
            DATA:  dout = tx_data[data_index];     // 数据位
            STOP:  dout = 1'b1;                    // 停止位
            default: dout = 1'b1;
        endcase
    end

endmodule