`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 21:20:41
// Design Name: 
// Module Name: uart_recv
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


module uart_recv(
    input  wire       clk,
    input  wire       rst,
    input  wire       din,
    output reg        valid,
    output reg  [7:0] data
);

    // -------------------- 状态定义 --------------------
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] state, next_state;

    // -------------------- 时序参数 --------------------
    localparam integer CLK_PER_BIT = 10416; // 100MHz / 9600bps ≈ 10416
    localparam integer CNT_WIDTH   = 14;

    reg [CNT_WIDTH-1:0] bit_cnt = 0;
    reg [3:0] data_index = 0;
    reg [7:0] data_reg   = 0;

    wire bit_end  = (bit_cnt == CLK_PER_BIT - 1);
    wire bit_half = (bit_cnt == CLK_PER_BIT / 2);

    
    // 状态机切换
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    // 状态转移逻辑
    always @(*) begin
        case (state)
            IDLE:  if (~din) next_state = START;
            START: if (bit_end) next_state = DATA;
            DATA:  if (bit_end && data_index == 7) next_state = STOP;
            STOP:  if (bit_end) next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    
    // bit 计数器
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            bit_cnt <= 0;
        else begin
            case (state)
                IDLE: bit_cnt <= 0;
                START, DATA, STOP: begin
                    if (bit_end)
                        bit_cnt <= 0;
                    else
                        bit_cnt <= bit_cnt + 1;
                end
                default: bit_cnt <= 0;
            endcase
        end
    end

   
    // data_index 计数
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_index <= 0;
        else begin
            if (state == IDLE)
                data_index <= 0;
            else if (state == DATA && bit_end && data_index != 7)
                data_index <= data_index + 1;
        end
    end

    
    // 数据采样寄存
    
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_reg <= 0;
        else if (state == DATA && bit_half)
            data_reg[data_index] <= din;
    end
    // 输出数据寄存（完整字节更新)
    always @(posedge clk or posedge rst) begin
        if (rst)
            data <= 0;
        else if (state == STOP && bit_end)
            data <= data_reg;
    end
// valid 脉冲生成
    always @(posedge clk or posedge rst) begin
        if (rst)
            valid <= 0;
        else if (state == STOP && bit_end)
            valid <= 1'b1;
        else
            valid <= 1'b0;
    end

endmodule