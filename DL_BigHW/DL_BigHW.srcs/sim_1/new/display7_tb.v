`timescale 1ns / 1ns

module display7_tb;
    reg [4:0] iData;  // D4 ~ D0 最高为 1 表示非数字，0 表示数字
    reg isDot;        // 是否打印 .，高电平表示要打印
    wire [7:0] oData;  // . & g ~ a，低电平表示选中

    display7 uut(
        .iData(iData),
        .isDot(isDot),
        .oData(oData)
    );

    initial
    begin
        iData = 5'b00000; // 数字
        repeat (2)
        begin
            isDot = 0;

            repeat (12)
            #10 iData = iData + 1;

            #10 isDot = 1;
            repeat (12)
            #10 iData = iData - 1;

            iData = 5'b10000; // 非数字
        end
    end
endmodule