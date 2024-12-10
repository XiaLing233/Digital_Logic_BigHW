module tmp_init (
    input clk,                      // E3 系统时钟，不用分频，数码管已经集成了分频模块
    input rst,                      // 重置，高位重置，绑定到一个开关 V10
    input btn_inc,                  // 增加，上按钮 M18
    input btn_dec,                  // 减少，下按钮 P18
    input btn_left,                 // 左移，左按钮 P17
    input btn_right,                // 右移，右按钮 M17
    input btn_save,                 // 保存，中按钮 N17

    input set_able,                 // 是否启用设定的标志位

     // 这两个不需要输出，是给调用它的函数用的。不过现在在调试呢，给它绑定个 led 灯吧
    output reg [15:0] ideal_temp,    // 理想温度，初始值为260 注意，温度和偏差值为了和传感器对应，做了 *10 处理，九位够了，511，但是凑两个字节吧
    output reg [7:0] temp_offset,   // 偏差值，初始值为30，六位够了，63
    output reg set_done,             // 表示是否设置完毕，一个标志位

    output [7:0] oData,             // 存放七段数码管的值，用来硬件绑定
    output [7:0] set                // 选择的通道
);

// 状态定义
localparam [1:0]
    IDLE = 2'b00,
    SET_TEMP = 2'b01,
    SET_OFFSET = 2'b10,
    DONE = 2'b11;

reg [1:0] current_state, next_state;
// 假设温度在 0~299 范围内，偏差值在 0~59 范围内
reg [39:0] seg_out;     // 数码管显示，五个一位
reg [1:0] sel;        // 光标，初始在个位，只有可能选择三个位，所以 2 位宽够了，和 display7_sel 的要对应

// 按钮状态寄存器
reg btn_inc_prev, btn_dec_prev, btn_left_prev, btn_right_prev, btn_save_prev;


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
    .sel({2'b00, sel}),
    .iData(seg_out),
    .isDot(8'h02),   // 写死，就低到高第二个需要.
    .oData(oData),
    .set(set)
);

// 同步时序状态转移逻辑
always @(posedge clk)
begin
    if (rst)
        current_state <= IDLE;
    else
        current_state <= next_state;
end

// 组合逻辑次态逻辑
always @(*)
begin
    case (current_state)
        IDLE: next_state = SET_TEMP;          // 初始状态直接进入温度设置
        SET_TEMP: next_state = (btn_save && !btn_save_prev) ? SET_OFFSET : SET_TEMP;    // 按下保存键进入偏差值设置
        SET_OFFSET: next_state = (btn_save && !btn_save_prev) ? DONE : SET_OFFSET;      // 按下保存键完成设置
        DONE: next_state = DONE;              // 保持在完成状态
        default: next_state = IDLE;
    endcase
end

// 输出逻辑和寄存器更新
always @(posedge clk)
begin
    if (set_able) // 只有在启用设定时才能进行设置
    begin
        if (rst)
        begin
            // 复位时初始化所有寄存器
            ideal_temp <= 16'd260;    // 默认温度26.0度  注意用的是 d
            temp_offset <= 8'd30;     // 默认偏差值3.0度 注意用的是 d
            sel <= 2'b00;            // 默认选个位，这个选择就是 0-7，二进制编码而已，这里少了一位，因为不需要更高位
            set_done <= 1'b0;        // 清除完成标志
            // 初始化按键状态
            btn_inc_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
            btn_dec_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
            btn_left_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
            btn_right_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
            btn_save_prev <= 1'b0; // 这几个都是为了防抖，确保按下一次只操作一次
        end
        else
        begin
            // 更新按键状态
            btn_inc_prev <= btn_inc;
            btn_dec_prev <= btn_dec;
            btn_left_prev <= btn_left;
            btn_right_prev <= btn_right;
            btn_save_prev <= btn_save;

            case (current_state)
                SET_TEMP:
                begin
                    // 温度设置显示逻辑
                    seg_out[39:20] <= 20'hBC210; // T...
                    seg_out[19:15] <= 5'b10000; // 空位
                    seg_out[14:10] <= (ideal_temp / 100) % 10;  // 百位
                    seg_out[9:5] <= (ideal_temp / 10) % 10;     // 十位
                    seg_out[4:0] <= ideal_temp % 10;            // 个位

                    // 温度调节逻辑
                    if (btn_inc && !btn_inc_prev)         // 增加按钮
                    begin
                        case (sel)
                            2'b00: if (ideal_temp % 10 < 9) ideal_temp <= ideal_temp + 1;
                            2'b01: if ((ideal_temp / 10) % 10 < 9) ideal_temp <= ideal_temp + 10;
                            2'b10: if ((ideal_temp / 100) % 10 < 2) ideal_temp <= ideal_temp + 100;
                        endcase
                    end
                    if (btn_dec && !btn_dec_prev)         // 减少按钮
                    begin
                        case (sel)
                            2'b00: if (ideal_temp % 10 > 0) ideal_temp <= ideal_temp - 1;
                            2'b01: if ((ideal_temp / 10) % 10 > 0) ideal_temp <= ideal_temp - 10;
                            2'b10: if ((ideal_temp / 100) % 10 > 0) ideal_temp <= ideal_temp - 100;
                        endcase
                    end
                    // 位置选择逻辑
                    if (btn_left && !btn_left_prev) // 向左，模运算
                        sel <= (sel + 1) % 3;
                    if (btn_right && !btn_right_prev) // 向右，模运算
                        sel <= (sel + 2) % 3; // -1 变成 +2，害怕有负数，回忆 C 语言
                    // 保存的逻辑在状态转移的 always 块已经写了，这里不需要再写
                end

                SET_OFFSET:
                begin
                    // 偏差值设置显示逻辑
                    seg_out[39:20] <= 20'hCC75A; // DIFF显示
                    seg_out[19:10] <= 10'b1000010000; // 空位
                    seg_out[9:5] <= (temp_offset / 10) % 10;    // 十位
                    seg_out[4:0] <= temp_offset % 10;           // 个位

                    // 偏差值调节逻辑
                    if (btn_inc && !btn_inc_prev) // 偏移量只有两个位需要选择
                    begin
                        case (sel)
                            2'b00: if (temp_offset % 10 < 9) temp_offset <= temp_offset + 1;
                            2'b01: if ((temp_offset / 10) % 10 < 5) temp_offset <= temp_offset + 10;
                        endcase
                    end
                    if (btn_dec && !btn_dec_prev) // 偏移量只有两个位需要选择
                    begin
                        case (sel)
                            2'b00: if (temp_offset % 10 > 0) temp_offset <= temp_offset - 1;
                            2'b01: if ((temp_offset / 10) % 10 > 0) temp_offset <= temp_offset - 10;
                        endcase
                    end
                    // 位置选择逻辑
                    if (btn_left && !btn_left_prev)
                        sel <= (sel + 1) % 2;
                    if (btn_right && !btn_right_prev)
                        sel <= (sel + 1) % 2;
                end

                DONE:
                begin
                    set_done <= 1'b1;     // 设置完成标志
                end
            endcase
        end
    end
end
endmodule
