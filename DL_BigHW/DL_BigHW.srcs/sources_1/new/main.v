// 主进程
// 初始化网络
// 设定预期温度
// 接温湿度并显示
// 发送到网络

module main(
    input clk,          // E3 系统时钟，100MHz，不用分频
    
    // 温湿度传感器部分
    inout data_wire,    // 与温湿度传感器连接的数据线，连接 PMod JC，G6(JC4)

    // 和 ESP32 的通信端口
    input RX,           // ESP32 的输出 TX D17，连接 PMod JB，连接黄色杜邦线，G16(JB3)
    output TX,          // ESP32 的输入 RX D16，连接 PMod JB，连接橙色杜邦线，H14(JB4)

    // 初始化设定部分
    input rst,       // 重置，高位重置，绑定到一个开关 V10
    input btn_inc,   // 增加，上按钮 M18
    input btn_dec,   // 减少，下按钮 P18
    input btn_left,  // 左移，左按钮 P17
    input btn_right, // 右移，右按钮 M17
    input btn_save,  // 保存，中按钮 N17

    // 七段数码管部分
    output reg [7:0] oData,         // 存放七段数码管的值，用来硬件绑定
    output reg [7:0] set,           // 选择的通道，用来分时显示数码管内容

    // 三色灯部分
    // 温度
    output pwm_red_t,       // PWM 红色输出 N16
    output pwm_green_t,     // PWM 绿色输出 R11
    output pwm_blue_t,      // PWM 蓝色输出 G14

    // 湿度
    output pwm_red_h,       // PWM 红色输出 N15
    output pwm_green_h,     // PWM 绿色输出 M16
    output pwm_blue_h,      // PWM 蓝色输出 R12

    input rst_to_begin // 重置到 SET_TEMP 状态
);

// 定义状态
localparam [2:0]
    INIT_NETWORK = 4'b000, // 初始化网络
    SET_TEMP = 4'b001,     // 设定预期温度
    GET_DATA = 4'b010,     // 接温湿度并显示，显示在数码管上，也显示在三色灯上
    SEND_DATA = 4'b011,    // 发送到网络
    WAIT = 4'b100;         // 等待 60s，再次读取温湿度

// 状态寄存器
reg [2:0] state, next_state; // 状态机的状态和下一个状态
reg net_able;                 // 是否启用网络的标志位
reg set_able;                 // 是否启用设定的标志位
reg get_data_able;            // 是否启用获取数据的标志位
reg send_able;                // 是否启用发送的标志位

reg is_tri_led = 1'b0;               // 是否是三色灯的标志位，如果在初始化，则不显示，因为数值不可信..

wire net_done;                   // 网络初始化完毕的标志位，出现在 INIT_NETWORK 状态
wire set_done;                // 设定完毕的标志位，出现在 SET_TEMP 状态
wire get_data_done;                 // 温度传感器是否完成了一次读取，出现在 GET_DATA 状态
wire send_done;                 // 是否发送完毕，出现在 SEND_DATA 状态
reg [7:0] counter = 0;           // 计数器，用来计数

// parameter WAIT_TIME = 60000000; // 60s 的计数器
parameter WAIT_TIME = 10000000; // 10s 的计数器

// 数据
wire [15:0] temp, humi; // 温度和湿度
wire [15:0] ideal_temp; // 理想温度，初始值为 26.0
wire [7:0] temp_offset; // 偏差值，初始值为 3.0

// Modify module ports to have separate oData inputs from each module
wire [7:0] oData_net;    // From network status module
wire [7:0] oData_init;   // From init module  
wire [7:0] oData_disp;   // From display module

// Modify wire declarations for set signals
wire [7:0] set_net;    // From network status module
wire [7:0] set_init;   // From init module  
wire [7:0] set_disp;   // From display module

// Select oData source based on current state
always @(*)
begin
    case (state)
        INIT_NETWORK:
        begin 
            oData = oData_net;
            set = set_net;
        end
        SET_TEMP:
        begin
            oData = oData_init;
            set = set_init;
        end
        default:      // GET_DATA, SEND_DATA and WAIT states
        begin
            oData = oData_disp;
            set = set_disp;
            is_tri_led = 1'b1; // 三色灯显示
        end
    endcase
