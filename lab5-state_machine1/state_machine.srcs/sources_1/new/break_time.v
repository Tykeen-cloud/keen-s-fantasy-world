`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/05 11:14:33
// Design Name: 
// Module Name: break_time
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


module break_time(
    input  wire clk,
    input  wire rst,
    input  wire start_001,
    input  wire start_02,
    output reg  done_001,
    output reg  done_02
);

parameter CLK_FREQ = 100_000_000; // 100 MHz
parameter max_001 = CLK_FREQ / 100; // 0.01 s = 1e-2 s = 100 Hz
parameter max_02  = CLK_FREQ / 5;   // 0.2 s = 5 Hz

reg [26:0] cnt_001s = 0;
reg [31:0] cnt_02s  = 0;

// -------------------- 0.01s 定时 --------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_001s <= 0;
        
    end else begin
        if (start_001) begin
            if (cnt_001s < max_001 - 1) begin
                cnt_001s <= cnt_001s + 1;
                
            end else begin
                cnt_001s <= 0;
                
            end
        end else begin
            // 当 start_001 拉低时，停止计数并清除标志
            cnt_001s <= 0;
            
        end
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        done_001<=1'b0;
        
    end else if(start_001 && (cnt_001s==max_001-1))begin
    done_001<=1'b1;
                
           
        end else begin
            // 当 start_001 拉低时，停止计数并清除标志
        done_001<=1'b0;
            
        end
    end
// -------------------- 0.2s 定时 --------------------
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cnt_02s <= 0;
        
    end else begin
        if (start_02) begin
            if (cnt_02s < max_02 - 1) begin
                cnt_02s <= cnt_02s + 1;
                
            end else begin
                cnt_02s <= 0;
                
            end
        end else begin
            cnt_02s <= 0;
            
        end
    end
end
always @(posedge clk or posedge rst) begin
    if (rst) begin
        done_02 <= 1'b0;
        
    end else  if(start_02 && (cnt_02s==max_02-1))begin
        done_02<=1'b1;
                
            
    end else begin
            cnt_02s <= 1'b0;
            
        end
    end
endmodule

