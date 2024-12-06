`timescale 1ns/1ns

module sel_display7_tb; // 只测试显示功能，分频器无需测试，之前已经测试过了
    reg clk;
    reg [2:0] sel;
    reg [39:0] iData;
    reg [7:0] isDot;
    wire [7:0] oData;

    sel_display7 uut(
        .clk(clk),
        .sel(sel),
        .iData(iData),
        .isDot(isDot),
        .oData(oData)
    );

    initial
    begin
        clk = 0;

        repeat (400)
        #1 clk = ~clk;
    end

    initial
    begin
        sel = 3'b110; // 就赋值为6
        iData = 40'habcdef1234; // 随便写点测试输入
        isDot = 8'h4f; // 随便安排是不是有 .
    end

endmodule