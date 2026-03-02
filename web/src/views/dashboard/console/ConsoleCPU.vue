<template>
  <div id="consoleCPU" style="width: 100%; height: 100%; background: var(--container-bg); text-align: center">
    <ve-line ref="consoleCPU" :data="chartData" :extend="chartExtend" width="100%" height="100%" :legend-visible="false" />
  </div>
</template>

<script>

import moment from 'moment/moment'
import veLine from 'v-charts/lib/line'

export default {
  name: 'ConsoleCPU',
  components: {
    veLine
  },
  data() {
    return {
      chartData: {
        columns: ['time', 'data'],
        rows: []
      },

      extend: {
        title: {
          show: true,
          text: 'CPU',
          left: 'center',
          top: 20

        },
        grid: {
          show: true,
          right: '30px',
          containLabel: true
        },
        xAxis: {
          time: 'time',
          max: 'dataMax',
          boundaryGap: ['20%', '20%'],
          axisLabel: {
            formatter: (v) => {
              return moment(v).format('HH:mm:ss')
            },
            showMaxLabel: true
          }
        },
        yAxis: {
          type: 'value',
          min: 0,
          max: 1,
          splitNumber: 6,
          position: 'left',
          silent: true,
          axisLabel: {
            formatter: (v) => {
              return v * 100 + '%'
            }
          }
        },
        tooltip: {
          trigger: 'axis',
          formatter: (data) => {
            console.log(data)
            return moment(data[0].data[0]).format('HH:mm:ss') + '</br> ' +
              data[0].marker + '使用：' + (data[0].data[1] * 100).toFixed(2) + '%'
          }
        },
        series: {
          itemStyle: {
            color: '#006838'
          },
          areaStyle: {
            color: {
              type: 'linear',
              x: 0,
              y: 0,
              x2: 0,
              y2: 1,
              colorStops: [{
                offset: 0, color: '#4caf50' // 0% 处的颜色
              }, {
                offset: 1, color: '#81c784' // 100% 处的颜色
              }],
              global: false // 缺省为 false
            }
          }
        }
      }
    }
  },
  computed: {
    theme() {
      return this.$store.state.settings.theme
    },
    textColor() {
      return this.theme === 'dark' ? '#bfcbd9' : '#333'
    },
    chartExtend() {
      const color = this.textColor
      return {
        ...this.extend,
        title: {
          ...this.extend.title,
          textStyle: { color }
        },
        xAxis: {
          ...this.extend.xAxis,
          axisLabel: {
            ...this.extend.xAxis.axisLabel,
            color
          },
          axisLine: { lineStyle: { color } }
        },
        yAxis: {
          ...this.extend.yAxis,
          axisLabel: {
            ...this.extend.yAxis.axisLabel,
            color
          },
          axisLine: { lineStyle: { color } },
          splitLine: { lineStyle: { color: this.theme === 'dark' ? '#333' : '#ccc' } }
        }
      }
    }
  },
  mounted() {
    this.$nextTick(_ => {
      setTimeout(() => {
        this.$refs.consoleCPU.echarts.resize()
      }, 100)
    })
  },
  methods: {
    setData: function(data) {
      this.chartData.rows = data
    }
  }
}
</script>
