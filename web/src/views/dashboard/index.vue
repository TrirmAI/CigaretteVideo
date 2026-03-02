<template>
  <div id="app" class="app-container" style="min-height: calc(100vh - 118px); background-color: var(--bg-color); overflow-y: auto;">
    <!-- Business Overview -->
    <el-row :gutter="20" style="margin-bottom: 20px;">
      <el-col :span="6">
        <el-card shadow="hover">
          <div slot="header"><span><i class="el-icon-s-check"></i> 执法活动总数</span></div>
          <div style="font-size: 24px; font-weight: bold; color: #409EFF; text-align: center;">{{ stats.overview.lawEnforcementCount || 0 }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div slot="header"><span><i class="el-icon-warning"></i> 案事件总数</span></div>
          <div style="font-size: 24px; font-weight: bold; color: #F56C6C; text-align: center;">{{ stats.overview.caseCount || 0 }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div slot="header"><span><i class="el-icon-document"></i> 证据文件数</span></div>
          <div style="font-size: 24px; font-weight: bold; color: #E6A23C; text-align: center;">{{ stats.overview.evidenceCount || 0 }}</div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div slot="header"><span><i class="el-icon-video-camera"></i> 接入设备数</span></div>
          <div style="font-size: 24px; font-weight: bold; color: #67C23A; text-align: center;">{{ stats.overview.deviceCount || 0 }}</div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Business Charts -->
    <el-row :gutter="20" style="margin-bottom: 20px;">
      <el-col :span="12">
        <el-card>
          <div slot="header"><span><i class="el-icon-data-line"></i> 执法活动趋势 (近7天)</span></div>
          <div id="lawTrendChart" style="height: 300px;"></div>
        </el-card>
      </el-col>
      <el-col :span="12">
        <el-card>
          <div slot="header"><span><i class="el-icon-pie-chart"></i> 案事件类型分布</span></div>
          <div id="caseDistChart" style="height: 300px;"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- Recent Alarms -->
    <el-row style="margin-bottom: 20px;">
      <el-col :span="24">
        <el-card>
          <div slot="header"><span><i class="el-icon-message-solid"></i> 最新预警动态</span></div>
          <el-table :data="dashboardAlarms" style="width: 100%" height="250" stripe>
            <el-table-column prop="time" label="时间" min-width="150" align="center"></el-table-column>
            <el-table-column prop="type" label="预警类型" width="100" align="center">
              <template slot-scope="scope">
                <el-tag :type="scope.row.level === '高' ? 'danger' : (scope.row.level === '中' ? 'warning' : 'info')" effect="dark" size="mini">
                  {{ scope.row.type }}
                </el-tag>
              </template>
            </el-table-column>
            <el-table-column prop="location" label="位置" min-width="200" align="center"></el-table-column>
            <el-table-column prop="gbId" label="国标编码" min-width="220" align="center"></el-table-column>
            <el-table-column label="快照" width="80" align="center">
              <template slot-scope="scope">
                <el-image 
                  style="width: 60px; height: 40px; border-radius: 4px; cursor: pointer;"
                  :src="scope.row.snapshot" 
                  :preview-src-list="[scope.row.snapshot]"
                  fit="cover">
                  <div slot="error" class="image-slot" style="display: flex; justify-content: center; align-items: center; width: 100%; height: 100%; background: #f5f7fa; color: #909399;">
                    <i class="el-icon-picture-outline"></i>
                  </div>
                </el-image>
              </template>
            </el-table-column>
          </el-table>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import request from '@/utils/request'
import echarts from 'echarts'

export default {
  name: 'Dashboard',
  components: {},
  data() {
    return {
      timer: null,
      dashboardAlarms: [], // 独立存储告警数据，避免被 stats 覆盖
      stats: {
        overview: {},
        recentAlarms: []
      }
    }
  },
  created() {
    this.fetchBusinessStats()
    this.fetchAiAlerts()
  },
  destroyed() {
    window.clearImmediate(this.timer)
  },
  methods: {
    fetchAiAlerts() {
      // 获取 AI 告警数据，覆盖 Mock 数据
      request({ url: '/api/ext/ai/alerts', method: 'get' }).then(res => {
        // 兼容处理：有些 request 封装会直接返回 data，有些返回完整 response
        const list = Array.isArray(res) ? res : (res.data && Array.isArray(res.data) ? res.data : [])
        
        if (list.length > 0) {
          // 映射后端数据到 Dashboard 格式
          this.dashboardAlarms = list.map(item => ({
            time: item.time.split(' ')[1], // 只显示时间部分
            type: item.type,
            location: item.deviceId,
            gbId: item.gbId || '-', // 如果没有 gbId 显示 -
            snapshot: item.snapshotUrl, // 后端返回的 /demo/xxx.jpg
            level: item.confidence > 0.9 ? '高' : (item.confidence > 0.6 ? '中' : '低') // 用于前端 Tag 颜色判断
          }))
        }
      }).catch(err => {
        console.error('Fetch AI Alerts failed', err)
      })
    },
    fetchBusinessStats() {
      request({ url: '/api/ext/business/stats', method: 'get' }).then(res => {
        let data = res;
        // Frontend Fallback Mock Data
        if (!data || !data.overview || !data.overview.lawEnforcementCount) {
          console.warn('Backend returned empty stats, using frontend mock data.');
          data = {
            overview: {
              lawEnforcementCount: 1258,
              caseCount: 86,
              evidenceCount: 342,
              deviceCount: 1024
            },
            lawTrend: {
              dates: ["01-10", "01-11", "01-12", "01-13", "01-14", "01-15", "01-16"],
              values: [120, 132, 101, 134, 90, 230, 210]
            },
            caseDistribution: [
              { name: "非法入侵", value: 35 },
              { name: "车辆违停", value: 25 },
              { name: "人员聚集", value: 15 },
              { name: "烟火检测", value: 8 },
              { name: "其他", value: 3 }
            ],
            recentAlarms: [
              { time: "10:23:45", type: "非法入侵", location: "东门入口" },
              { time: "09:15:12", type: "车辆违停", location: "消防通道" },
              { time: "08:45:33", type: "人员聚集", location: "广场中心" },
              { time: "08:12:05", type: "烟火检测", location: "仓库区域" },
              { time: "07:55:10", type: "非法入侵", location: "西侧围栏" }
            ]
          };
        }
        
        this.stats = data;
        this.$nextTick(() => {
          this.initLawTrendChart(data.lawTrend);
          this.initCaseDistChart(data.caseDistribution);
        });
      }).catch(err => {
         console.error('Fetch stats failed, using fallback mock data.', err);
         const mockData = {
            overview: {
              lawEnforcementCount: 1258,
              caseCount: 86,
              evidenceCount: 342,
              deviceCount: 1024
            },
            lawTrend: {
              dates: ["01-10", "01-11", "01-12", "01-13", "01-14", "01-15", "01-16"],
              values: [120, 132, 101, 134, 90, 230, 210]
            },
            caseDistribution: [
              { name: "非法入侵", value: 35 },
              { name: "车辆违停", value: 25 },
              { name: "人员聚集", value: 15 },
              { name: "烟火检测", value: 8 },
              { name: "其他", value: 3 }
            ],
            recentAlarms: [
              { time: "10:23:45", type: "非法入侵", location: "东门入口" },
              { time: "09:15:12", type: "车辆违停", location: "消防通道" },
              { time: "08:45:33", type: "人员聚集", location: "广场中心" },
              { time: "08:12:05", type: "烟火检测", location: "仓库区域" },
              { time: "07:55:10", type: "非法入侵", location: "西侧围栏" }
            ]
          };
          this.stats = mockData;
          this.$nextTick(() => {
            this.initLawTrendChart(mockData.lawTrend);
            this.initCaseDistChart(mockData.caseDistribution);
          });
      })
    },
    initLawTrendChart(data) {
      if (!data) return;
      const chart = echarts.init(document.getElementById('lawTrendChart'));
      chart.setOption({
        tooltip: { trigger: 'axis' },
        xAxis: { type: 'category', data: data.dates },
        yAxis: { type: 'value' },
        series: [{
          data: data.values,
          type: 'line',
          smooth: true,
          areaStyle: {}
        }]
      });
    },
    initCaseDistChart(data) {
      if (!data) return;
      const chart = echarts.init(document.getElementById('caseDistChart'));
      chart.setOption({
        tooltip: { trigger: 'item' },
        legend: { bottom: '5%', left: 'center' },
        series: [{
          name: '案事件类型',
          type: 'pie',
          radius: ['40%', '70%'],
          avoidLabelOverlap: false,
          itemStyle: { borderRadius: 10, borderColor: '#fff', borderWidth: 2 },
          label: { show: false, position: 'center' },
          emphasis: { label: { show: true, fontSize: '20', fontWeight: 'bold' } },
          data: data
        }]
      });
    }
  }
}
</script>

<style scoped>
#app {
  height: 100%;
}
.control-cell {
  padding-top: 10px;
  padding-left: 5px;
  padding-right: 10px;
  height: 360px;
}

/* Dark Theme Adaptation */
::v-deep .el-card {
  background-color: var(--container-bg);
  border-color: var(--border-color-base);
  color: var(--text-color-primary);
}

::v-deep .el-card__header {
  border-bottom-color: var(--border-color-base);
}

::v-deep .el-table {
  background-color: transparent;
  color: var(--text-color-regular);
  
  th, tr {
    background-color: transparent;
  }
  
  /* Header background */
  thead th {
    background-color: var(--background-color-base);
    color: var(--text-color-primary);
    border-bottom-color: var(--border-color-base);
  }

  /* Force transparent for rows to avoid white background */
  .el-table__body tr {
    background-color: transparent !important;
  }
  
  .el-table__body td {
    background-color: transparent !important;
  }
  
  /* Stripe row background - needs !important to override element style */
  &.el-table--striped .el-table__body tr.el-table__row--striped td {
    background-color: rgba(128, 128, 128, 0.05) !important;
  }
  
  /* Hover row background */
  .el-table__body tr:hover > td {
    background-color: rgba(128, 128, 128, 0.1) !important;
  }
  
  td, th.is-leaf {
    border-bottom-color: var(--border-color-base);
  }
}
</style>
