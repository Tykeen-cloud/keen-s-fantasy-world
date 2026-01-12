`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/18 19:02:19
// Design Name: 
// Module Name: uart_bridge
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


module uart_bridge (
    input  wire clk,
    input  wire rst,

    // 来自 uart_recv 的握手接口
    input  wire        recv_valid,
    input  wire [7:0]  recv_code,
    output reg         recv_ack,

    // 到 uart_send 的接口
    output reg         send_req,
    output reg [7:0]   send_data,
    input  wire        tx_busy
);

    // --------------------------
    // pending 缓冲区
    // --------------------------
    reg        pending_valid;
    reg [7:0]  pending_code;

    // ============================================================
    // pending_valid
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            pending_valid <= 1'b0;
        else begin
            if (recv_valid && !pending_valid)
                pending_valid <= 1'b1;          // 写入 pending
            else if (pending_valid && !tx_busy)
                pending_valid <= 1'b0;          // 消费 pending
        end
    end

    // ============================================================
    // pending_code
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            pending_code <= 8'd0;
        else if (recv_valid && !pending_valid)
            pending_code <= recv_code;          // 捕获数据
    end

    // ============================================================
    // recv_ack（单拍）
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            recv_ack <= 1'b0;
        else
            recv_ack <= (recv_valid && !pending_valid);
    end

    // ============================================================
    // send_req（单拍）
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            send_req <= 1'b0;
        else
            send_req <= (pending_valid && !tx_busy);
    end

    // ============================================================
    // send_data
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            send_data <= 8'd0;
        else if (pending_valid && !tx_busy)
            send_data <= pending_code;
    end

endmodule