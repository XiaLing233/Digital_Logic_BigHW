// 本模块负责把温湿度等信息发送到 ESP32

module send_data(
    input clk, // 系统时钟，100MHz
    input send_able, // 高电平表示可以发送
    input [15:0] temp, // 温度
    input [15:0] humi, // 湿度
    input [15:0] ideal_temp, // 理想温度
    input [7:0] temp_offset, // 温度偏差
    output reg send_done, // 发送完毕的标志位
    output TX // 发送的数据
);

parameter BAUD_RATE = 115200;
parameter CLOCK_RATE = 100_000_000; // 100MHz
parameter BIT_PERIOD = CLOCK_RATE / BAUD_RATE; // 每传输一个bit所需的时钟周期

// 状态编码
parameter [2:0] IDLE = 3'b001;
parameter [2:0] SEND = 3'b010;
parameter [2:0] DONE = 3'b100;

// 状态寄存器
reg [2:0] state = IDLE;

// 波特率计数器
reg [13:0] baud_counter = 14'd0;

// 位计数器
reg [6:0] bit_counter = 7'd0; // 总共需要发送70位（7字节 * 10位）

// 待发送的数据，包括起始位和停止位
reg [69:0] data_to_send = 70'd0;

// 输出寄存器
reg tx_reg = 1'b1;
assign TX = tx_reg;

// 状态机
always @(posedge clk)
begin
    case(state)
        IDLE:
        begin
            send_done <= 1'b0;
            // 按照小端方式加载数据，并为每个字节添加起始位和停止位
            // 参考：https://www.labcenter.com/blog/sim-uart/
            data_to_send <=
            {
                1'b1, temp_offset,1'b0,
                1'b1, ideal_temp[7:0], 1'b0,
                1'b1, ideal_temp[15:8], 1'b0,
                1'b1, humi[7:0], 1'b0,
                1'b1, humi[15:8], 1'b0,
                1'b1, temp[7:0], 1'b0,
                1'b1, temp[15:8], 1'b0
            };
            bit_counter <= 7'd0;
            baud_counter <= 14'd0;
            tx_reg <= 1'b1; // 空闲状态为高电平
            if(send_able)
                state <= SEND;
        end
        SEND:
        begin
            if(baud_counter < BIT_PERIOD - 1)
            begin
                baud_counter <= baud_counter + 1;
            end
            else
            begin
                baud_counter <= 14'd0;
                tx_reg <= data_to_send[bit_counter];
                bit_counter <= bit_counter + 1;
                if(bit_counter == 7'd69)
                begin
                    send_done <= 1'b1;
                    state <= DONE;
                end
            end
        end
        DONE:
        begin
            if(send_able)
                state <= IDLE;
        end
    endcase
end

endmodule