<template>
  <div id="ConsoleNet" style="width: 100%; height: 100%; background: var(--container-bg); text-align: center">
    <ve-bar ref="ConsoleNet" :data="chartData" :extend="chartExtend" :settings="chartSettings" width="100%" height="100%" ></ve-bar>
  </div>
</template>

<script>

import veBar from 'v-charts/lib/bar'

export default {
  name: 'ConsoleNet',
  components: {
    veBar
  },
  data() {
    return {
      chartData: {
        columns: ['path','free','use'],
        rows: []
      },
      chartSettings: {
        stack: {
          'xxx': ['free', 'use']
        },
        labelMap: {
          'free': '剩余',
          'use': '已使用'
        },
        itemStyle: {
          color: (params) => {
            if (params.seriesIndex === 0) {
              return '#4caf50' // Free (Lighter Green)
            } else {
              return '#006838' // Used (Tobacco Green)
            }
          }
        }
      },
      extend: {
        title: {
          show: true,
          text: "磁盘",
          left: "center",
          top: 20,
        },
        grid: {
          show: true,
          right: "30px",
          containLabel: true,
        },
        series: {
          barWidth: 30
        },
        legend: {
          left: "center",
          bottom: "15px",
        },
        tooltip: {
          trigger: 'axis',
          formatter: (data)=>{
            console.log(data)
            let relVal = "";
            for (let i = 0; i < data.length; i++) {
              relVal +=  data[i].marker + data[i].seriesName + ":" + data[i].value.toFixed(2) + "GB"
              if (i < data.length - 1) {
                relVal += "</br>";
              }
            }
            return relVal;
          }
        },

      }
    };
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
      setTimeout(()=>{
        this.$refs.ConsoleNet.echarts.resize()
      }, 100)
    })
  },
  destroyed() {
  },
  methods: {
    setData: function(data) {
      this.chartData.rows = data;
    }
  }
};
</script>
