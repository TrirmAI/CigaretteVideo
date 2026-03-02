<template>
  <div id="ConsoleNet" style="width: 100%; height: 100%; background: var(--container-bg); text-align: center">
    <ve-line ref="ConsoleNet" :data="chartData" :extend="chartExtend" :settings="chartSettings" :events="chartEvents" width="100%" height="100%" />
  </div>
</template>

<script>

import veLine from 'v-charts/lib/line'
import moment from 'moment/moment'

export default {
  name: 'ConsoleNet',
  components: {
    veLine
  },
  data() {
    return {
      chartData: {
        columns: ['time', 'out', 'in'],
        rows: []
      },
      chartSettings: {
        area: true,
        labelMap: {
          'in': '下载',
          'out': '上传'
        },
        itemStyle: {
          color: (params) => {
            if (params.seriesIndex === 0) {
              return '#006838' // Upload (Tobacco Green)
            } else {
              return '#4caf50' // Download (Lighter Green)
            }
          }
        },
        areaStyle: {
          color: (params) => {
            if (params.seriesIndex === 0) {
              return {
                type: 'linear',
                x: 0,
                y: 0,
                x2: 0,
                y2: 1,
                colorStops: [{
                  offset: 0, color: '#006838' // 0% 
                }, {
                  offset: 1, color: '#4caf50' // 100% 
                }],
                global: false
              }
            } else {
              return {
                type: 'linear',
                x: 0,
                y: 0,
                x2: 0,
                y2: 1,
                colorStops: [{
                  offset: 0, color: '#4caf50' // 0% 
                }, {
                  offset: 1, color: '#81c784' // 100% 
                }],
                global: false
              }
            }
          }
        }
      },
      extend: {
        title: {
          show: true,
          text: '网络',
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
          max: 1000,
          splitNumber: 6,
          position: 'left',
          silent: true
        },
        tooltip: {
          trigger: 'axis',
          formatter: (data) => {
            let in_sel = true
            let out_sel = true
            for (const key in this.extend.legend.selected) {
              if (key == '上传') {
                out_sel = this.extend.legend.selected[key]
              }
              if (key == '下载') {
                in_sel = this.extend.legend.selected[key]
              }
            }
            if (out_sel && in_sel) {
              return (
                data[1].marker +
                '下载：' +
                parseFloat(data[1].data[1]).toFixed(2) +
                'Mbps' +
                '</br> ' +
                data[0].marker +
                '上传：' +
                parseFloat(data[0].data[1]).toFixed(2) +
                'Mbps'
              )
            } else if (out_sel) {
              return (
                data[0].marker +
                '上传：' +
                parseFloat(data[0].data[1]).toFixed(2) +
                'Mbps'
              )
            } else if (in_sel) {
              return (
                data[0].marker +
                '下载：' +
                parseFloat(data[0].data[1]).toFixed(2) +
                'Mbps'
              )
            }
            return ''
          }
        },
        legend: {
          left: 'center',
          bottom: '15px',
          selected: {}
        }
      },
      chartEvents: {
        legendselectchanged: (item) => {
          this.extend.legend.selected = item.selected
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
        legend: {
          ...this.extend.legend,
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
        this.$refs.ConsoleNet.echarts.resize()
      }, 100)
    })
  },
  methods: {
    setData: function(data, total) {
      this.chartData.rows = data
      this.extend.yAxis.max = total
    }

  }
}
</script>
