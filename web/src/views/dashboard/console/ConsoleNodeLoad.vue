<template>
  <div id="ConsoleNodeLoad" style="width: 100%; height: 100%; background: var(--container-bg); text-align: center">
    <ve-histogram ref="consoleNodeLoad" :data="chartData" :extend="chartExtend" :events="events" :settings="chartSettings"
                  width="100%" height="100%" :legend-visible="true"/>

    <HasStreamChannel ref="hasStreamChannel"/>
  </div>
</template>

<script>
import veHistogram from 'v-charts/lib/histogram'
import HasStreamChannel from "@/views/dialog/hasStreamChannel";

export default {
  name: 'ConsoleNodeLoad',
  components: {
    veHistogram,
    HasStreamChannel
  },
  data() {
    return {
      chartData: {
        columns: ['id', 'push', 'proxy', 'gbReceive', 'gbSend'],
        rows: []
      },
      chartSettings: {
        labelMap: {
          'push': '直播推流',
          'proxy': '拉流代理',
          'gbReceive': '国标收流',
          'gbSend': '国标推流'
        },
        itemStyle: {
          color: (params) => {
            const colors = ['#006838', '#4caf50', '#81c784', '#a5d6a7']; // Tobacco Green palette
            return colors[params.seriesIndex % colors.length];
          }
        }
      },
      extend: {
        title: {
          show: true,
          text: '节点负载',
          left: 'center',
          top: 20

        },
        legend: {
          left: 'center',
          bottom: '15px'
        },
        label: {
          show: true,
          position: 'top'
        }
      },
      events: {
        click: this.onClick
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
          axisLabel: { color },
          axisLine: { lineStyle: { color } }
        },
        yAxis: {
          axisLabel: { color },
          axisLine: { lineStyle: { color } },
          splitLine: { lineStyle: { color: this.theme === 'dark' ? '#333' : '#ccc' } }
        }
      }
    }
  },
  mounted() {
    this.$nextTick(_ => {
      setTimeout(() => {
        this.$refs.consoleNodeLoad.echarts.resize()
      }, 100)
    })
  },
  methods: {
    setData: function (data) {
      this.chartData.rows = data
    },
    onClick(v) {
      if (v.seriesName === "国标收流") {
        this.$refs.hasStreamChannel.openDialog();
      }
    }
  }
}
</script>
