`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/11/06 12:48:31
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


// 文件名: string_send_tb.v
// 仿真模块：用于测试 string_send (顶层 FSM) 模块

`timescale 1ns / 1ps

module uart_send_tb;

reg clk;
reg rst;
reg valid;
reg [7:0] data;
wire dout;
wire tx_busy;
wire tx_done;

uart_send u_uart_send (
    .clk(clk),
    .rst(rst),
    .valid(valid),
    .data(data),
    .dout(dout),
    .tx_busy(tx_busy),
    .tx_done(tx_done)
);

localparam CLOCK_FREQ = 100*1e6;        // clock freq: 100MHz
localparam PERIOD     = 1e9 / CLOCK_FREQ;   // clock cycle: 10ns
localparam BAUD_RATE  = 9600;
localparam DIVIDER    = CLOCK_FREQ / BAUD_RATE; // ≈10417

always #(PERIOD/2) clk = ~clk;

integer bit_index = 0;
reg [9:0] expected_bits;
reg [3:0] all_check_error;
reg check_error;

initial begin
    clk   = 0;
    rst   = 1'b1;
    valid = 1'b0;
    data  = 8'h00;
    check_error     = 1'b0;
    all_check_error = 1'b0;
    expected_bits   = 10'h0;

    #(10*PERIOD);
    rst = 1'b0;
    #(2*PERIOD);

    // test case1: 8'hA5 (10100101)
    send_byte(8'hA5);
    #(50000*PERIOD);

    // test case2: 8'h3C (00111100)
    send_byte(8'h3C);
    #(50000*PERIOD);

    // test case3: 8'hFF (11111111)
    send_byte(8'hFF);
    #(50000*PERIOD);

    // test case4: 8'h00 (00000000)
    send_byte(8'h00);
    #(50000*PERIOD);

    // test case5: 8'h5A (01011010)
    send_byte(8'h5A);
    #(50000*PERIOD);

    if (!all_check_error)
        $display("All tests passed successfully!");
    else
        $display("%d test(s) failed!", all_check_error);

    $display("UART baud rate = %d, freq divider = %d", BAUD_RATE, DIVIDER);
    $finish;
end


// -------------------- send_byte 封装 --------------------
task send_byte;
    input [7:0] i_data;
    begin
        data  = i_data;
        valid = 1'b1;
        expected_bits = {1'b1, i_data, 1'b0}; // stop + data + start
        #PERIOD;  // valid 保持一个时钟
        valid = 1'b0;

        // 等待发送开始
        wait (tx_busy == 1);
        // 检查波形输出
        check_uart_output(i_data);
        // 等待发送结束
        wait (tx_done == 1);
    end
endtask


// -------------------- 输出校验任务 --------------------
task check_uart_output;
    input [7:0] i_data;
    begin
        $display(" Test case %x start", i_data);
        bit_index   = 0;
        check_error = 0;

        // UART 每位持续 DIVIDER 个 clk 周期
        // 起始位 + 8位数据 + 停止位
        repeat (10) begin
            #(DIVIDER*PERIOD); // 等一个 bit 时间
            if (dout !== expected_bits[bit_index]) begin
                $display(" Error at time %t, bit %0d: expected %b, got %b",
                         $time, bit_index, expected_bits[bit_index], dout);
                check_error = 1'b1;
            end
            bit_index = bit_index + 1;
        end

        if (check_error) begin
            all_check_error = all_check_error + 1'b1;
            $display(" Test case %x failed\n", i_data);
        end else
            $display(" Test case %x passed\n", i_data);
    end
endtask

endmodule