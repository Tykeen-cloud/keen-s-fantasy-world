`timescale 1ns / 1ps
module new_light(
input wire clk,
input wire rst,
input wire button,
input wire [1:0] fre_set,
input wire dir_set,
output reg [7:0] led
);
wire led_tick;

counter u_counter(
.clk(clk),
.rst(rst),
.fre_set(fre_set),
.tick(led_tick)
);
reg run_en;
reg button_r1;
reg button_r2;
reg button_r3;
wire button_posedge;
always@(posedge clk or posedge rst)begin
    if(rst)begin
        button_r1<=1'b0;
        button_r2<=1'b0;
        button_r3<=1'b0;
    end else begin
        button_r1<=button;
        button_r2<=button_r1;
        button_r3<=button_r2;
    end
end
assign button_posedge = button_r2 & (~button_r3);
always@(posedge clk or posedge rst)begin
if(rst)begin
run_en<=1'b0;
end else if(button_posedge)begin
run_en<=~run_en;
end
end
always@(posedge clk or posedge rst)begin
if(rst)begin
led<=8'b00000001;
end
else if (run_en && led_tick && dir_set)begin
led<={led[6:0],led[7]};
end
else if(run_en && led_tick && ~dir_set)begin
led<={led[0],led[7:1]};
end
else
led<=led;
end 
endmodule
