// 本模块接收选中的数码管，会闪烁之；同时接收输入的内容，不同的内容，显示在不同数码管上。

module combine_display7(
    input clk,
    input [3:0] sel,
    input [39:0] iData,
    input [7:0] isDot,
    output [7:0] oData,
    output [7:0] set
);

wire o_clk;

display7_divider uut1 (
    .i_clk(clk),
    .o_clk(o_clk)
);

sel_display7 uut2 (
    .clk(o_clk),
    .sel(sel),
    .iData(iData),
    .isDot(isDot),
    .oData(oData),
    .set(set) // 居然丢了这句，抽象..
);

endmodule

// 对系统时钟分频，IP 核的分频到不了这么低
module display7_divider(
    input i_clk,    // 100MHz 的输入
    output reg o_clk    // 480Hz 的输出
);

parameter DIVIDE = 104167; // 100MHz / 480Hz / 2 = 104167。记住要 /2。算法是：原频率 / 新频率 / 2
integer i = 0;

always @ (posedge i_clk)
begin
    if (i == DIVIDE - 1)
    begin
        i <= 0;
        o_clk <= ~o_clk;
    end
    else
    begin
        i <= i + 1;
    end
end
endmodule

module sel_display7(
    input clk,                  // 分频后的时钟，达到 60Hz 的刷新率，那也就是 480Hz 吧
    input [3:0] sel,            // 选择的位置，0 ~ 7，高电平有效。被选中的会闪烁。如果数值在 0 ~ 7 以外，则没有闪烁，保持常亮显示，一般用 1111 表示
    input [39:0] iData,         // 七段数码管的输入，套壳
    input [7:0] isDot,          // 七段数码管的输入，套壳
    output [7:0] oData,          // . & g ~ a，低电平表示选中
    output reg [7:0] set            // 硬件约束，选择的数码管！自己 i 热闹了，硬件呢？？？用时序，组合会延迟一位，不好
);

reg [4:0] sel_iData; // 被选中的，要传送到七段数码管的 iData
reg sel_isDot;       // 被选中的，要传送到七段数码管的 isDot
integer i = 0;       // 循环计数的变量，模 8
integer term_i = 0;  // 记录跳过了多少次时钟
parameter term = 60; // 60Hz，表示要亮 0.5s，暗 0.5s

display7 uut (
    .iData(sel_iData),
    .isDot(sel_isDot), // 这里要注意，isDot 在逻辑上的真假和数码管的显示是相反的，但是底层已经处理好了，display7 已经做了这部分工作！
    .oData(oData)
);

always @ (posedge clk)
begin
    set <= ~(8'h01 << i); // 非阻塞 需要对硬件进行约束啊！必须，必须，必须放到时序里！

    if (i != sel) // 正常显示
    begin
        case (i)
            0: sel_iData <= iData[4:0];
            1: sel_iData <= iData[9:5];
            2: sel_iData <= iData[14:10];
            3: sel_iData <= iData[19:15];
            4: sel_iData <= iData[24:20];
            5: sel_iData <= iData[29:25];
            6: sel_iData <= iData[34:30];
            7: sel_iData <= iData[39:35];
            default: sel_iData <= 5'b00000;
        endcase // 从 i*5 开始，向左选 5 位
        sel_isDot <= isDot[i];
    end

    else // 忽略一段时间
    begin
        if (term_i <= term / 2) // 类似于占空比吧
        begin
            case (i)
                0: sel_iData <= iData[4:0];
                1: sel_iData <= iData[9:5];
                2: sel_iData <= iData[14:10];
                3: sel_iData <= iData[19:15];
                4: sel_iData <= iData[24:20];
                5: sel_iData <= iData[29:25];
                6: sel_iData <= iData[34:30];
                7: sel_iData <= iData[39:35];
                default: sel_iData <= 5'b00000;
            endcase // 这里和上面的内容是一样的
            sel_isDot <= isDot[i];
        end
        else
        begin
            sel_iData <= 5'b10000;    // 空，读一下 README 里的编码表
            sel_isDot <= 0;          // 不要显示 .
        end

        term_i <= (term_i + 1) % term;
    end

    i <= (i + 1) % 8;
end

endmodule
