#include <WiFi.h>
#include "esp_eap_client.h"   // ESP32 的 EAP 头文件 esp_wpa2.h is deprecated
#include "config.h"     // 配置文件，涉及账号密码，不出现在 Git 中

// 和开发板连接的串口的设置 这里使用 UART2，参见
// https://controllerstech.com/wp-content/uploads/2022/06/esp321_3.avif
const int UART_BAUD_RATE = 115200;
const int UART_RX_PIN = 16;         // D16
const int UART_TX_PIN = 17;         // D17

void setup()
{
  Serial.begin(115200);  // 初始化串口通信，波特率为115200
  Serial2.begin(UART_BAUD_RATE, SERIAL_8N1, UART_RX_PIN, UART_TX_PIN); // 这个串口是用来和开发板通信的
  delay(1000);  // 延时1秒

  Serial.println("Waiting for start signal (0x99)...");

  while (true)
  {
    if (Serial2.available() > 0)
    { 
      uint8_t receivedByte = Serial2.read();

      if (receivedByte == 0x99)
      {
        Serial.println("Received start signal (0x99)");
        break;
      }
    }

    // 连接中，LED 灯闪烁
    Serial.println("Waiting for input...");
    pinMode(2, OUTPUT);
    digitalWrite(2, HIGH);
    delay(100);
    digitalWrite(2, LOW);

    delay(10);  // 短暂延时，避免过度占用 CPU
  }

    Serial.println("Connecting...");
    Serial.flush();

    // 配置 WPA2-Enterprise 参数
    WiFi.disconnect(true);      // 断开现有连接
    WiFi.mode(WIFI_STA);

    // 设置 WPA2-Enterprise 配置
    esp_eap_client_set_identity((uint8_t *)identity, strlen(identity));
    esp_eap_client_set_username((uint8_t *)username, strlen(username));
    esp_eap_client_set_password((uint8_t *)password, strlen(password));
    
    // 启用 WPA2-Enterprise
    esp_wifi_sta_enterprise_enable();

    WiFi.begin(ssid);     // 对于 WPA2-Enterprise，密码参数设为 NULL

    int counter = 0;

    // 等待连接
    while (WiFi.status() != WL_CONNECTED)
    {
      delay(1000);  // 每秒检查一次连接状态
      Serial.print(".");
      counter++;

      if (counter >= 20)
      {
        Serial2.write(0xee);
        counter = 0;
        ESP.restart();
      }
    }

    // WiFi连接成功后打印相关信息
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
    Serial2.write(0x99);
    Serial.write(0x99);

    // 连接成功后，LED 灯亮
    pinMode(2, OUTPUT);
    digitalWrite(2, HIGH);
}

void loop()
{
  uint8_t receivedData[7]; // 存储接收到的字节数据
  uint16_t temperature = 0;
  uint16_t humidity = 0;
  uint16_t ideal_tmp = 0;
  uint8_t diff = 0;

  // 读取数据
  if (Serial2.available() >= 7)
  {
    // 读取 7 个字节的数据
    for (int i = 0; i < 7; i++)
    {
      receivedData[i] = Serial2.read();
    }

    temperature = (receivedData[0] | (receivedData[1] << 8));
    humidity = (receivedData[2] | (receivedData[1] << 3));
    ideal_tmp = (receivedData[4] | (receivedData[5] << 8));
    diff = receivedData[6];

    // 对温度的特殊处理
    if (temperature & 0x8000) // 如果最高位为 1，说明是负数，舍弃最高位，取反加一
    {
      temperature = temperature & 0x7FFF;
      temperature = -temperature;
    }

    // 打印一下，看看数据是否正确
    Serial.print("Temperature: ");
    Serial.println(temperature);
    Serial.print("Humidity: ");
    Serial.println(humidity);
    Serial.print("Ideal Temperature: ");
    Serial.println(ideal_tmp);
    Serial.print("Difference: ");
    Serial.println(diff);
  }


  // 后面还有 POST 请求的代码，暂时不写了

}
