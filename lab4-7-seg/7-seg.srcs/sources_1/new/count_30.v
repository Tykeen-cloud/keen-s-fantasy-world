`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/31 21:43:00
// Design Name: 
// Module Name: count_30
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


module counter_30(
input wire clk,
input wire clk_count,
input wire rst,
input wire s2,
output reg [7:0] cnt

    );
localparam DEBOUNCE_CNT_MAX = 20'd999_999; 
reg [19:0] debounce_cnt = 20'd0;
reg btn_raw_sync = 1'b0;
reg btn_debounced = 1'b0;
reg run_en;
always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_raw_sync <= 1'b0;
        debounce_cnt <= 20'd0;
        btn_debounced <= 1'b0;
    end else begin
        
        btn_raw_sync <= s2; 
        
        
        
        if (btn_raw_sync != btn_debounced) begin
            if (debounce_cnt == DEBOUNCE_CNT_MAX) begin
                btn_debounced <= btn_raw_sync;
                debounce_cnt <= 20'd0;
            end else begin
                debounce_cnt <= debounce_cnt + 20'd1;
            end
        end else begin
            debounce_cnt <= 20'd0;
        end
    end
end


reg btn_sync_d1 = 1'b0;
wire btn_to_use; 
wire btn_trigger; 

assign btn_to_use =  btn_debounced ;


always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_sync_d1 <= 1'b0;
    end else begin
        btn_sync_d1 <= btn_to_use;
    end
end
assign btn_trigger = btn_sync_d1 & ~btn_to_use; 
always@(posedge clk or posedge rst)begin
if(rst)begin
run_en<=1'b0;
end else if(btn_trigger)begin
run_en<=~run_en;
end
end
reg [7:0] count_bcd_reg = 8'h00; 


wire [3:0] d0 = count_bcd_reg[3:0];   // 个位
wire [3:0] d1 = count_bcd_reg[7:4];   // 十位

always @(posedge clk_count or posedge rst) begin
    if (rst) begin
        count_bcd_reg <= 8'h00;
    end else if (run_en) begin
        if (count_bcd_reg == 8'h30) begin
            count_bcd_reg <= 8'h00;
        end
        else if (d0 < 4'd9) begin
            count_bcd_reg={d1,d0 + 4'd1};
        end
        else begin
            count_bcd_reg={d1+1,4'd0}; 
    end
    end
end

always@(*)begin
cnt=count_bcd_reg;
end


endmodule
