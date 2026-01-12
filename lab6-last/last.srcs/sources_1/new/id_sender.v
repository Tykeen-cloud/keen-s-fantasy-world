`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/14 09:12:56
// Design Name: 
// Module Name: id_sender
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


module id_sender(
    input  wire clk,
    input  wire rst,
    input  wire btn,          // 原来的 s3

    input  wire tx_busy,
    input  wire tx_done,

    output reg  valid,        // 给 uart_send
    output reg  [7:0] data_tosend
);

    // ---------------- ROM 学号 ----------------
    reg [7:0] id_mem [0:9];
    always @(*) begin
        id_mem[0] = 8'h32;
        id_mem[1] = 8'h30;
        id_mem[2] = 8'h32;
        id_mem[3] = 8'h34;
        id_mem[4] = 8'h33;
        id_mem[5] = 8'h31;
        id_mem[6] = 8'h31;
        id_mem[7] = 8'h33;
        id_mem[8] = 8'h33;
        id_mem[9] = 8'h36;
    end

    // ---------------- 按键消抖 ----------------
    localparam DEBOUNCE_MAX = 20'd999_999;

    reg [19:0] debounce_cnt;
    reg btn_sync0, btn_sync1, btn_state, btn_state_d;

    wire btn_edge = (~btn_state) & btn_state_d;

    // sync0
    always @(posedge clk or posedge rst) begin
        if (rst) btn_sync0 <= 0;
        else     btn_sync0 <= btn;
    end

    // sync1
    always @(posedge clk or posedge rst) begin
        if (rst) btn_sync1 <= 0;
        else     btn_sync1 <= btn_sync0;
    end

    // state
    always @(posedge clk or posedge rst) begin
        if (rst)
            btn_state <= 0;
        else if (btn_sync1 != btn_state) begin
            if (debounce_cnt == DEBOUNCE_MAX)
                btn_state <= btn_sync1;
        end
    end

    // debounce counter
    always @(posedge clk or posedge rst) begin
        if (rst)
            debounce_cnt <= 0;
        else if (btn_sync1 != btn_state) begin
            if (debounce_cnt < DEBOUNCE_MAX)
                debounce_cnt <= debounce_cnt + 1;
            else
                debounce_cnt <= 0;
        end else
            debounce_cnt <= 0;
    end

    // state_d
    always @(posedge clk or posedge rst) begin
        if (rst) btn_state_d <= 0;
        else     btn_state_d <= btn_state;
    end

    // ---------------- UART 学号发送 FSM ----------------
    reg sending;
    reg [3:0] index;

    // valid
    always @(posedge clk or posedge rst) begin
        if (rst)
            valid <= 0;
        else if (btn_edge && ~sending && ~tx_busy)
            valid <= 1;
        else if (sending && tx_done && index < 9)
            valid <= 1;
        else
            valid <= 0;
    end

    // index
    always @(posedge clk or posedge rst) begin
        if (rst)
            index <= 0;
        else if (btn_edge && ~sending && ~tx_busy)
            index <= 0;
        else if (sending && tx_done && index < 9)
            index <= index + 1;
    end

    // sending
    always @(posedge clk or posedge rst) begin
        if (rst)
            sending <= 0;
        else if (btn_edge && ~sending && ~tx_busy)
            sending <= 1;
        else if (sending && tx_done && index == 9)
            sending <= 0;
    end

    // data
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_tosend <= 0;
        else if (btn_edge && ~sending && ~tx_busy)
            data_tosend <= id_mem[0];
        else if (sending && tx_done && index < 9)
            data_tosend <= id_mem[index + 1];
    end

endmodule