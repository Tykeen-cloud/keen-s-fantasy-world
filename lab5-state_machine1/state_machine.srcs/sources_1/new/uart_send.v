`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/05 12:52:57
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
    input  wire       valid,     
    input  wire [7:0] data,       
    output reg        dout,       
    output wire       tx_busy,    
    output wire       tx_done     
);

    // 状态定义
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    
    localparam integer CLK_PER_BIT = 10417;
    localparam integer CNT_WIDTH   = 14; 

    reg [1:0] current_state = IDLE;
    reg [1:0] next_state    = IDLE;

    reg [CNT_WIDTH-1:0] bit_cnt = 0;  // 每 bit 的计数
    reg [3:0] data_index = 0;         // 发送第几位
    reg [7:0] tx_data = 0;            // 缓存要发的数据

    // 防丢帧的 valid 锁存
    reg valid_latched = 0;
    always @(posedge clk or posedge rst) begin
        if (rst)
            valid_latched <= 0;
        else if (valid)
            valid_latched <= 1;
        else if (current_state != IDLE)
            valid_latched <= 0; // 一旦进入发送就清除
    end

    // 判断一个 bit 是否发送结束
    wire bit_end = (bit_cnt == CLK_PER_BIT - 1);

    // tx_busy：在发送起始位、数据位、停止位期间为 1
    assign tx_busy = (current_state != IDLE);

    
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
            bit_cnt     <= 0;
        end else begin
            if (bit_end)
                bit_cnt <= 0;
            else if (current_state != IDLE)
                bit_cnt <= bit_cnt + 1;

            end
    end
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_index <= 0;
        else if (current_state == IDLE)
            data_index <= 0;
        else if ((current_state == DATA) && bit_end)
            data_index <= data_index + 1;
    end
    always @(posedge clk or posedge rst) begin
        if (rst)
            tx_data <= 0;
        else if ((current_state == IDLE) && valid_latched)
            tx_data <= data;
    end
    
    // UART 输出逻辑
   always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 1'b1;
        else begin
            case (current_state)
                IDLE:  dout <= 1'b1;
                START: dout <= 1'b0;
                DATA:  dout <= tx_data[data_index];
                STOP:  dout <= 1'b1;
                default: dout <= 1'b1;
            endcase
        end
    end

endmodule
