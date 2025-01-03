import configparser
from flask import Flask, request, jsonify
from flask_cors import CORS  # 导入 CORS
import mysql.connector
import logging
import os
from datetime import datetime
import pytz

app = Flask(__name__)

CORS(app) # 允许跨域请求

CONFIG = configparser.ConfigParser()
CONFIG.read('config.ini')

# 设置数据库连接
DB_HOST = CONFIG['database']['host']
DB_USER = CONFIG['database']['user']
DB_PASSWORD = CONFIG['database']['password']
DB_USER_READ_ONLY = CONFIG['database']['user-read-only']
DB_PASSWORD_READ_ONLY = CONFIG['database']['password-read-only']
DB_DATABASE = CONFIG['database']['database']
DB_PORT = int(CONFIG['database']['port'])
DB_CHARSET = CONFIG['database']['charset']

# 数据库
TABLE_NAME = CONFIG['table']['name']
TEMP = CONFIG['table']['temp']
HUMI = CONFIG['table']['humi']
IDEAL_TEMP = CONFIG['table']['ideal-temp']
IDEAL_HUMI = CONFIG['table']['ideal-humi']
TEMP_DIFF = CONFIG['table']['temp-diff']
TIMESTAMP = CONFIG['table']['timestamp']

# 日志
INFO_ADDR = CONFIG['log']['info-addr']
ENCODING = CONFIG['log']['encoding']

# 数据库配置
DB_CONFIG = {
    'host': DB_HOST,
    'user': DB_USER,
    'password': DB_PASSWORD,
    'database': DB_DATABASE,
    'port': DB_PORT,
    'charset': DB_CHARSET
}

# 数据库只读配置
DB_CONFIG_READ_ONLY = {
    'host': DB_HOST,
    'user': DB_USER_READ_ONLY,
    'password': DB_PASSWORD_READ_ONLY,
    'database': DB_DATABASE,
    'port': DB_PORT,
    'charset': DB_CHARSET
}

# 配置日志
def setup_logger():
    # 确保日志目录存在
    os.makedirs(INFO_ADDR, exist_ok=True)
    
    # 主日志配置
    logger = logging.getLogger('main')
    logger.setLevel(logging.INFO)
    
    # 日常日志文件
    daily_handler = logging.FileHandler(
        f'{INFO_ADDR}{datetime.now().strftime("%Y-%m-%d")}.log',
        encoding = ENCODING
    )
    daily_handler.setLevel(logging.INFO)
    
    # 设置日志格式
    formatter = logging.Formatter('%(asctime)s - %(levelname)s\n%(message)s', datefmt='%Y-%m-%d %H:%M:%S')
    daily_handler.setFormatter(formatter)
    
    logger.addHandler(daily_handler)
    return logger

LOGGER = setup_logger()


