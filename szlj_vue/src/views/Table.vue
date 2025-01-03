<template>
    <a-config-provider :locale="zhCN">
        <div style="margin : 10px 10px 0px 10px">
            <a-card title="查询条件">
                <h3>请选择日期</h3>        
                <div :style="{ width: '300px', border: '1px solid #d9d9d9', borderRadius: '4px' }">
                    <a-calendar :value="selectedDate" :fullscreen="false" @select="onSelect" @panelChange="onPanelChange"/>
                </div>
                <!-- <a-button type="primary" style="margin-top: 16px" @click="fetchData">查询</a-button> -->
            </a-card>
        
            <a-card title="结果">
                <h3>日期：{{ selectedDate.format('YYYY-MM-DD') }}</h3>
            <a-card :loading="isLoading" title="温度曲线">
                <!--采用 Chartjs 的折线图展示 data 的数据-->
                <div v-if = "temp_data.labels.length > 0" style="height: 50vh; display: flex; justify-content: center; align-items: center;">
                    <!-- <div>{{ data }}</div> -->
                    <MyLineChart :chartData="temp_data" />
                </div>
                <div v-else style="text-align: center; padding: 20px;">
                    <h2>暂无数据</h2>
                </div>
            </a-card>
            <a-card :loading="isLoading" title="湿度曲线">
                <!--采用 Chartjs 的折线图展示 data 的数据-->
                <div v-if = "humi_data.labels.length > 0" style="height: 50vh; display: flex; justify-content: center; align-items: center;">
                    <!-- <div>{{ data }}</div> -->
                    <MyLineChart :chartData="humi_data" />
                </div>
                <div v-else style="text-align: center; padding: 20px;">
                    <h2>暂无数据</h2>
                </div>
            </a-card>                
        </a-card>
        </div>
    </a-config-provider>
</template>

<script>
import dayjs from 'dayjs';
import zhCN from 'ant-design-vue/es/locale/zh_CN';
import 'dayjs/locale/zh-cn';
import MyLineChart from '../components/MyLineChart.vue';
import { notification } from 'ant-design-vue';

dayjs.locale('zh-cn');

export default {
    data() {
        return {
            zhCN, // 就必须得有这句..
            selectedDate: dayjs(), // 默认选今天
            temp_data: {
                labels: [],
                datasets: [
                    {
                        label: '实际温度',
                        backgroundColor: 'rgba(2, 159, 253, 0.0)',
                        borderColor: 'rgba(2, 159, 253, 1)',
                        fill: false,
                        pointStyle: false,
                        tension: 0.4,
                        data: [],
                    },
                    {
                        label: '理想温度',
                        backgroundColor: 'rgba(128, 128, 128, 0.0)',
                        borderColor: 'rgba(128, 128, 128, 1)',
                        fill: false,
                        pointStyle: false,
                        tension: 0.4,
                        data: [],
                    },
                ],
            },
            humi_data: {
                labels: [],
                datasets: [
                    {
                        label: '湿度',
                        backgroundColor: 'rgba(2, 159, 253, 0.0)',
                        borderColor: 'rgba(2, 159, 253, 1)',
                        fill: false,
                        pointStyle: false,
                        tension: 0.4,
                        data: [],
                    },
                ],
            },
            isLoading: false,
            errMsg : "",
        };
    },
    methods: {
        onSelect(date) {
            this.selectedDate = date;
            console.log(this.selectedDate);
            this.fetchData();
        },
        onPanelChange(date) {
            this.selectedDate = date;
            console.log(this.selectedDate);
        },
        openNotification(placement) {
            notification.open(
            {
                message: '错误',
                description: this.errMsg,
                placement,
            });
        },
        // 向后端请求数据
        /*
        传给后端的 json 数据格式：
        {
            "date" : "2025-01-03", // 日期
        }
        '''
        '''
        后端返回的 json 数据格式：
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
        */
        fetchData() {
            this.isLoading = true;
            const req_data = {
                date: this.selectedDate.format('YYYY-MM-DD'),
            };
            // console.log(req_data);
            fetch('/api/data_get', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify(req_data),
            })

            .then((response) => response.json())
            .then((data) => {
                if (data.status === 'ok') {
                    console.log(data);
                this.temp_data = {
                    labels: data.data.map((item) => item.timestamp),
                    datasets: [
                        {
                            label: '实际温度',
                            backgroundColor: 'rgba(2, 159, 253, 0.0)',
                            borderColor: 'rgba(2, 159, 253, 1)',
                            data: data.data.map((item) => item.temperature),
                            pointStyle: false,
                            fill: false,
                            tension: 0.4
                        },
                        {
                            label: '理想温度',
                            backgroundColor: 'rgba(128, 128, 128, 0.0)',
                            borderColor: 'rgba(128, 128, 128, 1)',
                            data: data.data.map((item) => item.ideal_temp),
                            pointStyle: false,
                            fill: false,
                            tension: 0.4
                        }
                    ]
                };
                this.humi_data = {
                    labels: data.data.map((item) => item.timestamp),
                    datasets: [{
                        label: '湿度',
                        backgroundColor: 'rgba(2, 159, 253, 0.0)',
                        borderColor: 'rgba(2, 159, 253, 1)',
                        data: data.data.map((item) => item.humidity),
                        pointStyle: false,
                        fill: false,
                        tension: 0.4
                    }]
                };
                }
                else {
                    this.$message.error(data.msg);
                    this.errMsg = data.msg;
                    console.error('Error:', error);
                }
                this.isLoading = false;
                })
                .catch((error) => {
                    this.isLoading = false;
                    this.errMsg = "服务端错误，请稍后再试";
                    this.openNotification('topRight');
                    console.error('Error:', error);
                });
        }
    },
    components: {
        MyLineChart,
    },
    mounted() {
        this.fetchData();
    },
};
</script>