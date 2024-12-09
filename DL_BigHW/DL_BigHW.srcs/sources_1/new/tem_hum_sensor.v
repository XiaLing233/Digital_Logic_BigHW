// 使用分频后的时钟，对外的接口
module combine_sensor(
    input clk,
    input start,
    inout data_wire,
    output reg [15:0] temp,
    output reg [15:0] humi,
    output reg is_done
);

wire o_clk;

    sensor_divider uut1 (
        .i_clk(clk),
        .o_clk(o_clk)
    );

    tmp_hum_sensor uut2(
        .clk(o_clk),
        .start(start),
        .data_wire(data_wire),
        .temp(temp),
        .humi(humi),
        .is_done(is_done)
    );

endmodule


// 对系统时钟分频
module sensor_divider(
    input i_clk,    // 100MHz 的输入
    output reg o_clk    // 1MHz 的输出
);

parameter DIVIDE = 50; // 100MHz / 1 MHz / 2 = 50。记住要 /2。算法是：原频率 / 新频率 / 2
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

// 传感器逻辑
module tmp_hum_sensor(
    input clk,              // 时钟，分频后的，周期为 1 MHz，这样一周期就对应 1us
    input start,            // 给一个开始的信号，高电平开始
    inout data_wire,        // 与传感器通信的数据线路
    output reg [15:0] temp, // 温度传输，不用下板到硬件，给主模块
    output reg [15:0] humi, // 湿度传输，不用下板到硬件，给主模块
    output reg is_done      // 一次读取结束的信号，不用下板到硬件，给主模块。调试的时候可以绑个 led，但是我估计个数不够
);

reg data_wire_out;                  // 控制数据线的输出信号，这样可以时序控制
reg [39:0] data_storage;            // 存放接收到的 40 位数据
integer i;                          // 指向存储内容的指针
integer counter;                    // 记录经过了多少个时钟周期，需要共用
assign data_wire = data_wire_out;   // 绑定输出

// 定义等待的秒数
parameter START_HIGH = 2000000;             // 2s
parameter START_LOW = 1000;                 // 1000us = 1ms
parameter SLAVE_RESPONSE_1 = 20;            // 20us
parameter SLAVE_RESPONSE_2 = 80;            // 80us
parameter ZERO_ONE_DIVIDE = 40;             // 40us，留一些冗余，来判断 0 / 1
parameter ERROR_RESTART = 1000000;          // 1s

// 定义状态
localparam [3:0]
    IDLE = 4'd0,                        // 闲置状态
    START_HIGH_STATE = 4'd1,            // 输出高电平
    START_LOW_STATE = 4'd2,             // 输出低电平
    SLAVE_RESPONSE_1_STATE = 4'd3,      // 接收高电平
    SLAVE_RESPONSE_2_STATE = 4'd4,      // 接收低电平
    READ_DATA = 4'd5,                   // 读数据
    CHECK_DATA = 4'd6,                  // 验证校验位
    DONE = 4'd7,                        // 完成
    ERROR = 4'd8;                       // 出错

reg [3:0] state, next_state;

// 状态转移逻辑
always @(posedge clk) // 同步复位
begin
    if (!start)
    begin
        state <= IDLE;
    end
    else
    begin
        state <= next_state;
    end
end

// 状态转移条件
always @(*)
begin
    next_state <= state; // 如果没有转移下一个状态，在当前状态空转
    case (state)
        IDLE:
        begin
            if (start)
                next_state <= START_HIGH_STATE;
        end
        START_HIGH_STATE:
        begin
            if (counter == START_HIGH)
            begin
                next_state <= START_LOW_STATE;
                counter <= 0;
            end

        end
        START_LOW_STATE:
        begin
            if (counter == START_LOW)
                begin
                    next_state <= SLAVE_RESPONSE_1_STATE;
                    counter <= 0;
                end

        end
        SLAVE_RESPONSE_1_STATE:
        begin
            if (counter == SLAVE_RESPONSE_1)
                begin
                    next_state <= SLAVE_RESPONSE_2_STATE;
                    counter <= 0;
                end
            else if (data_wire == 1'b0)
            begin
                next_state <= ERROR;
                counter <= 0;
            end
        end
        SLAVE_RESPONSE_2_STATE:
        begin
            if (counter == SLAVE_RESPONSE_2)
                begin
                    next_state <= READ_DATA;
                    counter <= 0;
                end

            else if (data_wire == 1'b1)
            begin
                next_state <= ERROR;
                counter <= 0;
            end

        end
        READ_DATA:
        begin
            if (i < 0)
            begin
                next_state <= CHECK_DATA;
                counter <= 0; // 尽管可能不需要，但还是置零吧
            end

        end
        CHECK_DATA:
        begin
            if (data_storage[39:32] + data_storage[31:24] + data_storage[23:16] + data_storage[15:8] == data_storage[7:0])
                next_state <= DONE;
            else
            begin
                next_state <= ERROR;
                counter <= 0;
            end

        end
        DONE:
        begin
            // 自己空转
        end
        ERROR:
        begin
            if (counter >= ERROR_RESTART)
                next_state <= START_HIGH_STATE;
        end
    endcase
end

// 某状态操作
always @(posedge clk)
begin
    case (state)
        IDLE:
        begin
            is_done <= 0;
            // temp <= 16'b0; // IDLE 的时候，保持原样不变
            // humi <= 16'b0;
            data_storage <= 40'b0;
            data_wire_out <= 1'b1;
            counter <= 0;
            i <= 39;
        end
        START_HIGH_STATE:
        begin
            data_wire_out <= 1'b1;
            counter <= counter + 1;
        end
        START_LOW_STATE:
        begin
            data_wire_out <= 1'b0;
            counter <= counter + 1;
        end
        SLAVE_RESPONSE_1_STATE:
        begin
            data_wire_out <= 1'bz;
            counter <= counter + 1;
        end
        SLAVE_RESPONSE_2_STATE:
        begin
            counter <= counter + 1;
        end
        READ_DATA:
        begin
            if (data_wire == 1'b0) // 每次到 0 的时候，处理一下之前读入的内容。当然要求 counter 非 0，排除第一个
            begin
                if (counter)
                begin
                    if (counter >= ZERO_ONE_DIVIDE)
                    begin
                        data_storage[i] <= 1'b1;
                        i <= i - 1;
                        counter <= 0;
                    end
                    else
                    begin
                        data_storage[i] <= 1'b0;
                        i <= i - 1;
                        counter <= 0;
                    end
                end
            end
            else // if (data_wire == 1'b1) 已经包含了所有情况
            begin
                counter <= counter + 1;
            end
        end
        CHECK_DATA:
        begin
            // No action needed, handled in next_state logic
        end
        DONE:
        begin
            is_done <= 1'b1;
            temp <= data_storage[39:24];
            humi <= data_storage[23:8];
        end
        ERROR:
        begin
            counter <= counter + 1;
        end
    endcase
end
endmodule