# 获得温湿度
'''
传入的 json 数据格式：
{
    "temperature": "温度",
    "humidity": "湿度",
    "ideal_temp": "理想温度",
    "diff": "温差",
    "device_mac": "设备 MAC 地址",
    "device_ip": "设备 IP 地址",
    "device_name": "设备名称",
}
'''
@app.route('/api/data_store', methods=['POST'])
def data_store():
    # 获取 json 数据
    data = request.json
    temperature = data['temperature'] * 1.0 / 10        # 因为传入的是整数，所以要除以 10
    humidity = (data['humidity'] - 32768) * 1.0 / 10     # 因为传入的是整数，所以要除以 10, 32768 的事儿，正常不应该需要，但是这个传感器有点问题
    ideal_temp = data['ideal_temp'] * 1.0 / 10          # 因为传入的是整数，所以要除以 10
    diff = data['diff'] * 1.0 / 10                      # 因为传入的是整数，所以要除以 10
    device_mac = data['device_mac']
    device_ip = data['device_ip']
    device_name = data['device_name']

    # 判断是不是合法的来源
    if (device_name != "SZLJ_ESP32" or device_mac != "F0:24:F9:5A:A3:94"):
        # 记录日志
        LOGGER.info(f"非法来源: device_mac: {device_mac}, device_name: {device_name}")
        return jsonify({
            'status': 'fail',
            'msg': '非法来源'
        }), 403
    
    # 判断数据是否合法
    verify_temperature = data['temperature']
    if (verify_temperature & 0x8000): # 温度的最高位是 1，说明是负数，把最高位去掉，再乘以 -1
        verify_temperature = (verify_temperature & 0x7FFF) * -1
        if (verify_temperature <= -400):
            # 记录日志
            LOGGER.info(f"温度数据不合法: temperature: {temperature}, verify_temperature: {verify_temperature}")
            return jsonify({
                'status': 'fail',
                'msg': '温度数据不合法'
            }), 400
    else: # 温度的最高位是 0，说明是正数
        if (verify_temperature >= 800):
            # 记录日志
            LOGGER.info(f"温度数据不合法: temperature: {temperature}, verify_temperature: {verify_temperature}")
            return jsonify({
                'status': 'fail',
                'msg': '温度数据不合法'
            }), 400

    if (humidity <= 0 or humidity >= 100): # 湿度是已经处理过的
        # 记录日志
        LOGGER.info(f"湿度数据不合法: humidity: {humidity}")
        return jsonify({
            'status': 'fail',
            'msg': '湿度数据不合法'
        }), 400

    # 调试
    print("temperature: ", temperature)
    print("humidity: ", humidity)
    print("ideal_temp: ", ideal_temp)
    print("diff: ", diff)
    print("device_mac: ", device_mac)
    print("device_ip: ", device_ip)
    print("device_name: ", device_name)

    # 记录日志
    LOGGER.info(f"合法的：\ntemperature: {temperature}, humidity: {humidity}, ideal_temp: {ideal_temp}, diff: {diff}, device_mac: {device_mac}, device_ip: {device_ip}, device_name: {device_name}")

    # 连接数据库
    conn = mysql.connector.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # 获取当前时间（上海时区）
    tz = pytz.timezone('Asia/Shanghai')
    now = datetime.now(tz).strftime('%Y-%m-%d %H:%M:%S')

    # 插入数据
    sql = f"INSERT INTO {TABLE_NAME} ({TEMP}, {HUMI}, {IDEAL_TEMP}, {TEMP_DIFF}, {TIMESTAMP}) VALUES ({temperature}, {humidity}, {ideal_temp}, {diff}, '{now}')" # now 是字符串，所以要加引号

    print("sql: ", sql)

    # 记录日志
    LOGGER.info(f"data_store 执行的sql语句是: {sql}")

    cursor.execute(sql)

    # 提交
    conn.commit()

    # 关闭数据库
    cursor.close()
    conn.close()

    return jsonify({
        'status': 'ok',
        'msg': '数据存储成功'
    }), 200

# 前端获取数据
'''
传入的 json 数据格式：
{
    "date": "日期", // 形如 2025-01-01
}
'''
'''
返回的 json 数据格式：
{
    "status": "ok",
    "msg": "数据获取成功",
    "data": [
        {
            "temperature": "温度",
            "humidity": "湿度",
            "ideal_temp": "理想温度",
            "diff": "温差",
            "timestamp": "时间戳" // 形如 2025-01-01 00:00:00
        },
        ...
    ]
}
'''
@app.route('/api/data_get', methods=['POST'])
def data_get():
    # 获取 json 数据
    data = request.json
    date = data['date']

    # 记录日志
    LOGGER.info(f"请求的日期: {date}")

    # 连接数据库
    conn = mysql.connector.connect(**DB_CONFIG_READ_ONLY)
    cursor = conn.cursor()

    # 查询数据
    sql = f"SELECT * FROM {TABLE_NAME} WHERE DATE({TIMESTAMP}) = '{date}'"

    # 记录日志
    LOGGER.info(f"data_get 执行的sql语句是: {sql}")

    cursor.execute(sql)
    result = cursor.fetchall()

    # 关闭数据库
    cursor.close()
    conn.close()

    # 处理数据
    data = []
    for row in result:
        # Convert UTC timestamp to Shanghai timezone
        tz = pytz.timezone('Asia/Shanghai')
        local_time = row[5].astimezone(tz).strftime('%Y-%m-%d %H:%M:%S')
        data.append({
            'temperature': row[1],
            'humidity': row[2],
            'ideal_temp': row[3],
            'diff': row[4],
            'timestamp': local_time
        })

    return jsonify({
        'status': 'ok',
        'msg': '数据获取成功',
        'data': data
    }), 200
