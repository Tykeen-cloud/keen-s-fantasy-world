`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/20 09:11:28
// Design Name: 
// Module Name: reg8file
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


module reg8file(
input wire clk,
input wire clr,
input wire en,
input wire [7:0] d,
input wire [2:0] wsel,
input wire [2:0] rsel,
output reg [7:0] q
);
wire clr_n;
reg [7:0] reg_array [7:0];
integer i;
assign clr_n=~clr;
always@(posedge clk or negedge clr_n) begin
if(~clr_n)begin
for(i=0;i<8;i=i+1) begin
reg_array[i]<=8'h00;
end
end 
else if(en) begin
reg_array[wsel]<=d;
end
end
always@(*) begin
q=reg_array[rsel];
end



 
endmodule
