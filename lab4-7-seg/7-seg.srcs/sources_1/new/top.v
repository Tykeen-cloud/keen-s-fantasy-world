`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/31 21:36:12
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
input wire clk,
input wire rst,
input wire en,
input wire s3,
input wire control,
output wire [7:0] led_en,
output wire [7:0] led_cx
);
wire clk_count;
wire clk_scan;
wire [7:0] cnt_s3;
wire [7:0] cntplus_s3;
wire [7:0] cnt_30;
wire [31:0] display;
wire [7:0] scan_data;     // 动态扫描模块输出的当前数码管的7段码
wire [7:0] scan_addr;     // 动态扫描模块输出的当前位选地
localparam [3:0] ID_HIGH_BCD = 4'h3;
localparam [3:0] ID_LOW_BCD  = 4'h6;
div_freq u_div_freq(
.clk(clk),
.rst(rst),
.scantick(clk_scan),
.counttick(clk_count)
);
s3_counter u_s3_counter(
.clk(clk),
.rst(rst),
.btn_in(s3),
.is_debounced(1'b0),
.count_bcd(cnt_s3)
);
s3_counter plus_s3_counter(
.clk(clk),
.rst(rst),
.btn_in(s3),
.is_debounced(1'b1),
.count_bcd(cntplus_s3)
);
counter_30 u_counter_30(
.clk(clk),
.clk_count(clk_count),
.rst(rst),
.s2(control),
.cnt(cnt_30)
);
assign display={
ID_HIGH_BCD,
ID_LOW_BCD,
cnt_s3,
cntplus_s3,
cnt_30
};
time_display u_time_display(
.clk(clk),
.rst_n(~rst),
.clk_scan(clk_scan),
.data_bcd_in(display),
.an(scan_addr),
.seg(scan_data)
);
assign led_en = en ? scan_addr : 8'hFF;
assign led_cx=scan_data;
endmodule