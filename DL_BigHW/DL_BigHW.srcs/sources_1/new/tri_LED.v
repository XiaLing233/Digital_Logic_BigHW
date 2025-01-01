// 针对不同的 24 位 rgb 三色输入，显示对于的颜色
// 利用的原理是 PWM 调节占空比

module tri_LED(
    input clk,             // 时钟信号，系统时钟就好了
    input [23:0] rgb,      // 三色在一起，从高到低是 R G B
    input ena,              // 使能信号，高电平有效
    output reg pwm_red,    // PWM 红色输出
    output reg pwm_green,  // PWM 绿色输出
    output reg pwm_blue    // PWM 蓝色输出
);
    reg [10:0] counter = 11'b0; // 计数器多一位，在保证对所有 RGB 支持的同时，确保占空比最大为 50%。还是太亮了，再加一位！

    // 计数器
    always @(posedge clk)
    begin
        counter <= counter + 1;
    end

    // 红色通道 PWM 生成
    always @(posedge clk)
    begin
        if (counter < rgb[23:16] && ena)
            pwm_red <= 1;
        else
            pwm_red <= 0;
    end

    // 绿色通道 PWM 生成
    always @(posedge clk && ena)
    begin
        if (counter < rgb[15:8])
            pwm_green <= 1;
        else
            pwm_green <= 0;
    end

    // 蓝色通道 PWM 生成
    always @(posedge clk && ena)
    begin
        if (counter < rgb[7:0])
            pwm_blue <= 1;
        else
            pwm_blue <= 0;
    end
endmodule
