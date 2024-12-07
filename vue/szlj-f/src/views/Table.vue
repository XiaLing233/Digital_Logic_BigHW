<script>
import { Line } from 'vue-chartjs';
import { Chart as ChartJS, Title, Tooltip, Legend, LineElement, PointElement, CategoryScale, LinearScale } from 'chart.js';

ChartJS.register(Title, Tooltip, Legend, LineElement, PointElement, CategoryScale, LinearScale);

export default {
    components: {
    LineChart: Line
  },
    data () {
        return {
            sel_type: "hour", // hour, day, week, month
            data: [ {temperature: 0, humidity: 0, ideal_tmp: 0, diff: 0, time: 0}], // 存放后端返回的数据
            status: "OK", // 存放后端返回的状态
            message: "", // 存放后端返回的消息
        }
    },

    methods: {
        fetchData() {
            // 向后端请求数据
            fetch('api/data', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    type: this.sel_type,
                }),
            })
            .then(response => response.json())
            .then(data => {
                this.data = data.data;
                this.status = data.status;
            })
            .catch((error) => {
                console.error('Error:', error);
            });
        }
    },
}


</script>

<template>
    <LineChart />
</template>