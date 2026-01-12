`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/13 15:40:29
// Design Name: 
// Module Name: mux
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


module mux(
    input  wire  en,
    input  wire  mux_sel,
    input  wire  [3:0] input_a,
    input  wire  [3:0] input_b,
    output  reg  [3:0] output_c
);

always @ (*) begin
   case({en,mux_sel})
   2'b1_0: output_c=input_a+input_b;
   2'b1_1: output_c=input_a-input_b;
   2'b0_1: output_c=4'b1111;
   2'b0_0: output_c=4'b1111;
   default:output_c=4'b0000;
   endcase
end  
endmodule
