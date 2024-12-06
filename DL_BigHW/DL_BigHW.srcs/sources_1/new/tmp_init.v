// 对初始温度和偏差值的设定

module tmp_init(

);

endmodule


// 对按钮输入的处理
module tmp_init_button(
    input set,          // 完成一项设定
    input left,         // 选择的内容左移
    input right,        // 选择的内容右移
    input inc,          // 模 10 + 1
    input dec           // 模 10 - 1
    input rst           // 高位复位
);

endmodule