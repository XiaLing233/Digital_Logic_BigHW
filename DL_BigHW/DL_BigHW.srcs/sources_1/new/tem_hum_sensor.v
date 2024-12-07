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
integer i = 39;                      // 指向存储内容的指针
integer counter = 0;                // 记录经过了多少个时钟周期，需要共用
assign data_wire = data_wire_out;   // 绑定输出

parameter START_HIGH = 2000000; // 2s
parameter START_LOW = 1000; // 1000us = 1ms
parameter SLAVE_RESPONSE_1 = 20; // 20us
parameter SLAVE_RESPONSE_2 = 80; // 80us

// parameter DATA_LOW = 50;  // 50us 的开始，大家都一样
parameter ZERO_ONE_DIVIDE = 40; // 40us，留一些冗余，来判断 0 / 1
parameter ERROR_RESTART = 1000000; // 1s

always @ (posedge clk)
begin
    if (!start) // 不开始，一直保持默认状态
    begin
        is_done <= 0;
        temp <= 16'b0;
        humi <= 16'b0;
        data_storage <= 40'b0;
        data_wire_out <= 1'b1;      // 因为拉低表示开始，所以如果不开始的话，把数据总线保持在高电平
    end
    else
    begin
        while (!is_done) // 没完成，说明没走到最后，一直循环
        begin
            /* 主机发送信号 */
            data_wire_out <= 1'b1;

            counter <= 0;
            while (counter < START_HIGH) // 先保持 2s 的稳定高电平
                counter <= counter + 1;

            data_wire_out <= 1'b0;

            counter <= 0;
            while (counter < START_LOW) // 再下拉 1ms
                counter <= counter + 1;

            /* 接收从机响应信号 */

            // 切换数据线为输入（高阻态）
            data_wire_out <= 1'bz;

            counter <= 0;
            while (data_wire == 1'b1 && counter < SLAVE_RESPONSE_1) // 20us 高
                counter <= counter + 1;

            if (counter != SLAVE_RESPONSE_1) // 时间不是 20us
            begin
                counter <= 0;
                while (counter < ERROR_RESTART) // 等待 1s 后重新开始循环
                    counter <= counter + 1;
                continue;
            end
            else
            begin
                counter <= 0;
                while (data_wire == 1'b0 && counter < SLAVE_RESPONSE_2)
                    counter <= counter + 1;

                if (counter != SLAVE_RESPONSE_2) // 时间不是 80us
                begin
                    counter <= 0;
                    while (counter < ERROR_RESTART) // 等待 1s 后重新开始循环
                    counter <= counter + 1;
                    continue;
                end
                else
                begin
                    counter <= 0;
                    while (data_wire == 1'b1 && counter < SLAVE_RESPONSE_2)
                    counter <= counter + 1;

                    if (counter != SLAVE_RESPONSE_2) // 时间不是 80us
                    begin
                    counter <= 0;
                    while (counter < ERROR_RESTART) // 等待 1s 后重新开始循环
                        counter <= counter + 1;
                    continue;
                    end

                    /* 传感器响应信号正确，准备接收数据 */
                    i <= 39;        // 高位在前
                    data_storage <= 40'b0;
                    
                    while (i >= 0)
                    begin
                        counter <= 0;
                        while (data_wire == 1'b0) // 先忽略低电平
                            continue;
                        while (data_wire == 1'b1) // 读入高电平
                            counter <= counter + 1;

                        if (counter >= ZERO_ONE_DIVIDE)
                            data_storage[i] <= 1'b1;
                        else
                            data_storage[i] <= 1'b0;
                        
                        i = i - 1;
                    end

                    /* 记录结束，开始校验 */
                    if (data_storage[39:32] + data_storage[31:24] + data_storage[23:16] + data_storage[15:8] == data_storage[7:0]) // OK
                    begin
                        is_done <= 1'b1;
                        temp <= data_storage[39:24];
                        humi <= data_storage[23:8];
                    end
                    else
                        continue;
                end
            end
        end
    end
end

endmodule