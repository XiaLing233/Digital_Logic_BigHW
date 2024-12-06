// 七段数码管的显示、选择模块

module display7(
    input [4:0] iData,  // D4 ~ D0 最高为 1 表示非数字，0 表示数字
    input isDot,        // 是否打印 .，高电平表示要打印
    output [7:0] oData  // . & g ~ a，低电平表示选中
);
    
    reg [7:0] TmpData;
    
    always @ (*)
    begin
        if (iData[4]) // 非数字
        begin
            case (iData[3:0])
                4'b0000 : TmpData <= 7'b1111111;     // 空
                4'b0001 : TmpData <= 7'b1001111;     // I        EF
                4'b0010 : TmpData <= 7'b0101011;     // n        CEG
                4'b0011 : TmpData <= 7'b1100110;     // i        ADE
                4'b0100 : TmpData <= 7'b0000111;     // t        DEFG
                4'b0101 : TmpData <= 7'b1000111;     // L        DEF
                4'b0110 : TmpData <= 7'b0100011;     // o        CDEG
                4'b0111 : TmpData <= 7'b1001110;     // T        AEF
                4'b1000 : TmpData <= 7'b0001001;     // H        BCEFG
                4'b1001 : TmpData <= 7'b1100000;     // D        ABCDE
                4'b1010 : TmpData <= 7'b0001110;     // F        AEFG
                4'b1111 : TmpData <= 7'b0111111;     // -        G
                default : TmpData <= 7'b1111111;     // 默认都不显示
            endcase
        end
        else // 数字
        begin
            case (iData[3:0])
                4'b0000 : TmpData <= 7'b1000000;     // 0
                4'b0001 : TmpData <= 7'b1111001;     // 1
                4'b0010 : TmpData <= 7'b0100100;     // 2
                4'b0011 : TmpData <= 7'b0110000;     // 3
                4'b0100 : TmpData <= 7'b0011001;     // 4
                4'b0101 : TmpData <= 7'b0010010;     // 5
                4'b0110 : TmpData <= 7'b0000010;     // 6
                4'b0111 : TmpData <= 7'b1111000;     // 7
                4'b1000 : TmpData <= 7'b0000000;     // 8
                4'b1001 : TmpData <= 7'b0010000;     // 9
                default : TmpData <= 7'b1111111;     // 默认都不显示
            endcase   
        end

        // 先修改非.的内容，不然会把最高位覆盖掉
        if (isDot)
            TmpData[7] <= 1'b0;
        else
            TmpData[7] <= 1'b1;
    end
    
    assign oData = TmpData;

endmodule