end

// 组合逻辑，模块的实例化
rec_netstat u_netstat ( // 网络状态接收模块
    .clk(clk),
    .RX(RX),
    .net_able(net_able),
    .net_done(net_done),
    .oData(oData_net),
    .set(set_net)
);

tmp_init u_init ( // 初始化模块
    .clk(clk),
    .rst(rst),
    .btn_inc(btn_inc),
    .btn_dec(btn_dec),
    .btn_left(btn_left),
    .btn_right(btn_right),
    .btn_save(btn_save),

    .set_able(set_able),

    .ideal_temp(ideal_temp),
    .temp_offset(temp_offset),
    .set_done(set_done),
    .oData(oData_init),
    .set(set_init)
);

combine_sensor u_sensor ( // 温湿度传感器模块
    .clk(clk),
    .start(get_data_able),
    .data_wire(data_wire),
    .temp(temp),
    .humi(humi),
    .is_done(get_data_done)
);

data_display u_display ( // 数据显示模块
    .clk(clk),
    .temp(temp),
    .humi(humi),
    .oData(oData_disp),
    .set(set_disp),
    .pwm_red_t(pwm_red_t),
    .pwm_green_t(pwm_green_t),
    .pwm_blue_t(pwm_blue_t),
    .pwm_red_h(pwm_red_h),
    .pwm_green_h(pwm_green_h),
    .pwm_blue_h(pwm_blue_h)
);

send_data u_send ( // 数据发送模块
    .clk(clk),
    .send_able(send_able),
    .temp(temp),
    .humi(humi),
    .ideal_temp(ideal_temp),
    .temp_offset(temp_offset),
    .send_done(send_done),
    .TX(TX)
);

// 状态转移逻辑
always @(posedge clk) // 同步复位，这里的复位，指的是复位到 SET_TEMP 状态，
begin                 // 和温度模块 rst 的区别是：这里的复位在更高层次，而温度模块的复位只是在设定温度时的复位
    if (rst_to_begin) // 如果需要重置到 SET_TEMP 状态
    begin
        state <= SET_TEMP;
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
        INIT_NETWORK:
        begin
            // 初始化网络
            if (net_done) // 如果网络初始化完毕
            begin
                next_state = SET_TEMP; // 转移到设定预期温度的状态
            end
        end
        SET_TEMP:
        begin
            // 设定预期温度
            if (set_done) // 如果设定完毕
            begin
                next_state = GET_DATA; // 转移到获取数据的状态
            end
        end
        GET_DATA:
        begin
            // 接温湿度并显示
            if (get_data_done) // 如果温度传感器完成了一次读取
            begin
                next_state = SEND_DATA; // 转移到发送数据的状态
            end
        end
        SEND_DATA:
        begin
            // 发送到网络
            if (send_done) // 如果发送完毕
            begin
                next_state = SET_TEMP; // 转移到设定预期温度的状态
            end
        end
        WAIT:
        begin
            // 等待 60s，再次读取温湿度
            if (counter == WAIT_TIME) // 如果计数器到 60s or 10s(调试)
            begin
                next_state = GET_DATA; // 转移到获取数据的状态
                counter = 0; // 计数器清零
            end
        end
    endcase
end

// 主进程
always @(posedge clk)
begin
    case (state)
        INIT_NETWORK:
        begin
            net_able <= 1'b1; // 启用网络
        end
        SET_TEMP:
        begin
            // 因为可能从任何状态转移到 SET_TEMP 状态，所以要重置所有的状态
            net_able <= 1'b0; // 禁用网络
            get_data_able <= 1'b0; // 禁用获取数据
            send_able <= 1'b0; // 禁用发送
            set_able <= 1'b1; // 启用设定
        end
        GET_DATA:
        begin
            set_able <= 1'b0; // 禁用设定
            get_data_able <= 1'b1; // 启用获取数据
        end
        SEND_DATA:
        begin
            get_data_able <= 1'b0; // 禁用获取数据
            send_able <= 1'b1; // 启用发送
        end
        WAIT:
        begin
            send_able <= 1'b0; // 禁用发送
            counter <= counter + 1; // 计数器加 1
        end
    endcase 
end

endmodule