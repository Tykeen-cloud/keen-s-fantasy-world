`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/27 14:41:37
// Design Name: 
// Module Name: counter
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


module counter 
(
    input wire clk,
    input wire rst,
    input wire [1:0] fre_set,
    output reg tick
);

reg   cnt_inc;
localparam CNT_1000HZ = 100 - 1; // 100000000/1000 - 1
localparam CNT_100HZ  = 200 - 1;
localparam CNT_20HZ   = 300 - 1; 
localparam CNT_5HZ    = 400 - 1;
localparam CNT_WIDTH  = 25;
reg [CNT_WIDTH-1:0] cnt;
reg [CNT_WIDTH-1:0] max_cnt;
always @(*) begin
        case(fre_set)
            2'b00: max_cnt = CNT_1000HZ; // 1000Hz
            2'b01: max_cnt = CNT_100HZ;  // 100Hz
            2'b10: max_cnt = CNT_20HZ;   // 20Hz
            2'b11: max_cnt = CNT_5HZ;    // 5Hz
            default:
             max_cnt = CNT_1000HZ;
        endcase
    end
wire  cnt_end = cnt_inc & (cnt==max_cnt);


always @ (posedge clk or posedge rst) begin
        if(rst) begin
            cnt <= {CNT_WIDTH{1'b0}}; 
            tick <= 1'b0;
        end
        else if (cnt == max_cnt) begin 
            cnt <= {CNT_WIDTH{1'b0}};
            tick <= 1'b1;
        end
        
        else begin
            cnt <= cnt + 1;
            tick <= 1'b0; 
        end
    end

endmodule
