// 本模块负责在七段数码管上展示温湿度以及用三色灯程度

module data_display(
    input clk,                      // E3 系统时钟，不用分频，数码管已经集成了分频模块
    input [15:0] temp,              // 温度
    input [15:0] humi,              // 湿度

    output [7:0] oData,             // 存放七段数码管的值，用来硬件绑定
    output [7:0] set                // 选择的通道
);

endmodule