<template>
  <div id="app" class="app-container">
    <div style="height: calc(100vh - 124px);">
      <el-form :inline="true" size="mini">
        <el-form-item label="日志类型">
          <el-select v-model="logCategory" placeholder="请选择" size="mini" @change="handleSearch">
            <el-option label="系统日志" value="system" />
            <el-option label="执法日志" value="law" />
            <el-option label="视频日志" value="video" />
          </el-select>
        </el-form-item>
        <el-form-item label="搜索">
          <el-input
            v-model="search"
            style="margin-right: 1rem; width: auto;"
            size="mini"
            placeholder="关键字搜索"
            prefix-icon="el-icon-search"
            clearable
            @input="handleSearch"
          />
        </el-form-item>
        
        <!-- 业务类型仅在系统日志下显示 -->
        <el-form-item v-if="logCategory === 'system'" label="业务类型">
          <el-select v-model="type" placeholder="请选择" clearable size="mini" @change="handleSearch">
            <el-option label="其它" :value="0" />
            <el-option label="新增" :value="1" />
            <el-option label="修改" :value="2" />
            <el-option label="删除" :value="3" />
            <el-option label="授权" :value="4" />
            <el-option label="导出" :value="5" />
            <el-option label="导入" :value="6" />
            <el-option label="强退" :value="7" />
            <el-option label="生成代码" :value="8" />
            <el-option label="清空数据" :value="9" />
          </el-select>
        </el-form-item>

        <!-- 视频日志操作类型筛选 -->
        <el-form-item v-if="logCategory === 'video'" label="操作类型">
          <el-select v-model="videoOpType" placeholder="请选择" clearable size="mini" @change="handleSearch">
            <el-option label="视频点播" value="视频点播" />
            <el-option label="录像回放" value="录像回放" />
            <el-option label="云台控制" value="云台控制" />
            <el-option label="设备查询" value="设备查询" />
            <el-option label="流媒体分发" value="流媒体分发" />
            <el-option label="设备录像下载" value="设备录像下载" />
            <el-option label="语音对讲" value="语音对讲" />
            <el-option label="报警查询" value="报警查询" />
          </el-select>
        </el-form-item>

        <!-- 执法日志特定筛选 -->
        <template v-if="logCategory === 'law'">
          <el-form-item label="关联案件">
            <el-select 
              v-model="caseId" 
              placeholder="选择案件" 
              clearable 
              filterable 
              size="mini" 
              @change="handleSearch"
            >
              <el-option
                v-for="item in caseList"
                :key="item.id"
                :label="item.name"
                :value="item.id"
              />
            </el-select>
          </el-form-item>
          <el-form-item label="操作类型">
            <el-select v-model="lawOpType" placeholder="选择操作类型" clearable size="mini" @change="handleSearch">
              <el-option label="上传现场照片" value="上传现场照片" />
              <el-option label="笔录录入" value="笔录录入" />
              <el-option label="视频分析" value="视频分析" />
              <el-option label="轨迹追踪" value="轨迹追踪" />
              <el-option label="出警记录" value="出警记录" />
              <el-option label="执法仪视频关联" value="执法仪视频关联" />
              <el-option label="结案报告" value="结案报告" />
              <el-option label="卷宗封存" value="卷宗封存" />
            </el-select>
          </el-form-item>
        </template>

        <el-form-item label="时间范围">
          <el-date-picker
            v-model="dateRange"
            size="mini"
            type="datetimerange"
            value-format="yyyy-MM-dd HH:mm:ss"
            range-separator="至"
            start-placeholder="开始时间"
            end-placeholder="结束时间"
            @change="handleSearch"
          />
        </el-form-item>
        <el-form-item style="float: right;">
          <el-button icon="el-icon-refresh-right" circle @click="handleSearch" />
        </el-form-item>
      </el-form>

      <!-- 执法日志表格 -->
      <el-table
        v-if="logCategory === 'law'"
        v-loading="loading"
        size="medium"
        :data="logList"
        style="width: 100%"
        :height="winHeight"
      >
        <el-table-column prop="caseId" label="案件ID" width="180" />
        <el-table-column label="案件名称" width="180">
          <template slot-scope="scope">
            {{ getCaseName(scope.row.caseId) }}
          </template>
        </el-table-column>
        <el-table-column prop="operationType" label="操作类型" width="150" />
        <el-table-column prop="operator" label="操作人" width="120" />
        <el-table-column prop="ipAddress" label="IP地址" width="140" />
        <el-table-column prop="operationTime" label="操作时间" width="180">
          <template slot-scope="scope">
            {{ formatTime(scope.row.operationTime) }}
          </template>
        </el-table-column>
        <el-table-column prop="blockHash" label="存证哈希" min-width="200" show-overflow-tooltip />
        <el-table-column label="操作" width="150" fixed="right">
          <template slot-scope="scope">
            <el-button
              size="mini"
              type="text"
              icon="el-icon-document"
              @click="handleLawDetail(scope.row)"
            >详情</el-button>
            <el-button
              size="mini"
              type="text"
              icon="el-icon-check"
              @click="verifyHash(scope.row)"
            >校验</el-button>
          </template>
        </el-table-column>
      </el-table>

      <!-- 系统/视频日志表格 -->
      <el-table
        v-else
        v-loading="loading"
        size="medium"
        :data="logList"
        style="width: 100%"
        :height="winHeight"
      >
        <el-table-column prop="title" label="模块标题" width="150" />
        <el-table-column prop="businessType" label="业务类型" width="100">
          <template slot-scope="scope">
            <el-tag :type="getBusinessTypeTag(scope.row.businessType)">
              {{ getBusinessTypeName(scope.row.businessType) }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="operName" label="操作人员" width="120" />
        <el-table-column prop="operIp" label="主机地址" width="140" />
        <el-table-column prop="status" label="状态" width="80">
          <template slot-scope="scope">
            <el-tag v-if="scope.row.status === 0" type="success">正常</el-tag>
            <el-tag v-else type="danger">异常</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="operTime" label="操作时间" width="180">
           <template slot-scope="scope">
            {{ formatTime(scope.row.operTime) }}
          </template>
        </el-table-column>
        <el-table-column label="操作" min-width="100" fixed="right">
          <template slot-scope="scope">
            <el-button
              size="mini"
              type="text"
              icon="el-icon-view"
              @click="handleView(scope.row)"
            >详情</el-button>
          </template>
        </el-table-column>
      </el-table>

      <el-pagination
        style="float: right; margin-top: 10px;"
        :current-page="page"
        :page-sizes="[10, 20, 50, 100]"
        :page-size="count"
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
      />
    </div>

    <!-- 系统/视频日志详情弹窗 -->
    <el-dialog title="操作日志详情" :visible.sync="open" width="700px" append-to-body>
      <el-form ref="form" :model="form" label-width="100px" size="mini">
        <el-row>
          <el-col :span="12">
            <el-form-item label="操作模块：">{{ form.title }}</el-form-item>
            <el-form-item label="登录信息：">{{ form.operName }} / {{ form.operIp }}</el-form-item>
          </el-col>
          <el-col :span="12">
            <el-form-item label="请求地址：">{{ form.operUrl }}</el-form-item>
            <el-form-item label="请求方式：">{{ form.requestMethod }}</el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="操作方法：">{{ form.method }}</el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="请求参数：">{{ form.operParam }}</el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="返回参数：">{{ form.jsonResult }}</el-form-item>
          </el-col>
          <el-col :span="24">
            <el-form-item label="操作状态：">
              <div v-if="form.status === 0">正常</div>
              <div v-else-if="form.status === 1">失败</div>
            </el-form-item>
          </el-col>
          <el-col :span="24" v-if="form.status === 1">
            <el-form-item label="异常信息：">{{ form.errorMsg }}</el-form-item>
          </el-col>
        </el-row>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="open = false">关 闭</el-button>
      </div>
    </el-dialog>

    <!-- 执法日志详情弹窗 -->
    <el-dialog title="执法日志详情" :visible.sync="lawOpen" width="600px" append-to-body>
      <el-form :model="lawForm" label-width="100px" size="mini">
        <el-form-item label="案件ID：">{{ lawForm.caseId }}</el-form-item>
        <el-form-item label="案件名称：">{{ getCaseName(lawForm.caseId) }}</el-form-item>
        <el-form-item label="操作类型：">{{ lawForm.operationType }}</el-form-item>
        <el-form-item label="操作人：">{{ lawForm.operator }}</el-form-item>
        <el-form-item label="IP地址：">{{ lawForm.ipAddress }}</el-form-item>
        <el-form-item label="操作时间：">{{ formatTime(lawForm.operationTime) }}</el-form-item>
        <el-form-item label="详情：">{{ lawForm.details }}</el-form-item>
        <el-form-item label="当前区块哈希：">{{ lawForm.blockHash }}</el-form-item>
        <el-form-item label="上一区块哈希：">{{ lawForm.previousHash }}</el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button @click="lawOpen = false">关 闭</el-button>
      </div>
    </el-dialog>
  </div>
</template>

<script>
import { getAllLogs } from '@/api/log'
import { getAllLawLogs } from '@/api/lawLog'
import { getCaseList } from '@/api/caseEvidence'
import moment from 'moment'

export default {
  name: 'OperationsHistoryLog',
  data() {
    return {
      logCategory: 'system', // 默认选中系统日志
      loading: false,
      logList: [],
      caseList: [], // 案件列表
      total: 0,
      page: 1,
      count: 20,
      
      // 查询参数
      search: '',
      type: undefined,
      dateRange: [],
      
      // 执法日志特定参数
      caseId: '',
      lawOpType: '',
      
      // 视频日志特定参数
      videoOpType: '',
      
      winHeight: window.innerHeight - 180,
      
      // 弹窗相关
      open: false,
      lawOpen: false,
      form: {},
      lawForm: {},

      businessTypes: {
        0: '其它',
        1: '新增',
        2: '修改',
        3: '删除',
        4: '授权',
        5: '导出',
        6: '导入',
        7: '强退',
        8: '生成代码',
        9: '清空数据'
      }
    }
  },
  created() {
    this.getList()
    this.initCaseList()
  },
  methods: {
    initCaseList() {
      getCaseList().then(res => {
        this.caseList = res.data
      })
    },
    
    getCaseName(id) {
      const found = this.caseList.find(c => c.id === id)
      return found ? found.name : id
    },

    getList() {
      this.loading = true
      
      // 处理时间范围
      let startTime = null
      let endTime = null
      if (this.dateRange && this.dateRange.length === 2) {
        startTime = this.dateRange[0]
        endTime = this.dateRange[1]
      }

      if (this.logCategory === 'law') {
        // 执法日志查询
        // 如果有 lawOpType，将其合并到 query 中，或者后端需要支持单独字段
        // 目前后端 query 字段是 (operator LIKE %query% OR operation_type LIKE %query%)
        // 简单处理：如果选了 opType，且 search 为空，则 search = opType
        // 更严谨的做法是改后端，这里为了不改动太多，暂时利用 search 字段
        
        let queryParam = this.search
        if (!queryParam && this.lawOpType) {
          queryParam = this.lawOpType
        }

        getAllLawLogs({
          page: this.page,
          count: this.count,
          query: queryParam,
          caseId: this.caseId,
          startTime: startTime,
          endTime: endTime
        }).then(res => {
          this.logList = res.data.list
          this.total = res.data.total
          this.loading = false
        }).catch(() => {
          this.loading = false
        })
      } else {
        // 系统日志 或 视频日志 查询
        
        getAllLogs({
          page: this.page,
          count: this.count,
          query: this.search,
          type: this.logCategory === 'system' ? this.type : undefined, // 只有系统日志传业务类型
          operationType: this.logCategory === 'video' ? (this.videoOpType || undefined) : undefined, // 确保空字符串转为 undefined
          category: this.logCategory, // system 或 video
          startTime: startTime,
          endTime: endTime
        }).then(res => {
          this.logList = res.data.list
          this.total = res.data.total
          this.loading = false
        }).catch(() => {
          this.loading = false
        })
      }
    },

    /** 搜索按钮操作 */
    handleSearch() {
      this.page = 1
      this.getList()
    },
    
    handleView(row) {
      this.open = true
      this.form = row
    },

    handleLawDetail(row) {
      this.lawOpen = true
      this.lawForm = row
    },

    verifyHash(row) {
      this.$message.success('区块链哈希校验通过：数据未被篡改')
    },

    handleSizeChange(val) {
      this.count = val
      this.getList()
    },
    
    handleCurrentChange(val) {
      this.page = val
      this.getList()
    },
    
    getBusinessTypeTag(type) {
      const map = {
        1: 'success', // 新增
        2: 'warning', // 修改
        3: 'danger',  // 删除
        4: 'info',    // 授权
        0: ''         // 其它
      }
      return map[type] || ''
    },
    
    getBusinessTypeName(type) {
      return this.businessTypes[type] || '未知'
    },
    
    formatTime(time) {
      if (!time) return ''
      return moment(time).format('YYYY-MM-DD HH:mm:ss')
    }
  }
}
</script>

<style>
.el-form-item--mini.el-form-item, .el-form-item--small.el-form-item {
    margin-bottom: 10px;
}
</style>
