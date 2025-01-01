// 使用分频后的时钟，对外的接口
module combine_sensor(
    input clk,
    input start,
    inout data_wire,
    output [15:0] temp,
    output [15:0] humi,
    output is_done
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
integer i = 39;                          // 指向存储内容的指针
assign data_wire = data_wire_out;   // 绑定输出

// 定义等待的秒数
parameter START_HIGH = 2000000;             // 2s
parameter START_LOW = 1000;                 // 1000us = 1ms
parameter SLAVE_RESPONSE_1 = 80;            // 80us
parameter SLAVE_RESPONSE_2 = 80;            // 80us
parameter ZERO_ONE_DIVIDE = 40;             // 40us，留一些冗余，来判断 0 / 1
parameter ERROR_RESTART = 1000000;          // 1s

// 计数器
integer counter_start_high = 0;
integer counter_start_low = 0;
// integer counter_slave_response_1 = 0;
// integer counter_slave_response_2 = 0;
integer counter_zero_one_divide = 0;
integer counter_error_restart = 0;

// 定义状态
localparam [3:0]
    IDLE = 4'd0,                        // 闲置状态
    START_HIGH_STATE = 4'd1,            // 输出高电平
    START_LOW_STATE = 4'd2,             // 输出低电平
    MASTER_RESPONSE_STATE = 4'd3,       // 释放总线
    SLAVE_RESPONSE_1_STATE = 4'd4,      // 接收低电平
    SLAVE_RESPONSE_2_STATE = 4'd5,      // 接收高电平
    READ_DATA = 4'd6,                   // 读数据
    CHECK_DATA = 4'd7,                  // 验证校验位
    DONE = 4'd8,                        // 完成
    ERROR = 4'd9;                       // 出错

reg [3:0] state = IDLE; // 得给一个初始状态
reg [3:0] next_state;

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
    next_state = state; // 如果没有转移下一个状态，在当前状态空转
    case (state)
        IDLE:
        begin
            if (start)
                next_state = START_HIGH_STATE;
        end
        START_HIGH_STATE:
        begin
            if (counter_start_high >= START_HIGH)
            begin
                next_state = START_LOW_STATE;
            end
        end
        START_LOW_STATE:
        begin
            if (counter_start_low >= START_LOW)
                begin
                    next_state = MASTER_RESPONSE_STATE;
                end

        end
        MASTER_RESPONSE_STATE:
        begin
            ; // 主机释放总线，什么时候接收到了从机的低电平，就进入下一个状态
            if (data_wire == 1'b0)
                begin
                    next_state = SLAVE_RESPONSE_1_STATE;
                end
        end
        SLAVE_RESPONSE_1_STATE:
        begin
            if (data_wire == 1'b1)
                begin
                    next_state = SLAVE_RESPONSE_2_STATE;
                end
        end
        SLAVE_RESPONSE_2_STATE:
        begin
            if (data_wire == 1'b0)
                begin
                    next_state = READ_DATA;
                end
        end
        READ_DATA:
        begin
            if (i < 0)
            begin
                next_state = CHECK_DATA;
            end

        end
        CHECK_DATA:
        begin
            if (data_storage[39:32] + data_storage[31:24] + data_storage[23:16] + data_storage[15:8] == data_storage[7:0])
                next_state = DONE;
            else
            begin
                next_state = ERROR;
            end

        end
        DONE:
        begin
            // 自己空转， start 信号控制
        end
        ERROR:
        begin
            if (counter_error_restart >= ERROR_RESTART)
                next_state = IDLE; // 重新开始，因为要清零。因为并没有成功，所以 start 信号一直是 1
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
            // temp <= 16'd123; // IDLE 的时候，保持原样不变
            // humi <= 16'd456;    // test
            data_storage <= 40'b0;
            data_wire_out <= 1'b1;

            // 这几个计数器要清零
            counter_start_high <= 0;
            counter_start_low <= 0;
            // counter_slave_response_1 <= 0;
            // counter_slave_response_2 <= 0;
            counter_zero_one_divide <= 0;
            counter_error_restart <= 0;

            i <= 39;
        end
        START_HIGH_STATE:
        begin
            // temp <= 16'd200; // IDLE 的时候，保持原样不变
            // humi <= 16'd111;    // test
            data_wire_out <= 1'b1;
            counter_start_high <= counter_start_high + 1;
        end
        START_LOW_STATE:
        begin
            // temp <= 16'd233; // IDLE 的时候，保持原样不变
            // humi <= 16'd333;    // test
            data_wire_out <= 1'b0;
            counter_start_low <= counter_start_low + 1;
        end
        MASTER_RESPONSE_STATE:
        begin
            // temp <= 16'd200; // IDLE 的时候，保持原样不变
            // humi <= 16'd222;    // test
            data_wire_out <= 1'bz;
        end
        SLAVE_RESPONSE_1_STATE:
        begin
            // temp <= 16'd200; // IDLE 的时候，保持原样不变
            // humi <= 16'd333;    // test
            // counter_slave_response_1 <= counter_slave_response_1 + 1;
        end
        SLAVE_RESPONSE_2_STATE:
        begin
            // temp <= 16'd200; // IDLE 的时候，保持原样不变
            // humi <= 16'd444;    // test
            // counter_slave_response_2 <= counter_slave_response_2 + 1;
        end
        READ_DATA:
        begin
            // temp <= 16'd200; // IDLE 的时候，保持原样不变
            // humi <= 16'd555;    // test
            if (data_wire == 1'b0) // 每次到 0 的时候，处理一下之前读入的内容。当然要求 counter 非 0，排除第一个
            begin
                if (counter_zero_one_divide)
                begin
                    if (counter_zero_one_divide >= ZERO_ONE_DIVIDE)
                    begin
                        data_storage[i] <= 1'b1;
                        i <= i - 1;
                        counter_zero_one_divide <= 0;
                    end
                    else
                    begin
                        data_storage[i] <= 1'b0;
                        i <= i - 1;
                        counter_zero_one_divide <= 0;
                    end
                end
            end
            else // if (data_wire == 1'b1) 已经包含了所有情况
            begin
                counter_zero_one_divide <= counter_zero_one_divide + 1;
            end
        end
        CHECK_DATA:
        begin
            // No action needed, handled in next_state logic
        end
        DONE:
        begin
            is_done <= 1'b1;
            humi <= data_storage[39:24];        // 湿度在前，不要写反了
            temp <= data_storage[23:8];
        end
        ERROR:
        begin
            // temp <= 16'd123; // IDLE 的时候，保持原样不变
            // humi <= 16'd909;    // test
            counter_error_restart <= counter_error_restart + 1;
        end
    endcase
end
endmodule