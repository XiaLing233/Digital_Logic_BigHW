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
//   Filler,
//   Filler
} from 'chart.js'
  
ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  Title,
  Tooltip,
  Legend,
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
                        ticks: {
                            callback: function(value) {
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
                },
                plugins: {
                    tooltip: {
                        callbacks: {
                            title: function(context) {
                                const date = new Date(context[0].label);
                                return date.toLocaleTimeString('zh-CN', {
                                    hour12: false,
                                    hour: '2-digit',
                                    minute: '2-digit',
                                    second: '2-digit'
                                });
                            },
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