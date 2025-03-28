// 本模块负责在七段数码管上展示温湿度以及用三色灯程度

module data_display(
    input clk,                      // E3 系统时钟，不用分频，数码管已经集成了分频模块
    input [15:0] temp,              // 温度
    input [15:0] humi,              // 湿度
    input ena,                      // 使能信号

    /* 七段数码管部分 */
    output [7:0] oData,             // 存放七段数码管的值，用来硬件绑定
    output [7:0] set,                // 选择的通道

    /* 三色灯部分 */
    output pwm_red_t,            // PWM 红色输出
    output pwm_green_t,          // PWM 绿色输出
    output pwm_blue_t,            // PWM 蓝色输出

    output pwm_red_h,            // PWM 红色输出
    output pwm_green_h,          // PWM 绿色输出
    output pwm_blue_h            // PWM 蓝色输出
);

reg [39:0] iData; // 七段数码管的输入
reg [15:0] abs_temp; // 温度的绝对值
reg [15:0] modified_humi; // 修改后的湿度，去掉最高位，因为传感器不太对劲
reg [23:0] rgb_temp;   // 三色灯的输入
reg [23:0] rgb_humi;   // 三色灯的输入

combine_display7 u_display7 (
    .clk(clk),
    .sel(4'b1111),
    .iData(iData),
    .isDot(8'h22),
    .oData(oData),
    .set(set)
);

tri_LED u_tri_LED_temp (
    .clk(clk),
    .rgb(rgb_temp),
    .ena(ena),
    .pwm_red(pwm_red_t),
    .pwm_green(pwm_green_t),
    .pwm_blue(pwm_blue_t)
);

tri_LED u_tri_LED_humi (
    .clk(clk),
    .rgb(rgb_humi),
    .ena(ena),
    .pwm_red(pwm_red_h),
    .pwm_green(pwm_green_h),
    .pwm_blue(pwm_blue_h)
);

// 对七段数码管的处理
always @(*)
begin
    iData[39:35] = 5'b10111; // T
    iData[19:15] = 5'b11000; // H
    abs_temp = temp;        // 初始的，可能为负，为了消除 latch warning
    // 温度
    if (temp[15] == 1) // 零下
    begin
        // 先把温度取绝对值
        abs_temp = temp & 16'h7FFF;
        if (abs_temp > 99) // 三位数，显示不下
        begin
            iData[34:20] = 15'b100001010110110; // T.Lo
        end
        else
        begin
            iData[34:30] = 5'b11111; // -
            iData[29:25] = (abs_temp / 10) % 10;
            iData[24:20] = abs_temp % 10;
        end
    end
    else // 零上
    begin
            iData[34:30] = (abs_temp / 100) % 10;
            iData[29:25] = (abs_temp / 10) % 10;
            iData[24:20] = abs_temp % 10;
    end

    // 湿度
    modified_humi = humi & 16'h7FFF; // 去掉最高位
    iData[14:10] = (modified_humi / 100) % 10;
    iData[9:5] = (modified_humi / 10) % 10;
    iData[4:0] = modified_humi % 10;     
end

// 对三色灯的处理
always @(*)
begin
    // 温度
    if (temp[15] == 1) // 零下
        rgb_temp = 24'h2347BD; // 蓝色
    else // 零上
    begin
        if (temp > 250)
            rgb_temp = 24'hB30600; // 红色
        else if (temp < 180)
            rgb_temp = 24'h2347BD; // 蓝色
        else
            rgb_temp = 24'h29AF34; // 绿色
    end

    // 湿度
    if (modified_humi > 700)
        rgb_humi = 24'h2347BD; // 蓝色
    else if (modified_humi < 400)
        rgb_humi = 24'hB30600; // 红色
    else
        rgb_humi = 24'h29AF34; // 绿色
end
endmodule