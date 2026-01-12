`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/10/13 15:32:36
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
`timescale 1ns/1ps         // 定义时间单位和时间精度

module decoder_38_sim();    //仿真代码的module无需定义输入输出

   // 定义需要用到的信号，若信号是在块语句里面用到，则定义为reg型，
   // 信号名可以任意，最好与测试模块的代码有相同的含义
   reg [2:0] data_in;         // 3位二进制数据输入
   reg [2:0] en;              // 3位使能信号输入
   wire [7:0] data_out;       // 8位输出

   //被测试模块实例化
   decoder_38 u_decoder_38(    //被测试模块名decoder_38写在前面
         .data_in(data_in),    // 指定testbenablech中定义的信号与被测试模块信号的连接关系
         .en(en),                // ()括号里面的信号是testbenablech中定义的
         .data_out(data_out)
   );

   initial    // initial块中的语句只执行一次，initial只用于testbench，不应该用在功能代码中
   begin
       en = 3'b000; data_in = 3'b000;               // 默认从0ns开始，若0ns不做初始化，系统会对输入赋值不定态度x
       #5 begin en = 3'b100;data_in = 3'b000; end   // 延时5个时间单位，即延时5ns
       #5 begin en = 3'b100;data_in = 3'b001; end   // 构造测试输入：使能端有效，输入遍历8种情况 
       #5 begin en = 3'b100;data_in = 3'b010; end
       #5 begin en = 3'b100;data_in = 3'b011; end  
       #5 begin en = 3'b100;data_in = 3'b100; end
       #5 begin en = 3'b100;data_in = 3'b101; end    
       #5 begin en = 3'b100;data_in = 3'b110; end
       #5 begin en = 3'b100;data_in = 3'b111; end  
       #5 begin en = 3'b101;data_in = 3'b000; end   //构造测试输入：使能端无效
       #10 $finish ;                                // 结束仿真，不然系统会一直运行，直到系统设置的默认的仿真时间到（一般是1000ns）     
   end

   endmodule