#include <WiFi.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <WiFiClientSecure.h>
#include "esp_eap_client.h"   // ESP32 的 EAP 头文件 esp_wpa2.h is deprecated
#include "config.h"     // 配置文件，涉及账号密码，不出现在 Git 中

#define IS_HTTPS 1

#if IS_HTTPS
const char* BACKEND_HOST = "https://szlj.xialing.icu/api/data_store";
#else
const char* BACKEND_HOST = "http://localhost:8000/api/data_store"; // 没用，因为连接的是学校网络，怎么 localhost 到本机呢?
#endif

// 和开发板连接的串口的设置 这里使用 UART2，参见
// https://controllerstech.com/wp-content/uploads/2022/06/esp321_3.avif
const int UART_BAUD_RATE = 115200;
const int UART_RX_PIN = 16;         // D16
const int UART_TX_PIN = 17;         // D17

#if IS_HTTPS
WiFiClientSecure client;    // 创建一个安全的客户端 
#endif

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
    delay(500);
    digitalWrite(2, LOW);
    delay(500);
  }

    while (true)
    {
      Serial.println("Connecting...");
      Serial.flush();

      // 配置 WPA2-Enterprise 参数
      WiFi.disconnect(true);      // 断开现有连接
      WiFi.mode(WIFI_STA);

      // 设置 WPA2-Enterprise 配置
      esp_eap_client_set_identity((uint8_t *)IDENTITY, strlen(IDENTITY));
      esp_eap_client_set_username((uint8_t *)USERNAME, strlen(USERNAME));
      esp_eap_client_set_password((uint8_t *)PASSWORD, strlen(PASSWORD));
      
      // 启用 WPA2-Enterprise
      esp_wifi_sta_enterprise_enable();

      WiFi.begin(SSID);     // 对于 WPA2-Enterprise，密码参数设为 NULL

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
          continue;
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

#if IS_HTTPS
      client.setCACert(ROOT_CA);   // 设置根证书
#endif

      break;
    }
}

// 发送 POST 请求
void sendHttpsRequest(uint16_t temperature, uint16_t humidity, uint16_t ideal_tmp, uint8_t diff)
{
  if (WiFi.status() == WL_CONNECTED)
  {
    Serial.print("device_mac: ");
    Serial.println(WiFi.macAddress());
    Serial.print("device_ip: ");
    Serial.println(WiFi.localIP().toString());
    Serial.print("device_name: ");
    Serial.println("SZLJ_ESP32");
    
#if IS_HTTPS
    HTTPClient https;           // 创建一个 HTTP 客户端

    // 设置请求头
    if (https.begin(client, BACKEND_HOST))
    {
      https.addHeader("Content-Type", "application/json");
      
      // 创建 JSON 对象
      StaticJsonDocument<200> doc;
      doc["temperature"] = temperature;
      doc["humidity"] = humidity;
      doc["ideal_temp"] = ideal_tmp;
      doc["diff"] = diff;
      doc["device_mac"] = WiFi.macAddress();
      doc["device_ip"] = WiFi.localIP().toString();
      doc["device_name"] = "SZLJ_ESP32";

      // 将 JSON 对象转换为字符串
      String jsonStr;
      serializeJson(doc, jsonStr);

      // 发送 POST 请求
      int httpCode = https.POST(jsonStr);

      // 检查请求是否成功
      if (httpCode > 0)
      {
        String payload = https.getString();
        Serial.println(httpCode);
        Serial.println(payload);
        Serial2.write(0x99);      // 发送成功信号
      }
      else
      {
        Serial.println("发送请求失败");
        Serial2.write(0xee);      // 发送失败信号
      }

      // 关闭连接
      https.end();
    }
#else
    HTTPClient http;           // 创建一个 HTTP 客户端

    // 设置请求头
    if (http.begin(BACKEND_HOST))
    {
      http.addHeader("Content-Type", "application/json");
      
      // 创建 JSON 对象
      StaticJsonDocument<400> doc;
      doc["temperature"] = temperature;
      doc["humidity"] = humidity;
      doc["ideal_temp"] = ideal_tmp;
      doc["diff"] = diff;
      doc["device_mac"] = WiFi.macAddress();
      doc["device_ip"] = WiFi.localIP().toString();
      doc["device_name"] = "SZLJ_ESP32";

      // 将 JSON 对象转换为字符串
      String jsonStr;
      serializeJson(doc, jsonStr);

      // 发送 POST 请求
      int httpCode = http.POST(jsonStr);

      // 检查请求是否成功
      if (httpCode > 0)
      {
        String payload = http.getString();
        Serial.println(httpCode);
        Serial.println(payload);
        Serial2.write(0x99);      // 发送成功信号
      }
      else
      {
        Serial.println("发送请求失败");
        Serial.print("错误码：");
        Serial.println(httpCode);
        Serial2.write(0xee);      // 发送失败信号
      }

      // 关闭连接
      http.end();
    }
#endif
  }
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

    temperature = ((receivedData[0] << 8) | receivedData[1]);
    humidity = ((receivedData[2] << 8)| receivedData[3]);
    ideal_tmp = ((receivedData[4] << 8) | receivedData[5]);
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
    Serial.print("Ideal Temperature: ");
    Serial.println(ideal_tmp);
    Serial.print("Humidity: ");
    Serial.println(humidity);
    Serial.print("Humidity(HEX): ");
    Serial.println(humidity, HEX);
    Serial.print("Difference: ");
    Serial.println(diff);

    // 向服务器发送 POST 请求
    sendHttpsRequest(temperature, humidity, ideal_tmp, diff);
  }
}
