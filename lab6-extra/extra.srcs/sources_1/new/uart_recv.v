`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/13 19:07:40
// Design Name: 
// Module Name: uart_recv
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

module uart_recv(
    input  wire        clk,
    input  wire        rst,
    input  wire        din,

    output reg         valid,         // 接收到新字节脉冲
    output reg         enter_detect,  // 回车（0x0D）单脉冲

    output reg         start_match,
    output reg         stop_match,
    output reg         hitsz_match,

    // 握手接口：输出 result 并等待顶层确认
    output reg  [7:0]  result_code,   // ASCII 编码结果（保持直到 result_ack）
    output reg         result_valid,  // 持续有效直到 result_ack
    input  wire        result_ack     // 顶层读走后拉高一拍确认
);

    // -------------------- 状态定义 (UART 接收 FSM) --------------------
    localparam IDLE  = 3'b000;
    localparam START = 3'b001;
    localparam DATA  = 3'b010;
    localparam STOP  = 3'b011;

    reg [2:0] state, next_state;
    reg [2:0] prev_state;

    // -------------------- UART 定时参数 --------------------
    localparam integer CLK_PER_BIT = 10416;
    localparam integer CNT_WIDTH   = 14;

    reg [CNT_WIDTH-1:0] bit_cnt = 0;
    reg [3:0]  data_index = 0;
    reg [7:0]  data_reg   = 0;

    // -------------------- 字符串匹配 FSM 状态定义 --------------------
    localparam [3:0] M_IDLE  = 4'd0;
    localparam [3:0] M_S     = 4'd1; // 's'
    localparam [3:0] M_ST    = 4'd2; // 'st'
    localparam [3:0] M_STA   = 4'd3; // 'sta'
    localparam [3:0] M_STAR  = 4'd4; // 'star'
    localparam [3:0] M_START = 4'd5; // 'start'
    localparam [3:0] M_STO   = 4'd6; // 'sto'
    localparam [3:0] M_STOP  = 4'd7; // 'stop'
    localparam [3:0] M_H     = 4'd8; // 'h'
    localparam [3:0] M_HI    = 4'd9; // 'hi'
    localparam [3:0] M_HIT   = 4'd10; // 'hit'
    localparam [3:0] M_HITS  = 4'd11; // 'hits'
    localparam [3:0] M_HITSZ = 4'd12; // 'hitsz'

    reg [3:0] match_state, next_match_state;

    // -------------------- 信号定义 --------------------
    wire bit_end  = (bit_cnt == CLK_PER_BIT - 1);
    wire bit_half = (bit_cnt == CLK_PER_BIT / 2);

    // 延迟 enter_detect 1 拍，用于下一拍清 match（可选保留）
    reg enter_detect_d;

    // 记录是否已收到回车（等待下一个字符串开始时清 match）
    reg cr_seen;

    // ASCII 常量（更直观）
    localparam [7:0] R_NO_MATCH = "0"; // 8'h30
    localparam [7:0] R_STOP     = "1"; // 8'h31
    localparam [7:0] R_START    = "2"; // 8'h32
    localparam [7:0] R_HITSZ    = "3"; // 8'h33
    

    always @(posedge clk or posedge rst) begin
        if (rst) enter_detect_d <= 0;
        else     enter_detect_d <= enter_detect;
    end

    // 记录上一个 state，用于检测 IDLE->START 边沿（即字符开始）
    always @(posedge clk or posedge rst) begin
        if (rst) prev_state <= IDLE;
        else     prev_state <= state;
    end

    // cr_seen：在检测到回车时置位；在检测到下一个字符串开始（IDLE->START）时复位
    always @(posedge clk or posedge rst) begin
        if (rst)
            cr_seen <= 0;
        else if (state == STOP && bit_end && data_reg == 8'h0D)
            cr_seen <= 1; // 收到回车，标记字符串结束
        else if (state == START && prev_state == IDLE && cr_seen)
            cr_seen <= 0; // 下一个字符串开始，清标记
    end

    // ============================================================
    // 状态机切换 (UART 接收 FSM)
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (~din) next_state = START;
            START: if (bit_end) next_state = DATA;
            DATA:  if (bit_end && data_index == 7) next_state = STOP;
            STOP:  if (bit_end) next_state = IDLE;
        endcase
    end

    // ============================================================
    // bit 计数器
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            bit_cnt <= 0;
        else if (state == IDLE)
            bit_cnt <= 0;
        else if (bit_end)
            bit_cnt <= 0;
        else
            bit_cnt <= bit_cnt + 1;
    end

    // ============================================================
    // data_index 计数
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_index <= 0;
        else if (state == IDLE)
            data_index <= 0;
        else if (state == DATA && bit_end && data_index != 7)
            data_index <= data_index + 1;
    end

    // ============================================================
    // DATA 区间采样
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            data_reg <= 0;
        else if (state == DATA && bit_half)
            data_reg[data_index] <= din;
    end

    // ============================================================
    // 字符串匹配状态机 - 状态寄存器
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            match_state <= M_IDLE;
        // 在每个新字节到达时 (state == STOP && bit_end)，更新 FSM 状态
        else if (state == STOP && bit_end)
            match_state <= next_match_state;
    end

    // ============================================================
    // 字符串匹配状态机 - 组合逻辑（下一状态）
    // ============================================================
    always @(*) begin
        // 默认：任何不匹配的字符都会使 FSM 重置。
        // 但是，如果下一个字符是 's' 或 'h'，则启动新的匹配。
        if (data_reg == "s")
            next_match_state = M_S;
        else if (data_reg == "h")
            next_match_state = M_H;
        else
            next_match_state = M_IDLE;

        // 覆盖：基于当前状态的特定转换
        case (match_state)
            M_IDLE: begin
                if (data_reg == "s")      next_match_state = M_S;
                else if (data_reg == "h") next_match_state = M_H;
                else                      next_match_state = M_IDLE;
            end
            M_S: begin
                if (data_reg == "t")      next_match_state = M_ST;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_ST: begin
                if (data_reg == "a")      next_match_state = M_STA;
                else if (data_reg == "o") next_match_state = M_STO;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_STA: begin
                if (data_reg == "r")      next_match_state = M_STAR;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_STAR: begin
                if (data_reg == "t")      next_match_state = M_START;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_START: begin // "start" 匹配后
                if (data_reg == "s")      next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_STO: begin
                if (data_reg == "p")      next_match_state = M_STOP;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_STOP: begin // "stop" 匹配后
                if (data_reg == "s")      next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_H: begin
                if (data_reg == "i")      next_match_state = M_HI;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_HI: begin
                if (data_reg == "t")      next_match_state = M_HIT;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_HIT: begin
                if (data_reg == "s")      next_match_state = M_HITS;
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_HITS: begin
                if (data_reg == "z")      next_match_state = M_HITSZ;
                else if (data_reg == "s") next_match_state = M_S; // 覆盖默认
                else if (data_reg == "t") next_match_state = M_ST;
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            M_HITSZ: begin // "hitsz" 匹配后
                if (data_reg == "s")      next_match_state = M_S; // 覆盖默认
                else if (data_reg == "h") next_match_state = M_H; // 覆盖默认
            end
            // default: 由 case 之外的默认赋值处理
        endcase
    end

    // ============================================================
    // valid 脉冲（收到完整字节）
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            valid <= 0;
        else if (state == STOP && bit_end)
            valid <= 1;
        else
            valid <= 0;
    end

    // ============================================================
    // 回车检测 enter_detect（单脉冲）
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst)
            enter_detect <= 0;
        else if (state == STOP && bit_end && data_reg == 8'h0D)
            enter_detect <= 1;
        else
            enter_detect <= 0;
    end

    // ============================================================
    // 匹配逻辑（粘滞）- [!! MODIFIED !!]
    // ============================================================
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            start_match <= 0;
            stop_match  <= 0;
            hitsz_match <= 0;
        end
        // 在新字节到达的 *同一拍*，检查 FSM 的 *下一状态* 是否为匹配状态
        else if (state == STOP && bit_end) begin
            if (next_match_state == M_START)
                start_match <= 1;
            if (next_match_state == M_STOP)
                stop_match  <= 1;
            if (next_match_state == M_HITSZ)
                hitsz_match <= 1;
        end
        // 清除逻辑保持不变：在新字符串开始时（上一行有 CR）清除
        else if (state == START && prev_state == IDLE && cr_seen) begin
            start_match <= 0;
            stop_match  <= 0;
            hitsz_match <= 0;
        end
    end

    // ============================================================
    // 结果握手逻辑（在检测到 CR 时写入 result 并保持，直到收到 result_ack）
    // ============================================================
    wire cur_start_match = start_match; // "start"
    wire cur_stop_match  = stop_match;  // "stop"
    wire cur_hitsz_match = hitsz_match; // "hitsz"

    wire [1:0] match_count = cur_start_match + cur_stop_match + cur_hitsz_match;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_valid <= 0;
            result_code  <= R_NO_MATCH;
        end
        else begin
            // 如果已存在未确认的结果，等待顶层 ack
            if (result_valid) begin
                if (result_ack) begin
                    result_valid <= 0;
                    result_code  <= R_NO_MATCH;
                end
            end
            else begin
                // 没有未确认的结果时，在检测到回车这拍写入结果并保持
                if (state == STOP && bit_end && data_reg == 8'h0D) begin
                    result_valid <= 1;
                    case (match_count)
                        2'd0: result_code <= R_NO_MATCH;
                        2'd1: begin
                            if (cur_stop_match)
                                result_code <= R_STOP;
                            else if (cur_start_match)
                                result_code <= R_START;
                            else
                                result_code <= R_HITSZ;
                        end
                        2'd2:begin
                            if(cur_stop_match && cur_start_match)
                                result_code<="4";
                            else if(cur_start_match && cur_hitsz_match)
                                result_code<="5";
                            else 
                                result_code<="6";
                            end
                        default: result_code <= "7";
                    endcase
                end
            end
        end
    end

endmodule