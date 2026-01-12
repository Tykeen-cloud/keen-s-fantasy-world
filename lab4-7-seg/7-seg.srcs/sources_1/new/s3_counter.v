`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/31 21:41:37
// Design Name: 
// Module Name: s3_counter
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


module s3_counter (
    input wire clk,            
    input wire rst,           
    input wire btn_in,          
    input wire is_debounced,    
    output wire [7:0] count_bcd 
);
localparam DEBOUNCE_CNT_MAX = 20'd999_999; 
reg [19:0] debounce_cnt = 20'd0;
reg btn_raw_sync = 1'b0;
reg btn_debounced = 1'b0;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_raw_sync <= 1'b0;
        debounce_cnt <= 20'd0;
        btn_debounced <= 1'b0;
    end else begin
        
        btn_raw_sync <= btn_in; 
        
        
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

// --- 2. ���������ź� (���ؼ��?) ---
reg btn_sync_d1 = 1'b0;
wire btn_to_use; 
wire btn_trigger; 

assign btn_to_use = is_debounced ? btn_debounced : btn_raw_sync;


always @(posedge clk or posedge rst) begin
    if (rst) begin
        btn_sync_d1 <= 1'b0;
    end else begin
        btn_sync_d1 <= btn_to_use;
    end
end
assign btn_trigger = btn_sync_d1 & ~btn_to_use; 


// --- 3. BCD ������ (00-99 ѭ��) ---
reg [7:0] count_bcd_reg = 8'h00; 

// ���? BCD λ
wire [3:0] d0 = count_bcd_reg[3:0];   // ��λ
wire [3:0] d1 = count_bcd_reg[7:4];   // ʮλ

always @(posedge clk or posedge rst) begin
    if (rst) begin
        count_bcd_reg <= 8'h00;
    end else if (btn_trigger) begin
        // --- ��λ (d0) ���� 0-9 ---
        if (d0 < 4'd9) begin
            count_bcd_reg[3:0] <= d0 + 4'd1;
        end else begin
            count_bcd_reg[3:0] <= 4'd0; // ���㣬��λ��ʮλ
            
            // --- ʮλ (d1) ���� 0-9 ---
            if (d1 < 4'd9) begin
                count_bcd_reg[7:4] <= d1 + 4'd1;
            end else begin
                // �ﵽ���? 99������
                count_bcd_reg <= 8'h00; 
            end
        end
    end
end

assign count_bcd = count_bcd_reg;

endmodule