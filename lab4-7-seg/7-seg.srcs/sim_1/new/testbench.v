`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/31 21:49:18
// Design Name: 
// Module Name: testbench
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


`timescale 1ns / 1ps

module top_tb;

    // ----------------------------------------------------
    // 1. 信号定义
    // ----------------------------------------------------
    reg clk;
    reg rst;        // S1: 异步复位 (高电平有效)
    reg en;         // SW0: 数码管使能 (高电平有效)
    reg s3;         // S3: 计数按钮
    reg control;    // S2: 启停控制按钮

    wire [7:0] led_en; // 位选
    wire [7:0] led_cx; // 段选
    
    // 内部信号监视 (用于调试)
    wire [31:0] display_data;
    wire [7:0] cnt_30_debug;
    wire [7:0] cnt_s3_debug;
    wire [7:0] cntplus_s3_debug;

    // ----------------------------------------------------
    // 2. 例化待测模块 (UUT)
    // ----------------------------------------------------
    top uut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .s3(s3),
        .control(control),
        .led_en(led_en),
        .led_cx(led_cx)
    );

    // ----------------------------------------------------
    // 3. 调试信号连接 (方便在波形中查看)
    // ----------------------------------------------------
    assign display_data     = uut.display;
    assign cnt_30_debug     = uut.cnt_30;
    assign cnt_s3_debug     = uut.cnt_s3;
    assign cntplus_s3_debug = uut.cntplus_s3;

    // ----------------------------------------------------
    // 4. 时钟生成 (50MHz)
    // ----------------------------------------------------
    parameter CLK_PERIOD = 20; // 50MHz (20ns)
    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD / 2) clk = ~clk;
    end
  // ----------------------------------------------------
    // 5. 激励生成 (Test Scenarios)
    // ----------------------------------------------------
    initial begin
        $dumpfile("top.vcd"); // VCD波形文件
        $dumpvars(0, top_tb); // 导出所有信号

        // --- #T0: 初始化与复位 (S1) ---
        $display("T=%t: [Test 0] System Reset (S1 pressed).", $time);
        rst     = 1'b1;     // S1 按下 (复位)
        en      = 1'b0;     // SW0 关闭 (数码管熄灭)
        s3      = 1'b0;     // S3 未按下
        control = 1'b0;     // S2 未按下
        #(CLK_PERIOD * 10); // 保持复位 200ns
        
        rst     = 1'b0;     // S1 释放 (结束复位)
        en      = 1'b1;     // SW0 打开 (数码管使能)
        $display("T=%t: [Test 0] Reset released. Display enabled.", $time);
        
        // 要求: 复位后 cnt_30 自动开始计数 (0.1s 间隔)
        // (等待 cnt_30 计数到 3)
        #(300_000_000 + CLK_PERIOD); // 等待 300ms (3个 0.1s 周期)
        $display("T=%t: [Test 1] cnt_30 should be '03'.", $time); // 此时 cnt_30 应为 03
        
        // --- #T1: 测试 S2 (control) 暂停功能 ---
        $display("T=%t: [Test 2] Pressing S2 (control) to PAUSE.", $time);
        control = 1'b1;     // S2 按下
        #(100_000);         // 模拟按键按压 100us
        control = 1'b0;     // S2 释放
        
        #(500_000_000);     // 等待 500ms (0.5s)
        $display("T=%t: [Test 2] cnt_30 should still be '03' (Paused).", $time); // cnt_30 应保持在 03
        
        // --- #T2: 测试 S2 (control) 恢复功能 ---
        $display("T=%t: [Test 3] Pressing S2 (control) to RESUME.", $time);
        control = 1'b1;     // S2 再次按下
        #(100_000);         // 模拟按键按压 100us
        control = 1'b0;     // S2 释放
        
        #(300_000_000);     // 等待 300ms (0.3s)
        $display("T=%t: [Test 3] cnt_30 should be '06' (Resumed).", $time); // cnt_30 应为 03 + 3 = 06

        // --- #T3: 测试 S3 (带消抖 vs 不带消抖) ---
        $display("T=%t: [Test 4] Simulating a BOUNCY press on S3.", $time);
        // 模拟一次抖动的按键 (总时长 < 20ms)
        s3 = 1'b1; #(1_000_000); // 按下 1ms
        s3 = 1'b0; #(2_000_000); // 弹起 2ms
        s3 = 1'b1; #(1_000_000); // 按下 1ms
        s3 = 1'b0; #(3_000_000); // 弹起 3ms
        s3 = 1'b1; #(20_000_000); // 稳定按下 20ms
        s3 = 1'b0; // 最终释放
        
        #(50_000_000); // 等待状态稳定
        // 结果: cnt_s3 (不消抖) 应计数3次; cntplus_s3 (消抖) 应计数1次
        $display("T=%t: [Test 4] cnt_s3 (no-debounce) should be '03'.", $time);
        $display("T=%t: [Test 4] cntplus_s3 (debounce) should be '01'.", $time);

        // --- #T4: 测试 S3 长按 (Hold) ---
        $display("T=%t: [Test 5] Simulating a LONG press on S3.", $time);
        s3 = 1'b1; // 按下 S3
        #(100_000_000); // 保持按下 100ms
        s3 = 1'b0; // 释放 S3
        
        #(50_000_000); // 等待状态稳定
        // 结果: 两个计数器都只应该再增加1 (总数变为 04 和 02)
        $display("T=%t: [Test 5] cnt_s3 should be '04'.", $time);
        $display("T=%t: [Test 5] cntplus_s3 should be '02'.", $time);

        // --- #T5: 测试 SW0 (en) 关闭显示 ---
        $display("T=%t: [Test 6] Disabling display (en=0).", $time);
        en = 1'b0; // 关闭数码管使能
        // 此时 led_en 输出应为 8'hFF
        
        // 在显示关闭时，等待 cnt_30 继续计数
        #(500_000_000); // 等待 500ms (0.5s)
        // (cnt_30 此时应为 06 + 0.3s + 0.05s + 0.1s + 0.5s = 06 + 9 ticks = 15)
        
        $display("T=%t: [Test 6] Re-enabling display (en=1).", $time);
        en = 1'b1; // 重新打开显示
        // 此时应显示: 36 04 02 15
        #(10_000_000); // 等待 10ms

        // --- #T6: 测试 cnt_30 溢出 (30 -> 0) ---
        $display("T=%t: [Test 7] Waiting for cnt_30 to wrap around (30 -> 0).", $time);
        // 当前 cnt_30 = 15. 还需要 15 拍 (1.5s) 到达 30, 再 1 拍 (0.1s) 到达 0
        #(1_600_000_000); // 等待 1.6s
        $display("T=%t: [Test 7] cnt_30 should be '00' (wrapped).", $time); // 此时 cnt_30 应为 00

        // --- #T7: 测试 S1 (rst) 最终复位 ---
        $display("T=%t: [Test 8] Final system reset (S1).", $time);
        rst = 1'b1; // S1 按下 (复位)
        #(100_000); // 保持复位 100us
        rst = 1'b0; // S1 释放
        
        #(10_000_000); // 等待 10ms
        // 此时所有计数器应清零: 36 00 00 00
        $display("T=%t: [Test 8] All counters should be '00'.", $time);
        
        // 验证 cnt_30 自动重启
        #(100_000_000 + CLK_PERIOD); // 等待 100ms
        $display("T=%t: [Test 8] cnt_30 should restart automatically to '01'.", $time);

        // --- 结束 ---
        $display("T=%t: [Test] Simulation Finished.", $time);
        $finish;
    end

endmodule