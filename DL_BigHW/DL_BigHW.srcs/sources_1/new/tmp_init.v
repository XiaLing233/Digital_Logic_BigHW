// 对初始温度和偏差值的设定，本模块负责接收按键和开关的输入，输出理想的温度值存到寄存器里，也负责实现七段数码管的显示
module temperature_control (
    input clk,       // E3 系统时钟，不用分频，数码管已经集成了分频模块
    input rst,       // 重置，高位重置，绑定到一个开关 V10
    input btn_inc,   // 增加，上按钮 M18
    input btn_dec,   // 减少，下按钮 P18
    input btn_left,  // 左移，左按钮 P17
    input btn_right, // 右移，右按钮 M17
    input btn_save,  // 保存，中按钮 N17

    // 这两个不需要输出，是给调用它的函数用的。不过现在在调试呢，给它绑定个 led 灯吧
    output reg [8:0] ideal_temp, // 理想温度，初始值为260 注意，温度和偏差值为了和传感器对应，做了 *10 处理，九位够了，511
    output reg [5:0] temp_offset, // 偏差值，初始值为30，六位够了，63
    output reg set_done,    // 表示是否设置完毕，一个标志位

    output [7:0] oData,         // 存放七段数码管的值，用来硬件绑定
    output [7:0] set            // 选择的通道
);

// 假设温度在 0~299 范围内，偏差值在 0~59 范围内
reg [39:0] seg_out; // 数码管显示，五个一位
reg [1:0] sel = 2'b00; // 光标，初始在个位，只有可能选择三个位，所以 2 位宽够了，和 display7_sel 的要对应

// 七段数码管的组合逻辑
// sel_display7 uut ( // tb 调试用，不分频
//     .clk(clk),
//     .sel({1'b0, sel}),
//     .iData(seg_out),
//     .isDot(8'h02), // 写死，就低到高第二个需要.
//     .oData(oData),
//     .set(set)
// );

combine_display7 uut ( // 下板用 分频
    .clk(clk),
    .sel({1'b0, sel}),
    .iData(seg_out),
    .isDot(8'h02), // 写死，就低到高第二个需要.
    .oData(oData),
    .set(set)
);

// 状态逻辑
reg setting_temp = 1'b1; // 初始状态为设定 ideal_temp
// reg [1:0] save_count = 2'b00; // 保存按钮按下次数 没必要！上面的够了

// 按钮状态寄存器
reg btn_inc_prev, btn_dec_prev, btn_left_prev, btn_right_prev, btn_save_prev;

always @(posedge clk or posedge rst)
begin
    if (rst) // 重置
    begin
        ideal_temp <= 9'd260; // 注意用的是 d
        temp_offset <= 6'd30; // 注意用的是 d
        sel <= 2'b00;     // 默认选个位，这个选择就是 0-7，二进制编码而已，这里少了一位，因为不需要更高位
        set_done <= 1'b0;
        setting_temp <= 1'b1;

        seg_out[39:35] <= 5'b10111; // T
        seg_out[34:30] <= 5'b10000; // 空位
        seg_out[29:25] <= 5'b10000; // 空位
        seg_out[24:20] <= 5'b10000; // 空位
        seg_out[19:15] <= 5'b10000; // 空位
        seg_out[14:10] <= (ideal_temp / 100) % 10; // 百位
        seg_out[9:5] <= (ideal_temp / 10) % 10; // 十位
        seg_out[4:0] <= ideal_temp % 10; // 个位

        btn_inc_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
        btn_dec_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
        btn_left_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
        btn_right_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
        btn_save_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
    end 
    else // 正常状态
    begin
        seg_out[39:20] <= 20'b10111100001000010000; // T...
        seg_out[19:15] <= 5'b10000; // 空位
        seg_out[14:10] <= (ideal_temp / 100) % 10; // 百位
        seg_out[9:5] <= (ideal_temp / 10) % 10; // 十位
        seg_out[4:0] <= ideal_temp % 10; // 个位

        if (setting_temp) // 先设置温度
        begin
            if (btn_inc && !btn_inc_prev) // 增加值
            begin
                case (sel)
                2'b00: ideal_temp <= (ideal_temp % 10 < 9) ? (ideal_temp + 1) : ideal_temp; // 个位+1
                2'b01: ideal_temp <= ((ideal_temp / 10) % 10 < 9) ? (ideal_temp + 10) : ideal_temp; // 十位+10
                2'b10: ideal_temp <= ((ideal_temp /100 ) % 10 < 2) ? (ideal_temp + 100) : ideal_temp; // 百位+100
                endcase
            end
            if (btn_dec && !btn_dec_prev) // 减少值
            begin
                case (sel)
                2'b00: ideal_temp <= (ideal_temp % 10 > 0) ? (ideal_temp - 1) : ideal_temp; // 个位-1
                2'b01: ideal_temp <= ((ideal_temp / 10) % 10 > 0) ? (ideal_temp - 10) : ideal_temp; // 十位-10
                2'b10: ideal_temp <= ((ideal_temp / 100) % 10 > 0) ? (ideal_temp - 100) : ideal_temp; // 百位-100
                endcase
            end
            if (btn_left && !btn_left_prev) // 向左，模运算
                sel <= (sel + 1) % 3;
            if (btn_right && !btn_right_prev) // 向右，模运算
                sel <= (sel + 2) % 3; // -1 变成 +2，害怕有负数，回忆 C 语言
            if (btn_save && !btn_save_prev) // 保存，进入到下一个设定
            begin
                setting_temp <= 1'b0;
                sel <= 2'b00; // 重置光标位置
            end
        end
        else // 再设置温度的偏移量
        begin
            seg_out[39:20] <= 20'hCC75A; // DIFF
            seg_out[19:10] <= 10'b1000010000; // 空位
            seg_out[9:5] <= (temp_offset / 10) % 10; // 十位
            seg_out[4:0] <= temp_offset % 10; // 个位

           if (btn_inc && !btn_inc_prev) // 偏移量只有两个位需要选择
            begin
                case (sel)
                2'b00: temp_offset <= (temp_offset % 10 < 9) ? (temp_offset + 1) : temp_offset; // 个位+1
                2'b01: temp_offset <= ((temp_offset / 10 ) % 10 < 5) ? (temp_offset + 10) : temp_offset; // 十位+10
                endcase
            end
            if (btn_dec && !btn_dec_prev) // 偏移量只有两个位需要选择
            begin
                case (sel)
                2'b00: temp_offset <= (temp_offset % 10 > 0) ? (temp_offset - 1) : 0; // 个位-1
                2'b01: temp_offset <= ((temp_offset / 10) % 10 > 0) ? (temp_offset - 10) : 0; // 十位-10
                endcase
            end
            if (btn_left && !btn_left_prev)
                sel <= (sel + 1) % 2;
            if (btn_right && !btn_right_prev)
                sel <= (sel + 1) % 2; // 发现没有，左右两种移动，代码是一样的
            if (btn_save && !btn_save_prev)
                set_done <= 1'b1; // 没必要再用一个临时变量记录设置的次数了，一共就两种设置
        end

        // 更新按钮状态寄存器
        btn_inc_prev <= btn_inc;
        btn_dec_prev <= btn_dec;
        btn_left_prev <= btn_left;
        btn_right_prev <= btn_right;
        btn_save_prev <= btn_save;
    end
end
endmodule
