`timescale 1ns / 1ns

module tri_LED_tb;
    reg clk;             // 时钟信号
    reg [23:0] rgb;       // 三色在一起，从高到低是 R G B
    wire pwm_red;        // PWM 红色输出
    wire pwm_green;      // PWM 绿色输出
    wire pwm_blue;      // PWM 蓝色输出

    tri_LED uut (
        .clk(clk),
        .rgb(rgb),
        .pwm_red(pwm_red),
        .pwm_green(pwm_green),
        .pwm_blue(pwm_blue)
    );

    initial
    begin
        clk = 0;

        repeat (600)
        #1 clk = ~clk;
    end

    initial
    begin
        rgb = 24'h3ecf7f;
    end

endmodule
