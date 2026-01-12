`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/27 19:35:54
// Design Name: 
// Module Name: testbench
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


module testbench();
reg clk;
reg rst;
reg button;
reg [1:0] fre_set;
reg dir_set;
wire [7:0] led;
flow_light u_flow_light (
.clk(clk),
.rst(rst),
.button(button),
.fre_set(fre_set),
.dir_set(dir_set),
.led(led)
);
initial begin
rst=1'b1;
button=1'b0;
clk=1'b0;
fre_set=2'b00;
dir_set=1'b0;
#100;
rst=1'b0;
#200;
button=1'b1;
#10;
button=1'b0;
#500000;
#100000;
fre_set=2'b11;
#100000;
dir_set=1'b1;
#5000000;
button=1'b1;
#10;
button=1'b0;
#10000000;
$finish;
end
always #5 clk=~clk;
endmodule
