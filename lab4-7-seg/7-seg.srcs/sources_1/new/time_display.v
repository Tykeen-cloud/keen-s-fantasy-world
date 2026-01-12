`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/31 21:44:25
// Design Name: 
// Module Name: time_display
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


module time_display (
    input wire clk,             
    input wire rst_n,         
    input wire clk_scan,        
    input wire [31:0] data_bcd_in, 
    
    output wire [7:0] an,     
    output wire [7:0] seg       
);
reg [2:0] scan_addr = 3'd0; 
reg clk_scan_d1 = 1'b0; 

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        clk_scan_d1 <= 1'b0;
    end else begin
        clk_scan_d1 <= clk_scan;
    end
end

wire clk_scan_posedge = clk_scan & (~clk_scan_d1);

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        scan_addr <= 3'd0; 
    end else if (clk_scan_posedge) begin
        if (scan_addr == 3'd7) begin
            scan_addr <= 3'd0;
        end else begin
            scan_addr <= scan_addr + 3'd1;
        end
    end
end
reg [3:0] current_bcd_data;

always @(*) begin
    case (scan_addr)
        3'd0: current_bcd_data = data_bcd_in[3:0];   // DK0
        3'd1: current_bcd_data = data_bcd_in[7:4];   // DK1
        3'd2: current_bcd_data = data_bcd_in[11:8];  // DK2
        3'd3: current_bcd_data = data_bcd_in[15:12]; // DK3
        3'd4: current_bcd_data = data_bcd_in[19:16]; // DK4
        3'd5: current_bcd_data = data_bcd_in[23:20]; // DK5
        3'd6: current_bcd_data = data_bcd_in[27:24]; // DK6
        3'd7: current_bcd_data = data_bcd_in[31:28]; // DK7
        default: current_bcd_data = 4'hF; 
    endcase
end


reg [7:0] an_reg; 

always @(*) begin
    case (scan_addr)
        3'd0: an_reg = 8'hFE; // 选中 DK0
        3'd1: an_reg = 8'hFD; // 选中 DK1
        3'd2: an_reg = 8'hFB; // 选中 DK2
        3'd3: an_reg = 8'hF7; // 选中 DK3
        3'd4: an_reg = 8'hEF; // 选中 DK4
        3'd5: an_reg = 8'hDF; // 选中 DK5
        3'd6: an_reg = 8'hBF; // 选中 DK6
        3'd7: an_reg = 8'h7F; // 选中 DK7
        default: an_reg = 8'hFF; // 全灭
    endcase
end

assign an = an_reg; 


reg [7:0] seg_reg; 

always @(*) begin
    case (current_bcd_data)
        // D7 (dp) 默认设置为 0 (亮)
        4'd0: seg_reg = 8'b1100_0000; // 0 + dp (0xxxxxxx)
        4'd1: seg_reg = 8'b1111_1001; // 1 + dp 
        4'd2: seg_reg = 8'b1010_0100; // 2 + dp
        4'd3: seg_reg = 8'b1011_0000; // 3 + dp
        
        4'd4: seg_reg = 8'b1001_1001; // 4 + dp (根据常见段码)
        4'd5: seg_reg = 8'b1001_0010; // 5 + dp
        4'd6: seg_reg = 8'b1000_0010; // 6 + dp
        4'd7: seg_reg = 8'b1111_1000; // 7 + dp
        4'd8: seg_reg = 8'b1000_0000; // 8 + dp
        4'd9: seg_reg = 8'b1001_0000; // 9 + dp
        default: seg_reg = 8'b1111_1111; // 其他值（全灭，dp 也灭）
    endcase
end

assign seg = seg_reg;

endmodule
