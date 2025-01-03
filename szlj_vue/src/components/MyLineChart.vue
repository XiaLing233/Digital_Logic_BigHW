<template>
    <Line
    ref="chart"
    :data="chartData"
    :options="chartOptions"
    />
</template>
  
  <script>
  import { Line } from 'vue-chartjs'
  import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale,
//   Filler,
//   Filler
} from 'chart.js'

import 'chartjs-adapter-dayjs-4'

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
  TimeScale,
//   Filler
)
  
  export default {
    name: 'LineChart',
    components: { Line },
    props: {
        chartData: {
            type: Object,
            required: true
        },
        chartOptions: {
            type: Object,
            default: () => ({
                maintainAspectRatio: false,  // 禁用保持宽高比，允许自适应
                responsive: true, // 得有这句，不然不会自适应
                scales: {
                    x: {
                        type: 'time',  // 设置 x 轴为时间类型
                        time: {
                        unit: 'minute', // 设置单位为分钟
                        unitStepSize: 5, // 设置步长为 5 分钟
                        tooltipFormat: 'll HH:mm', // 提示框中显示时间的格式
                        },
                        ticks: {
                            callback: function(value, index) {
                                const date = new Date(this.getLabelForValue(value));
                                return date.toLocaleTimeString('zh-CN', { 
                                    hour12: false,
                                    hour: '2-digit',
                                    minute: '2-digit',
                                    second: '2-digit'
                                });
                            }
                        }
                    }
                }
            })
        },
    },
    watch: {
    // 监听 chartData 或 chartOptions 的变化，并手动触发更新
    chartData(newValue, oldValue) {
      if (newValue !== oldValue && this.$refs.chart) {
        this.$nextTick(() => {
          this.$refs.chart.$chart.update()
        })
      }
    },
    chartOptions(newValue, oldValue) {
      if (newValue !== oldValue && this.$refs.chart) {
        this.$nextTick(() => {
          this.$refs.chart.$chart.update()
        })
      }
    }
  }
  }
  </script>