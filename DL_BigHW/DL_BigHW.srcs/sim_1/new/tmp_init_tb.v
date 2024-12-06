`timescale 1ns/1ns
module tmp_init_tb;
    reg clk;       // E3 系统时钟，不用分频，数码管已经集成了分频模块
    reg rst;       // 重置，高位重置，绑定到一个开关 V10
    reg btn_inc;   // 增加，上按钮 M18
    reg btn_dec;   // 减少，下按钮 P18
    reg btn_left;  // 左移，左按钮 P17
    reg btn_right; // 右移，右按钮 M17
    reg btn_save;  // 保存，中按钮 N17

    // 这两个不需要输出，是给调用它的函数用的。不过现在在调试呢，给它绑定个 led 灯吧
    wire [8:0] ideal_temp; // 理想温度，初始值为260 注意，温度和偏差值为了和传感器对应，做了 *10 处理，九位够了，511
    wire [5:0] temp_offset; // 偏差值，初始值为30，六位够了，63
    wire set_done;    // 表示是否设置完毕，一个标志位

    wire [7:0] oData;         // 存放七段数码管的值，用来硬件绑定
    wire [7:0] set;

    temperature_control uut3 (
        .clk(clk),
        .rst(rst),
        .btn_inc(btn_inc),
        .btn_dec(btn_dec),
        .btn_left(btn_left),
        .btn_right(btn_right),
        .btn_save(btn_save),
        .ideal_temp(ideal_temp),
        .temp_offset(temp_offset),
        .set_done(set_done),
        .oData(oData),
        .set(set)
    );

    initial
    begin
        clk = 0;

        repeat (400)
            #1 clk = ~clk;
    end

    initial
    begin
        rst = 1;
        btn_inc = 0;
        btn_dec = 0;
        btn_left = 0;
        btn_right = 0;
        btn_save = 0;

        #1 rst = 0;

        repeat(3)
        begin // 测试增加
            #5 btn_inc = 1;
            #5 btn_inc = 0;
        end

        // 左移一位
        #5 btn_left = 1;
        #5 btn_left = 0;

        #5 btn_inc = 1;
        #5 btn_inc = 0;

        #5 btn_save = 1;
        #5 btn_save = 0;

        // 开始处理偏移量

        repeat(5)
        begin
            #5 btn_inc = 1;
            #5 btn_inc = 0;
        end

        #5 btn_save = 1;
        #5 btn_save = 0;

        // 进行到此，应该 set_done 为 1
    end

endmodule