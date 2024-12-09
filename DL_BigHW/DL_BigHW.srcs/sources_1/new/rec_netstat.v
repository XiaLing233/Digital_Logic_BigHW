// 本模块负责接收网络是否初始化成功，波特率 115200，接收系统时钟 100MHz，不需要进行分频，只要进行好波特率的处理就好
module rec_netstat(
    input clk, // 系统时钟，100MHz，不用分频
    input RX,
    input net_able, // 高电平表示网络初始化
    output reg net_done,
    output [7:0] oData,
    output [7:0] set
);

parameter BAUD_RATE = 115200;
parameter CLOCK_RATE = 100000000; // 100MHz
parameter BIT_PERIOD = CLOCK_RATE / BAUD_RATE; //每传输一个bit所需的时钟周期

reg [7:0] rx_data;
reg [3:0] bit_count;
reg [31:0] clk_count;
reg rx_state;

// 约定 0x99 为网络初始化成功的标志位，0xee 为网络初始化失败的标志位
always @(posedge clk)
begin
    if (net_able)
    begin
        if (rx_state == 0 && RX == 0) // 开始接收
        begin
            rx_state <= 1;
            clk_count <= 0;
            bit_count <= 0;
        end
        else if (rx_state == 1)
        begin
            if (clk_count == BIT_PERIOD/2 && bit_count == 0) // 从这里开始，后面接收的数据时间都会在中间，增加了准确性
            begin
                clk_count <= 0;
                bit_count <= bit_count + 1;
            end
            else if (clk_count == BIT_PERIOD && bit_count > 0) // 开始接收
            begin
                if (bit_count <= 8) // 如果还没接收完
                begin
                    rx_data[bit_count-1] <= RX;
                    bit_count <= bit_count + 1;
                end
                else // 接收完毕
                begin
                    rx_state <= 0;
                    if (rx_data == 8'h99)
                        net_done <= 1'b1;
                    else if (rx_data == 8'hee)
                        net_done <= 1'b0;
                end
                clk_count <= 0;
            end
            else
                clk_count <= clk_count + 1;
        end
    end
    else
    begin
        rx_state <= 0;
        net_done <= 1'b0;
    end
end
endmodule