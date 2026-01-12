`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/11 23:27:06
// Design Name: 
// Module Name: seg_display
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


module seg_display (
    input  wire        clk,       // 100MHz 时钟
    input  wire        rst,
    input  wire [7:0]  data_in,   // 来自 uart_recv 的数据
    input  wire        valid,     // 数据有效（一个时钟周期高电平）
    output reg  [7:0]  seg,       // 段选输出
    output reg  [7:0]  an         // 位选输出
);
    //========================
    // 一、缓存最近6个字符
    //========================
    reg [7:0] buffer[0:5];   // 存放最近 6 个字符
    reg [7:0] char_count;    // 接收总字符数

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 6; i = i + 1)
                buffer[i] <= 8'd0;
        end
        else if (valid) begin
            // 左移缓存，新字符进入末尾
            for (i = 0; i < 5; i = i + 1)
                buffer[i] <= buffer[i+1];
            buffer[5] <= data_in;
        end
    end
   always @(posedge clk or posedge rst) begin
    if (rst)
        char_count <= 0;
    else if (valid)
        char_count <= char_count + 1;
end
    //========================
    // 二、数码管扫描控制
    //========================
    reg [2:0] scan_sel;             // 当前扫描位 0~7
    reg [15:0] scan_cnt;

    always @(posedge clk or posedge rst) begin
    if (rst)
        scan_cnt <= 0;
    else if (scan_cnt == 16'd49999)
        scan_cnt <= 0;
    else
        scan_cnt <= scan_cnt + 1;
end
   always @(posedge clk or posedge rst) begin
    if (rst)
        scan_sel <= 0;
    
    else if (scan_cnt == 16'd49999)
        scan_sel <= scan_sel + 1;
end
    //========================
    // 三、数码管数据选择
    //========================
    reg [7:0] digit;
    always @(*) begin
        case (scan_sel)
            3'd0: digit = char_count % 10;                  // 个位
            3'd1: digit = (char_count / 10) % 10;           // 十位
            3'd2: digit = ascii_to_hex(buffer[5]);
            3'd3: digit = ascii_to_hex(buffer[4]);
            3'd4: digit = ascii_to_hex(buffer[3]);
            3'd5: digit = ascii_to_hex(buffer[2]);
            3'd6: digit = ascii_to_hex(buffer[1]);
            3'd7: digit = ascii_to_hex(buffer[0]);
            default: digit = 8'hF1;
        endcase
    end

    //========================
    // 四、位选控制
    //========================
    always @(*) begin
        an = 8'b1111_1111;
        an[scan_sel] = 1'b0;  // 低电平选通
    end

    //========================
    // 五、段码译码
    //========================
    always @(*) begin
        case (digit)
            8'h00: seg = 8'b11000000;
            8'h01: seg = 8'b11111001;
            8'h02: seg = 8'b10100100;
            8'h03: seg = 8'b10110000;
            8'h04: seg = 8'b10011001;
            8'h05: seg = 8'b10010010;
            8'h06: seg = 8'b10000010;
            8'h07: seg = 8'b11111000;
            8'h08: seg = 8'b10000000;
            8'h09: seg = 8'b10010000;
            8'h0A: seg = 8'b10001000;
            8'h0B: seg = 8'b10000011;
            8'h0C: seg = 8'b11000110;
            8'h0D: seg = 8'b10100001;
            8'h0E: seg = 8'b10000110;
            8'h0F: seg = 8'b10001110;
            8'hF1:seg = 8'b11111111;
            default: seg = 8'b11111111;
        endcase
    end

    //========================
    // 六、ASCII转十六进制函数
    //========================
    function [7:0] ascii_to_hex;
        input [7:0] ascii;
        begin
            case (ascii)
                8'h30: ascii_to_hex = 8'h00; // '0'
                8'h31: ascii_to_hex = 8'h01;
                8'h32: ascii_to_hex = 8'h02;
                8'h33: ascii_to_hex = 8'h03;
                8'h34: ascii_to_hex = 8'h04;
                8'h35: ascii_to_hex = 8'h05;
                8'h36: ascii_to_hex = 8'h06;
                8'h37: ascii_to_hex = 8'h07;
                8'h38: ascii_to_hex = 8'h08;
                8'h39: ascii_to_hex = 8'h09;
                8'h41, 8'h61: ascii_to_hex = 8'h0A; // 'A' or 'a'
                8'h42, 8'h62: ascii_to_hex = 8'h0B;
                8'h43, 8'h63: ascii_to_hex = 8'h0C;
                8'h44, 8'h64: ascii_to_hex = 8'h0D;
                8'h45, 8'h65: ascii_to_hex = 8'h0E;
                8'h46, 8'h66: ascii_to_hex = 8'h0F;
                default: ascii_to_hex =8'hF1;
            endcase
        end
    endfunction

endmodule