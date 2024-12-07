#include <ESP8266WiFi.h>
#include "config.h"   // 配置文件

extern "C"
{
#include "user_interface.h"
#include "wpa2_enterprise.h"
}

void setup()
{
  // 设置WiFi模式为STA（Station）
  WiFi.mode(WIFI_STA);
  Serial.begin(9600);  // 初始化串口通信，波特率为9600
  delay(3000);  // 延时3秒

  // wifi_set_phy_mode(PHY_MODE_11B);  // 802.11b only

  struct station_config wifi_config;

  // 清空wifi_config结构体
  memset(&wifi_config, 0, sizeof(wifi_config));

  // 设置WiFi SSID和密码，仍然是必须的，作为连接到网络的第一步
  strcpy((char*)wifi_config.ssid, ssid);
  strcpy((char*)wifi_config.password, password);

  // 设置WiFi配置
  wifi_station_set_config(&wifi_config);
  
  // 启用WPA2企业认证

  // wifi_station_set_wpa2_enterprise_auth(1);
    
  // 设置企业身份、用户名和密码
  // wifi_station_set_enterprise_identity((uint8*)identity, strlen(identity));
  // wifi_station_set_enterprise_username((uint8*)username, strlen(username));
  // wifi_station_set_enterprise_password((uint8*)password, strlen((char*)password));

  // 连接WiFi
  wifi_station_connect();
  while (WiFi.status() != WL_CONNECTED)
  {
    delay(1000);  // 每秒检查一次连接状态
    Serial.print(".");
  }

  // WiFi连接成功后打印相关信息
  Serial.println("WiFi connected");
  Serial.println("IP address: ");
  Serial.println(WiFi.localIP());
}

void loop()
{
  // 空循环
}