`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/15 21:06:30
// Design Name: 
// Module Name: test
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


// id_sender 模块的仿真测试文件
`timescale 1ns / 1ps

module id_sender_tb;

    // -------------------- 信号定义 --------------------
    reg         clk;
    reg         rst;
    reg         btn;          // 模拟按键输入 (s3)
    
    // 模拟 UART 发送模块的输入/反馈
    reg         tx_busy;
    reg         tx_done;
    integer i=0;
    // DUT 输出
    wire        valid;        // DUT 请求发送数据
    wire [7:0]  data_tosend;  // DUT 要发送的数据

    // -------------------- 仿真参数 --------------------
    parameter CLK_PERIOD = 10;          // 10ns 时钟周期
    parameter DEBOUNCE_CYCLES = 100_000; // 简化消抖周期以加快仿真

    // -------------------- DUT 实例化 --------------------
    id_sender DUT (
        .clk(clk),
        .rst(rst),
        .btn(btn),
        .tx_busy(tx_busy),
        .tx_done(tx_done),
        .valid(valid),
        .data_tosend(data_tosend)
    );

    // -------------------- 时钟和复位生成 --------------------
    initial begin
        clk = 0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
    
    initial begin
        $display("--- Starting ID Sender Simulation ---");
        rst = 1;
        btn = 1;    // 按键初始未按下
        tx_busy = 0;
        tx_done = 0;
        
        #(CLK_PERIOD * 5); // 保持复位
        rst = 0;
        $display("[%0d] Reset finished. System is IDLE.", $time / CLK_PERIOD);
    end

    // -------------------- UART 模拟任务 --------------------
    // 模拟 UART 发送模块对 valid 信号的响应
    task mock_uart_tx;
        begin
            @(posedge clk);
            tx_busy = 1; // UART 收到有效信号，开始工作
            tx_done = 0;
            
            // 假设 UART 发送一个字节需要一段较长的时间
            # (CLK_PERIOD * 50); 
            
            // 记录发送的字符
            $display("[%0d] MOCK_TX: Received 0x%h ('%c'), setting tx_done=1.", 
                     $time / CLK_PERIOD, data_tosend, data_tosend);
            
            tx_done = 1; // 发送完成
            
            @(posedge clk);
            tx_busy = 0; // 完成后，tx_busy 和 tx_done 都清零
            tx_done = 0;
        end
    endtask

    // -------------------- 按键输入任务 --------------------
    task press_button;
        begin
            $display("\n[%0d] SIM: Pressing button (btn=0)...", $time / CLK_PERIOD);
            btn = 0;
            # (CLK_PERIOD * 20); // 模拟按键按下
            $display("[%0d] SIM: Releasing button (btn=1)...", $time / CLK_PERIOD);
            btn = 1;
        end
    endtask

    // -------------------- 主测试激励 --------------------
    initial begin
        # (CLK_PERIOD * 10); // 等待复位完全结束

        // 1. 模拟按键按下 (触发学号发送序列)
        press_button;
        
        // 2. 监视并模拟 UART 响应
        for ( i = 0; i < 11; i = i + 1) begin // 学号10位 + 1位用于验证发送结束
            
            // 等待 DUT 发送 valid 信号
            // 注意：第一次 valid 信号会在按键消抖后触发
            @(posedge clk) while (!valid) begin
                if ($time > 1000_000 * CLK_PERIOD) begin
                    $display("*** ERROR: Timeout waiting for valid signal! ***");
                    $stop;
                end
                // 特殊处理：将消抖周期设短，避免仿真时间过长
                // 在这里可以观察到 debounce_cnt 跑满 DEBOUNCE_MAX (简化版)
                if (i == 0 && $time / CLK_PERIOD > 100_000) 
                    $display("[%0d] INFO: Waiting for debounce completion...", $time / CLK_PERIOD);
            end

            // 如果 valid 触发了，模拟 UART 接收并处理
            if (i < 10) begin
                $display("[%0d] DUT_VALID: index=%0d, data_tosend=0x%h('%c').", 
                         $time / CLK_PERIOD, i, data_tosend, data_tosend);
                mock_uart_tx;
            end else begin
                // 验证发送结束
                $display("\n[%0d] SIM: All 10 digits sent. Checking for sending=0...", $time / CLK_PERIOD);
                # (CLK_PERIOD * 5); 
            end
        end

        $display("\n--- Simulation finished ---");
        $stop;
    end
    
    // -------------------- 监视 (可选) --------------------
    // 打印关键信号，辅助调试
    

endmodule
