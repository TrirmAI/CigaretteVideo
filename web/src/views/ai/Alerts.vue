<template>
  <div class="app-container">
    <!-- 统计看板 -->
    <el-row :gutter="20" class="panel-group">
      <el-col :xs="12" :sm="12" :lg="6" class="card-panel-col">
        <div class="card-panel">
          <div class="card-panel-icon-wrapper icon-message">
            <i class="el-icon-bell card-panel-icon" />
          </div>
          <div class="card-panel-description">
            <div class="card-panel-text">今日告警</div>
            <span class="card-panel-num">128</span>
          </div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="12" :lg="6" class="card-panel-col">
        <div class="card-panel">
          <div class="card-panel-icon-wrapper icon-time">
            <i class="el-icon-time card-panel-icon" />
          </div>
          <div class="card-panel-description">
            <div class="card-panel-text">待处置</div>
            <span class="card-panel-num">42</span>
          </div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="12" :lg="6" class="card-panel-col">
        <div class="card-panel">
          <div class="card-panel-icon-wrapper icon-warning">
            <i class="el-icon-warning-outline card-panel-icon" />
          </div>
          <div class="card-panel-description">
            <div class="card-panel-text">误报率</div>
            <span class="card-panel-num">3.5%</span>
          </div>
        </div>
      </el-col>
      <el-col :xs="12" :sm="12" :lg="6" class="card-panel-col">
        <div class="card-panel">
          <div class="card-panel-icon-wrapper icon-success">
            <i class="el-icon-finished card-panel-icon" />
          </div>
          <div class="card-panel-description">
            <div class="card-panel-text">处置效率</div>
            <span class="card-panel-num">98%</span>
          </div>
        </div>
      </el-col>
    </el-row>

    <!-- 图表区域 -->
    <el-row :gutter="20" style="margin-bottom: 20px;">
      <el-col :span="16">
        <el-card>
          <div slot="header"><span>告警趋势</span></div>
          <div id="trendChart" style="height: 300px;"></div>
        </el-card>
      </el-col>
      <el-col :span="8">
        <el-card>
          <div slot="header"><span>告警分布</span></div>
          <div id="pieChart" style="height: 300px;"></div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 告警列表 -->
    <el-card>
      <div slot="header" class="clearfix">
        <span>实时告警流</span>
        <div style="float: right;">
          <el-select v-model="filterType" placeholder="告警类型" size="small" style="width: 120px; margin-right: 10px;">
            <el-option label="全部" value="" />
            <el-option label="聚集检测" value="gathering" />
            <el-option label="烟火检测" value="fire" />
            <el-option label="徘徊检测" value="loitering" />
            <el-option label="打电话" value="phone" />
          </el-select>
          <el-select v-model="filterLevel" placeholder="级别" size="small" style="width: 100px; margin-right: 10px;">
            <el-option label="全部" value="" />
            <el-option label="高" value="high" />
            <el-option label="中" value="medium" />
            <el-option label="低" value="low" />
          </el-select>
        </div>
      </div>
      
      <el-table :data="tableData" style="width: 100%" v-loading="loading">
        <el-table-column label="快照" width="120">
          <template slot-scope="scope">
            <el-image 
              style="width: 100px; height: 60px"
              :src="scope.row.snapshot" 
              :preview-src-list="[scope.row.snapshot]">
            </el-image>
          </template>
        </el-table-column>
        <el-table-column prop="time" label="时间" width="160" />
        <el-table-column prop="device" label="设备/区域" />
        <el-table-column prop="type" label="告警类型" width="120">
          <template slot-scope="scope">
            <el-tag :type="getAlertTag(scope.row.type)">{{ scope.row.typeName }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="level" label="级别" width="100">
           <template slot-scope="scope">
             <span :style="{color: scope.row.level === '高' ? 'red' : (scope.row.level === '中' ? 'orange' : 'gray')}">
               {{ scope.row.level }}
             </span>
           </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template slot-scope="scope">
            <el-tag :type="scope.row.status === '待处置' ? 'danger' : 'success'" size="mini">
              {{ scope.row.status }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="200">
          <template slot-scope="scope">
            <el-button size="mini" type="primary" @click="handleDispose(scope.row)" v-if="scope.row.status === '待处置'">处置</el-button>
            <el-button size="mini" @click="viewDetail(scope.row)">详情</el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 处置弹窗 -->
    <el-dialog title="告警处置" :visible.sync="dialogVisible" width="500px">
      <el-form :model="disposeForm" label-width="80px">
        <el-form-item label="处置动作">
          <el-radio-group v-model="disposeForm.action">
            <el-radio label="confirm">确认告警</el-radio>
            <el-radio label="false">误报归档</el-radio>
            <el-radio label="assign">指派工单</el-radio>
          </el-radio-group>
        </el-form-item>
        <el-form-item label="备注信息">
          <el-input type="textarea" v-model="disposeForm.remark" rows="3"></el-input>
        </el-form-item>
        <el-form-item label="联动推送">
          <el-checkbox-group v-model="disposeForm.push">
            <el-checkbox label="sms">短信通知</el-checkbox>
            <el-checkbox label="app">APP推送</el-checkbox>
          </el-checkbox-group>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="dialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="submitDispose">确 定</el-button>
      </span>
    </el-dialog>

    <el-dialog title="告警详情" :visible.sync="detailVisible" width="60%">
      <div v-if="detailData">
        <el-row :gutter="20">
          <el-col :span="12">
            <el-descriptions :column="1" border>
              <el-descriptions-item label="告警时间">{{ detailData.time }}</el-descriptions-item>
              <el-descriptions-item label="告警类型">
                 <el-tag :type="detailData.type === 'gathering' ? 'danger' : 'warning'">{{ detailData.typeName }}</el-tag>
              </el-descriptions-item>
              <el-descriptions-item label="设备/区域">{{ detailData.device }}</el-descriptions-item>
              <el-descriptions-item label="置信度">{{ detailData.level }}</el-descriptions-item>
            </el-descriptions>
            <div style="margin-top: 20px;">
              <h4>告警快照</h4>
              <el-image :src="detailData.snapshot" :preview-src-list="[detailData.snapshot]" style="width: 100%; border-radius: 4px;"></el-image>
            </div>
          </el-col>
          <el-col :span="12">
             <h4>告警录像</h4>
             <div v-if="detailData.videoUrl" style="width: 100%; height: 300px; background: #000; display: flex; align-items: center; justify-content: center;">
               <video :src="detailData.videoUrl" controls style="width: 100%; max-height: 100%;"></video>
             </div>
             <div v-else style="width: 100%; height: 300px; background: var(--background-color-base, #f5f7fa); display: flex; align-items: center; justify-content: center; color: #909399;">
               暂无录像
             </div>
          </el-col>
        </el-row>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import echarts from 'echarts'
import request from '@/utils/request'

export default {
  data() {
    return {
      filterType: '',
      filterLevel: '',
      loading: false,
      detailVisible: false,
      detailData: null,
      dialogVisible: false,
      disposeForm: {
        action: 'confirm',
        remark: '',
        push: ['app']
      },
      tableData: []
    }
  },
  mounted() {
    this.initCharts()
    this.fetchAlerts()
    window.addEventListener('resize', this.handleResize)
  },
  beforeDestroy() {
    window.removeEventListener('resize', this.handleResize)
  },
  methods: {
    fetchAlerts() {
      this.loading = true
      request({
        url: '/api/ext/ai/alerts',
        method: 'get'
      }).then(res => {
        // 兼容处理：有些 request 封装会直接返回 data，有些返回完整 response
        // 如果 res 是数组，说明拦截器已经处理过
        // 如果 res.data 是数组，说明需要取 res.data
        const list = Array.isArray(res) ? res : (res.data && Array.isArray(res.data) ? res.data : [])
        
        console.log('AI Alerts API Response:', res)
        console.log('Parsed List:', list)

        this.tableData = list.map(item => {
            // 根据告警类型映射 type code (用于显示颜色)
            let typeCode = 'gathering'
            if (item.type.includes('烟火')) typeCode = 'fire'
            else if (item.type.includes('徘徊')) typeCode = 'loitering'
            else if (item.type.includes('打电话')) typeCode = 'phone'
            
            return {
                id: item.id,
                snapshot: item.snapshotUrl, // 确保后端返回的是 /demo/xxx.jpg
                time: item.time,
                device: item.deviceId,
                type: typeCode,
                typeName: item.type,
                level: item.confidence > 0.9 ? '高' : (item.confidence > 0.6 ? '中' : '低'),
                videoUrl: item.videoUrl, // 新增视频字段
                status: '待处置' // 默认状态
            }
        })
        this.loading = false
      }).catch(err => {
        console.error('Fetch Alerts Error:', err)
        this.loading = false
      })
    },
    initCharts() {
      // Trend Chart
      const trendChart = echarts.init(document.getElementById('trendChart'))
      trendChart.setOption({
        tooltip: { trigger: 'axis' },
        xAxis: { type: 'category', data: ['08:00', '09:00', '10:00', '11:00', '12:00', '13:00'] },
        yAxis: { type: 'value' },
        series: [{
          data: [5, 12, 25, 18, 10, 8],
          type: 'line',
          smooth: true,
          areaStyle: {}
        }]
      })
      this.trendChart = trendChart

      // Pie Chart
      const pieChart = echarts.init(document.getElementById('pieChart'))
      pieChart.setOption({
        tooltip: { trigger: 'item' },
        series: [{
          type: 'pie',
          radius: ['40%', '70%'],
          data: [
            { value: 45, name: '聚集检测' },
            { value: 30, name: '烟火检测' },
            { value: 15, name: '徘徊检测' },
            { value: 10, name: '打电话' }
          ]
        }]
      })
      this.pieChart = pieChart
    },
    handleResize() {
      this.trendChart && this.trendChart.resize()
      this.pieChart && this.pieChart.resize()
    },
    getAlertTag(type) {
      const map = {
        gathering: 'danger',
        fire: 'danger',
        loitering: 'warning',
        phone: 'info'
      }
      return map[type] || ''
    },
    handleDispose(row) {
      this.dialogVisible = true
      this.disposeForm.remark = ''
    },
    submitDispose() {
      this.$message.success('处置提交成功，已推送至移动端')
      this.dialogVisible = false
    },
    viewDetail(row) {
      this.detailData = row
      this.detailVisible = true
    }
  }
}
</script>

<style lang="scss" scoped>
.panel-group {
  margin-top: 18px;
  .card-panel-col {
    margin-bottom: 32px;
  }
  .card-panel {
    height: 108px;
    cursor: pointer;
    font-size: 12px;
    position: relative;
    overflow: hidden;
    color: #666;
    background: var(--container-bg);
    box-shadow: 4px 4px 40px rgba(0, 0, 0, .05);
    border-color: rgba(0, 0, 0, .05);
    display: flex;
    align-items: center;
    
    .card-panel-icon-wrapper {
      float: left;
      margin: 14px 0 0 14px;
      padding: 16px;
      transition: all 0.38s ease-out;
      border-radius: 6px;
    }
    .card-panel-icon {
      float: left;
      font-size: 48px;
    }
    .card-panel-description {
      float: right;
      font-weight: bold;
      margin: 26px;
      margin-left: 0px;
      .card-panel-text {
        line-height: 18px;
        color: rgba(0, 0, 0, 0.45);
        font-size: 16px;
        margin-bottom: 12px;
      }
      .card-panel-num {
        font-size: 20px;
        color: var(--text-color-primary);
      }
    }
    .icon-message { color: #006838; }
    .icon-time { color: #f4516c; }
    .icon-warning { color: #ffb980; }
    .icon-success { color: #34bfa3; }
  }
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

::v-deep .el-descriptions {
  background-color: transparent;
  color: var(--text-color-primary);
}
::v-deep .el-descriptions__body {
  background-color: transparent;
  color: var(--text-color-primary);
}
::v-deep .el-descriptions-item__label.is-bordered-label {
  background-color: var(--background-color-base, #fafafa);
  color: var(--text-color-regular);
  border-color: var(--border-color-base);
}
::v-deep .el-descriptions-item__content {
  color: var(--text-color-primary);
  border-color: var(--border-color-base);
}

::v-deep .el-table {
  background-color: transparent;
  color: var(--text-color-regular);
  
  th, tr {
    background-color: transparent;
  }
  
  thead th {
    background-color: var(--background-color-base);
    color: var(--text-color-primary);
    border-bottom-color: var(--border-color-base);
  }

  .el-table__body tr {
    background-color: transparent !important;
  }
  
  .el-table__body td {
    background-color: transparent !important;
  }
  
  td, th.is-leaf {
    border-bottom-color: var(--border-color-base);
  }
}
</style>
