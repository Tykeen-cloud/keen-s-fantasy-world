`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/13 23:37:34
// Design Name: 
// Module Name: top
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


module top (
    input  wire clk,
    input  wire rst,

    // UART IO 接口
    input  wire rx,     // 串口输入（上位机 → FPGA）
    output wire tx      // 串口输出（FPGA → 上位机）
);

    // ===============================
    // 1) 中间信号定义
    // ===============================

    // 来自 uart_recv
    wire        recv_valid;
    wire [7:0]  recv_code;
    wire        recv_ack;

    // 给 uart_send
    wire        send_req;
    wire [7:0]  send_data;
    wire        tx_busy;
    wire        tx_done;   // send 模块可能会用到，但顶层无需处理


    // ===============================
    // 2) 模块实例化
    // ===============================

    // ---- UART 接收器 ----
    uart_recv u_recv (
        .clk(clk),
        .rst(rst),
        .din(rx),

        // 非握手接口
        .valid(),
        .enter_detect(),
        .start_match(),
        .stop_match(),
        .hitsz_match(),

        // 握手接口（顶层真正使用）
        .result_code(recv_code),
        .result_valid(recv_valid),
        .result_ack(recv_ack)
    );


    // ---- UART 桥接逻辑（bridge）----
    uart_bridge u_bridge (
        .clk(clk),
        .rst(rst),

        // 输入：来自 uart_recv
        .recv_valid(recv_valid),
        .recv_code(recv_code),
        .recv_ack(recv_ack),

        // 输出：给 uart_send
        .send_req(send_req),
        .send_data(send_data),

        // 输入：发送器忙状态
        .tx_busy(tx_busy)
    );


    // ---- UART 发送器 ----
    uart_send u_send (
        .clk(clk),
        .rst(rst),
        .valid(send_req),      // 单拍启动信号
        .enter_en(1'b1),       // 永远允许发送
        .data(send_data),
        .dout(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

endmodule
