`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/31 21:40:06
// Design Name: 
// Module Name: div_freq
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


module div_freq
(
    input wire clk,
    input wire rst,
    output reg scantick,
    output reg counttick
);

reg   scancnt_inc;
reg   countcnt_inc;
localparam CNT_WIDTH  = 25;
reg [CNT_WIDTH-1:0] scancnt;
reg [CNT_WIDTH-1:0] max_scancnt=100000000/500-1;
reg [CNT_WIDTH-1:0] countcnt;
reg [CNT_WIDTH-1:0] max_countcnt=100000000/10-1;
wire  scancnt_end = scancnt_inc & (scancnt==max_scancnt);
wire  countcnt_end = countcnt_inc & (countcnt==max_countcnt);

always @ (posedge clk or posedge rst) begin
        if(rst) begin
            scancnt <= {CNT_WIDTH{1'b0}}; 
            scantick <= 1'b0;
        end
        else if (scancnt == max_scancnt) begin 
            scancnt <= {CNT_WIDTH{1'b0}};
            scantick <= 1'b1;
        end
        
        else begin
            scancnt <= scancnt + 1;
            scantick <= 1'b0; 
        end
    end
always @ (posedge clk or posedge rst) begin
        if(rst) begin
            countcnt <= {CNT_WIDTH{1'b0}}; 
            counttick <= 1'b0;
        end
        else if (countcnt == max_countcnt) begin 
            countcnt <= {CNT_WIDTH{1'b0}};
            counttick <= 1'b1;
        end
        
        else begin
            countcnt <= countcnt + 1;
            counttick <= 1'b0; 
        end
    end
endmodule
