`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/21 18:34:57
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
reg clr;
reg en;
reg [7:0] d;
reg [2:0] wsel;
reg [2:0] rsel;
wire [7:0] q;
initial begin
clr=1'b1;
en=1'b0;
clk=1'b0;
d=8'h00;
wsel=3'b000;
rsel=3'b000;
#10;
clr=1'b0;
en=1'b1;
d=8'hce;
wsel=3'b011;
rsel=3'b001;
#10 d=8'h34;wsel=3'b010;rsel=3'b011;
#10 d=8'h45;wsel=3'b100;rsel=3'b010;
#10;
en=1'b0;
#10 clr=1'b1;
#50 $finish;
end
always #5 clk=~clk;

reg8file u_reg8file(
.clk(clk),
.clr(clr),
.en(en),
.d(d),
.wsel(wsel),
.rsel(rsel),
.q(q)
);

endmodule
