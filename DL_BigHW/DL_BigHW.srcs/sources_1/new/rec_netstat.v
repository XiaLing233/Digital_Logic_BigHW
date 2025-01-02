// 本模块负责接收网络是否初始化成功，波特率 115200，接收系统时钟 100MHz，不需要进行分频，只要进行好波特率的处理就好
module rec_netstat(
    input clk, // 系统时钟，100MHz，不用分频
    input RX,
    input net_able, // 高电平表示网络初始化
    output reg net_done,
    output [7:0] oData, // 存放七段数码管的值，用来硬件绑定
    output [7:0] set,  // 选择的通道
    output TX      // 给 TX 发送 0x99 表示开始连接网络
);

parameter BAUD_RATE = 115200;
parameter CLOCK_RATE = 100000000; // 100MHz
parameter BIT_PERIOD = CLOCK_RATE / BAUD_RATE; //每传输一个bit所需的时钟周期

reg [7:0] rx_data = 8'h00; // 接收到的数据
reg [3:0] bit_count;
reg [31:0] clk_count;
reg [39:0] iData = 40'h8CA748437C;       // 存放向数码管传输的数据 INIT .
reg [7:0] isDot = 8'hAA;        // 存放小数点的情况
reg rx_state;
reg[3:0] state = IDLE;      // 位宽要和状态编码对应！！！
reg[3:0] next_state;
reg send_done = 0;          // 记录是否给 ESP32 发送了连接要求

// 七段数码管的组合逻辑
combine_display7 uut (
    .clk(clk),
    .sel(4'b1111), // 不选择任何位
    .iData(iData),
    .isDot(isDot),   // 没有小数点
    .oData(oData),
    .set(set)
);

parameter IDLE = 4'b0001;
parameter SEND = 4'b0010;
parameter REC = 4'b0100;
parameter DONE = 4'b1000;

// 波特率计数器
reg [13:0] baud_counter = 14'd0;

// 位计数器
reg [3:0] bit_counter = 4'b0; // 总共需要发送10位

reg [9:0] data_to_send = 10'b1100110010; // 发送 0x99 表示开始连接网络

// 输出寄存器
reg tx_reg = 1'b1;
assign TX = tx_reg;

// 第一段：状态寄存器
always @(posedge clk)
begin
    state <= next_state;
end

// 第二段：组合逻辑计算下一状态
always @(*)
begin
    next_state = state; // 默认保持当前状态
    
    case(state)
        IDLE:
        begin
            if(net_able)
                next_state = SEND;
        end
        SEND:
        begin
            if(send_done)
                next_state = REC;
        end
        REC:
        begin
            if(net_done)
                next_state = DONE;
        end
        DONE:
        begin
            ; // 空转
        end
        default:
            next_state = IDLE;
    endcase
end

// 第三段：状态输出
always @(posedge clk)
begin
    case (state)
        IDLE:
        begin
            rx_state <= 1'b0;
            net_done <= 1'b0;
            send_done <= 1'b0;
            baud_counter <= 14'd0;
            bit_counter <= 4'b0;
            iData = 40'h8CA748437C;
            isDot <= 8'h08;     // INIT .
        end
        SEND:
        begin
            iData = 40'h8CA748437C;
            isDot <= 8'h0C;     // INIT ..
            if (baud_counter < BIT_PERIOD - 1)
            begin
                baud_counter <= baud_counter + 1;
            end
            else
            begin
                baud_counter <= 0;
                tx_reg <= data_to_send[bit_counter];

                if (bit_counter == 9) // 不要把条件判断和加法运算并列！
                begin
                    send_done <= 1'b1;
                    // iData = 40'h8CA748437C;
                    iData = 40'h8CA748CA74;
                    isDot <= 8'h0E; // INIT ...
                    bit_counter <= 4'b0;
                end
                else
                begin
                    bit_counter <= bit_counter + 1;
                end
            end
        end
        REC:
        begin
            if (rx_state == 0 && RX == 0) // 开始接收
            begin
                rx_state <= 1;
                clk_count <= 0;
                bit_count <= 0;
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
                            // iData <= 40'h8CA748437C; // INIT ..OK
                            iData <= 40'h8437C8437C; // INIT ..OK
                            isDot <= 8'h00;
                        end

                        else // (rx_data == 8'hee) 其实只要不是 0x99 就是失败，不然恐怕有未定义行为
                        begin
                            net_done <= 1'b0;
                            // iData <= 40'h8CA74D7635; // INIT FAIL
                            iData <= 40'hD7635D7635; // INIT FAIL
                            isDot <= 8'h00;
                        end
                    end
                    clk_count <= 0;
                end
                else
                    clk_count <= clk_count + 1;
            end
            else if (RX == 1) // 如果接收到停止位，或者压根没接收到数据
            begin
                rx_state <= 0;
                isDot <= 8'h00;
            end
        end
        DONE:
        begin
            ; // 空转
        end
    endcase
end
endmodule