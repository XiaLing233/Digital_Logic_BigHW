// 本模块负责接收网络是否初始化成功，波特率 115200，接收系统时钟 100MHz，不需要进行分频，只要进行好波特率的处理就好
module rec_netstat(
    input clk, // 系统时钟，100MHz，不用分频
    input RX,
    input net_able, // 高电平表示网络初始化
    output reg net_done,
    output [7:0] oData, // 存放七段数码管的值，用来硬件绑定
    output [7:0] set  // 选择的通道
);

parameter BAUD_RATE = 115200;
parameter CLOCK_RATE = 100000000; // 100MHz
parameter BIT_PERIOD = CLOCK_RATE / BAUD_RATE; //每传输一个bit所需的时钟周期

reg [7:0] rx_data;
reg [3:0] bit_count;
reg [31:0] clk_count;
reg [39:0] iData;       // 存放向数码管传输的数据
reg [7:0] isDot;        // 存放小数点的情况
reg rx_state;
reg state, next_state;

// 七段数码管的组合逻辑
combine_display7 uut (
    .clk(clk),
    .sel(4'b1111), // 不选择任何位
    .iData(iData),
    .isDot(isDot),   // 没有小数点
    .oData(oData),
    .set(set)
);

parameter IDLE = 1'b0;
parameter REC = 1'b1;

always @(posedge clk)
begin
    if (net_able)
        state <= REC;
    else
        state <= IDLE;
end

// 某状态操作
always @(posedge clk)
begin
    case (state)
        IDLE:
        begin
            rx_state <= 1'b0;
            net_done <= 1'b0;
        end
        REC:
        begin
            if (rx_state == 0 && RX == 0) // 开始接收
            begin
                rx_state <= 1;
                clk_count <= 0;
                bit_count <= 0;
                iData <= 40'h8CA7484210; // INIT ....
                isDot <= 8'h0F;
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
                        rx_state <= 0;          // 准备下一次接收，因为如果连接失败，ESP32 会自动重启，所以只需要等着下一次信号就好
                        if (rx_data == 8'h99)
                        begin
                            net_done <= 1'b1;
                            iData <= 40'h8CA748437C; // INIT ..OK
                            isDot <= 8'h00;
                        end

                        else if (rx_data == 8'hee)
                        begin
                            net_done <= 1'b0;
                            iData <= 40'h8CA74D7635; // INIT FAIL
                            isDot <= 8'h00;
                        end
                    end
                    clk_count <= 0;
                end
                else
                    clk_count <= clk_count + 1;
            end
        end
    endcase
end
endmodule