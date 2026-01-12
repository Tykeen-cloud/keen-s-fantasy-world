`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 23:48:42
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


module top(
    input  wire clk,
    input  wire rst,
    input  wire s3,
    input  wire din,
    output wire dout,
    output wire [7:0] seg,
    output wire [7:0] an
);

    
    wire [7:0] recv_data;
    wire recv_valid;
    uart_recv u_uart_recv(
        .clk(clk),
        .rst(rst),
        .din(din),
        .valid(recv_valid),
        .data(recv_data)
    );

    
    seg_display u_seg_display(
        .clk(clk),
        .rst(rst),
        .data_in(recv_data),
        .valid(recv_valid),
        .seg(seg),
        .an(an)
    );

    
    wire valid_d;
    wire valid;
    wire [7:0] data_tosend;
    wire tx_busy, tx_done;

    uart_send u_uart_send(
        .clk(clk),
        .rst(rst),
        .valid(valid),
        .data_tosend(data_tosend),
        .dout(dout),
        .tx_busy(tx_busy),
        .tx_done(tx_done)
    );

    
    id_sender u_id_sender(
        .clk(clk),
        .rst(rst),
        .btn(s3),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .valid(valid),
        .data_tosend(data_tosend)
    );

endmodule