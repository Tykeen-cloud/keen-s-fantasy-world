`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/05 21:16:59
// Design Name: 
// Module Name: string_send
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


module string_send(
    input  wire clk,
    input  wire rst,
    output wire txo
);


localparam integer STRING_LENGTH = 15;
localparam integer INDEX_WIDTH   = 5;


function [7:0] get_char;
    input [INDEX_WIDTH-1:0] index;
    begin
        case (index)
            0:  get_char = 8'h68; // h
            1:  get_char = 8'h69; // i
            2:  get_char = 8'h74; // t
            3:  get_char = 8'h73; // s
            4:  get_char = 8'h7A; // z
            5:  get_char = 8'h32; // 2
            6:  get_char = 8'h30; // 0
            7:  get_char = 8'h32; // 2
            8:  get_char = 8'h34; // 4
            9:  get_char = 8'h33; // 3
            10: get_char = 8'h31; // 1
            11: get_char = 8'h31; // 1
            12: get_char = 8'h33; // 3
            13: get_char = 8'h33; // 3
            14: get_char = 8'h36; // 6
            
            
            default: get_char = 8'h00;
        endcase
    end
endfunction

// -------------------- 状态定义 --------------------
localparam [1:0] IDLE_ST = 2'b00;
localparam [1:0] SEND_ST = 2'b01;
localparam [1:0] WAIT_ST = 2'b10;

// -------------------- 信号定义 --------------------
reg [1:0] current_state, next_state;
reg [INDEX_WIDTH-1:0] char_index = 0;
reg [7:0] tx_data_out;
reg tx_start_req_r;

wire tx_busy;
wire tx_done;

reg start_001s_reg = 0;
reg start_02s_reg  = 0;
wire tx_001_done;
wire tx_02_done;


reg tx_done_d;
wire tx_done_pos = tx_done & ~tx_done_d;
always @(posedge clk or posedge rst)
    if (rst) tx_done_d <= 0;
    else     tx_done_d <= tx_done;

// -------------------- 定时器 --------------------
break_time u_break_time(
    .clk(clk),
    .rst(rst),
    .start_001(start_001s_reg),
    .start_02(start_02s_reg),
    .done_001(tx_001_done),
    .done_02(tx_02_done)
);

// -------------------- UART --------------------
uart_send my_uart_send(
    .clk(clk),
    .rst(rst),
    .valid(tx_start_req_r),
    .data(tx_data_out),
    .dout(txo),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
);

// -------------------- 定时控制 --------------------
always @(posedge clk or posedge rst) begin
    if (rst)
        start_001s_reg <= 1'b0;
    else if (tx_done_pos && char_index < STRING_LENGTH - 1)
        start_001s_reg <= 1'b1;
    else if (tx_001_done)
        start_001s_reg <= 1'b0;
end
always @(posedge clk or posedge rst) begin
    if (rst)
        start_02s_reg <= 1'b0;
    else if (current_state == IDLE_ST && !start_02s_reg)
        start_02s_reg <= 1'b1;
    else if (tx_02_done)
        start_02s_reg <= 1'b0;
end


// -------------------- 状态寄存 --------------------
always @(posedge clk or posedge rst)begin
    if (rst) current_state <= IDLE_ST;
    else     current_state <= next_state;
end
// -------------------- 状态跳转逻辑 --------------------
always @(*) begin
    case (current_state)
        IDLE_ST: begin
            if (tx_02_done)
                next_state = SEND_ST;
        end
        SEND_ST: begin
            if (tx_done_pos) begin
                if (char_index == STRING_LENGTH - 1)
                    next_state = IDLE_ST;
                else
                    next_state = WAIT_ST;
            end
        end
        WAIT_ST: begin
            if (tx_001_done && !tx_busy)
                next_state = SEND_ST;
        end
    endcase
end

// -------------------- 数据与发送控制 --------------------
always @(posedge clk or posedge rst) begin
    if (rst)
        char_index <= 0;
    else if (current_state == IDLE_ST && next_state == SEND_ST)
        char_index <= 0;
    else if (current_state == WAIT_ST && next_state == SEND_ST)
        char_index <= char_index + 1;
end
always @(posedge clk or posedge rst) begin
    if (rst)
        tx_data_out <= 8'h00;
    else if (current_state == IDLE_ST && next_state == SEND_ST)
        tx_data_out <= get_char(0);
    else if (current_state == WAIT_ST && next_state == SEND_ST)
        tx_data_out <= get_char(char_index + 1);
end
always @(posedge clk or posedge rst) begin
    if (rst)
        tx_start_req_r <= 1'b0;
    else if ((current_state == IDLE_ST && next_state == SEND_ST) || 
             (current_state == WAIT_ST && next_state == SEND_ST))
        tx_start_req_r <= 1'b1;
    else
        tx_start_req_r <= 1'b0;
end

endmodule