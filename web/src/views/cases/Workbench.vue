<template>
  <div class="app-container">
    <div class="filter-container" style="margin-bottom: 20px;">
      <el-input v-model="listQuery.keyword" placeholder="案事件名称 / 编号" style="width: 200px;" class="filter-item" @keyup.enter.native="handleFilter" />
      <el-select v-model="listQuery.status" placeholder="状态" clearable style="width: 120px; margin-left: 10px;" class="filter-item">
        <el-option v-for="(item, key) in statusMap" :key="key" :label="item.label" :value="key" />
      </el-select>
      <el-button class="filter-item" type="primary" icon="el-icon-search" style="margin-left: 10px;" @click="handleFilter">
        搜索
      </el-button>
      <el-button class="filter-item" style="margin-left: 10px;" type="primary" icon="el-icon-plus" @click="handleAdd">
        新增案事件
      </el-button>
    </div>

    <el-table
      v-loading="listLoading"
      :data="list"
      fit
      highlight-current-row
      style="width: 100%; border-radius: 4px;"
    >
      <el-table-column label="ID" prop="id" sortable="custom" align="center" width="80">
        <template slot-scope="{row}">
          <span>{{ row.id }}</span>
        </template>
      </el-table-column>
      <el-table-column label="案事件名称" min-width="150px">
        <template slot-scope="{row}">
          <span class="link-type" @click="handleEdit(row)">{{ row.name }}</span>
          <el-tag size="mini" type="danger" v-if="row.priority === 'high'" style="margin-left: 5px;">紧急</el-tag>
        </template>
      </el-table-column>
      <el-table-column label="涉事对象" width="120px" align="center">
        <template slot-scope="{row}">
          <span>{{ row.subject || '张三' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="案发地点" width="180px">
        <template slot-scope="{row}">
          <span>{{ row.location || '东门广场' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="时间" width="160px" align="center">
        <template slot-scope="{row}">
          <span>{{ row.time || '2023-10-27 10:00' }}</span>
        </template>
      </el-table-column>
      <el-table-column label="类型" width="110px" align="center">
        <template slot-scope="{row}">
          <span>{{ row.type }}</span>
        </template>
      </el-table-column>
      <el-table-column label="状态" class-name="status-col" width="100">
        <template slot-scope="{row}">
          <el-tag :type="statusMap[row.status] ? statusMap[row.status].type : 'info'">
            {{ statusMap[row.status] ? statusMap[row.status].label : '未知' }}
          </el-tag>
        </template>
      </el-table-column>
      <el-table-column label="操作" align="center" width="230" class-name="small-padding fixed-width">
        <template slot-scope="{row}">
          <el-button type="success" size="mini" @click="handleEdit(row)">
            处理
          </el-button>
          <el-button v-if="row.status!='4'" size="mini" type="warning" @click="handleStatus(row, '4')">
            归档
          </el-button>
          <el-button v-if="row.status!='deleted'" size="mini" type="danger" @click="handleDelete(row)">
            删除
          </el-button>
        </template>
      </el-table-column>
    </el-table>

    <div class="pagination-container" style="margin-top: 20px; text-align: right;">
       <el-pagination
        :current-page="listQuery.page"
        :page-sizes="[10, 20, 30, 50]"
        :page-size="listQuery.limit"
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        background
      />
    </div>

    <!-- 流程处理弹窗 -->
    <el-dialog :title="dialogStatus === 'create' ? '新增案事件' : '案事件处置'" :visible.sync="dialogFormVisible" width="800px">
      <div style="margin-bottom: 30px;" v-if="dialogStatus === 'update'">
         <el-steps :active="activeStep" finish-status="success" align-center>
          <el-step title="受理"></el-step>
          <el-step title="研判"></el-step>
          <el-step title="处置"></el-step>
          <el-step title="归档"></el-step>
        </el-steps>
      </div>

      <el-form ref="dataForm" :model="temp" label-position="left" label-width="100px" style="width: 600px; margin-left:50px;">
        <el-form-item label="案事件名称" prop="name">
          <el-input v-model="temp.name" />
        </el-form-item>
        <el-form-item label="类型" prop="type">
          <el-select v-model="temp.type" class="filter-item" placeholder="请选择">
            <el-option label="非法运输" value="transport" />
            <el-option label="无证经营" value="unlicensed" />
            <el-option label="售假" value="fake" />
            <el-option label="走私" value="smuggling" />
          </el-select>
        </el-form-item>
        <el-form-item label="涉事对象" prop="subject">
           <el-input v-model="temp.subject" />
        </el-form-item>
        <el-form-item label="案发地点" prop="location">
           <el-input v-model="temp.location" />
        </el-form-item>
        <el-form-item label="紧急程度" prop="priority">
          <el-rate v-model="temp.priorityVal" :max="3" :texts="['低', '中', '高']" show-text></el-rate>
        </el-form-item>
        <el-form-item label="描述" prop="description">
          <el-input v-model="temp.description" type="textarea" :rows="3" />
        </el-form-item>
        <el-form-item label="关联证据" v-if="dialogStatus === 'update'">
          <div style="display: flex; gap: 10px; flex-wrap: wrap;">
             <div v-for="(ev, index) in temp.evidence" :key="index" class="evidence-item">
               <video v-if="ev.type === 'video'" :src="ev.url" controls style="width: 200px; height: 150px; background: #000; border-radius: 4px;"></video>
               <el-image v-else style="width: 200px; height: 150px; border-radius: 4px;" :src="ev.url" fit="cover" :preview-src-list="[ev.url]"></el-image>
               <div style="font-size: 12px; color: #666; margin-top: 5px; text-align: center;">{{ ev.name }}</div>
             </div>
          </div>
        </el-form-item>
      </el-form>
      <div slot="footer" class="dialog-footer">
        <el-button type="warning" plain @click="handleLog" v-if="dialogStatus === 'update'" style="float: left;">
          <i class="el-icon-document"></i> 执法操作日志
        </el-button>
        <el-button @click="dialogFormVisible = false">
          取消
        </el-button>
        <el-button type="primary" @click="dialogStatus==='create'?createData():updateData()">
          确认
        </el-button>
      </div>
    </el-dialog>

    <law-log-dialog ref="logDialog" />
  </div>
</template>

<script>
import request from '@/utils/request'
import LawLogDialog from './LawLogDialog'

export default {
  components: { LawLogDialog },
  data() {
    return {
      list: [],
      total: 0,
      listLoading: true,
      listQuery: {
        page: 1,
        limit: 20,
        keyword: '',
        status: undefined
      },
      statusMap: {
        1: { label: '受理', type: 'success' },
        2: { label: '研判', type: 'warning' },
        3: { label: '处置', type: 'danger' },
        4: { label: '归档', type: 'info' }
      },
      dialogFormVisible: false,
      dialogStatus: '',
      activeStep: 0,
      temp: {
        id: undefined,
        name: '',
        type: '',
        status: 1,
        priority: 'low',
        priorityVal: 1,
        subject: '',
        location: '',
        description: '',
        evidence: []
      },
      mockCaseList: [
        {
          id: 1001,
          name: '非法运输卷烟案-车牌号京A88888',
          type: '非法运输',
          status: 1,
          priority: 'high',
          priorityVal: 3,
          subject: '王某某',
          location: '高速收费站出口',
          time: '2023-10-27 09:30:00',
          description: '拦截一辆疑似运输假冒伪劣卷烟的厢式货车，现场查获违规卷烟 50 箱。',
          evidence: [
            { type: 'video', url: '/static/video/suspect-red-hat-1.mp4', name: '执法记录仪-拦截现场' }
          ]
        },
        {
          id: 1002,
          name: '无证经营烟草制品案-便民超市',
          type: '无证经营',
          status: 2,
          priority: 'medium',
          priorityVal: 2,
          subject: '李某',
          location: '幸福路12号',
          time: '2023-10-26 14:15:00',
          description: '接到群众举报，对某超市进行突击检查，发现其未持有烟草专卖零售许可证销售卷烟。',
          evidence: [
            { type: 'video', url: '/static/video/suspect-red-hat-2.mp4', name: '执法记录仪-店内取证' }
          ]
        },
        {
          id: 1003,
          name: '销售假冒注册商标卷烟案',
          type: '售假',
          status: 3,
          priority: 'low',
          priorityVal: 1,
          subject: '张三',
          location: '中心市场批发部',
          time: '2023-10-25 10:00:00',
          description: '例行巡查发现某批发部存在销售假烟嫌疑。',
          evidence: []
        }
      ]
    }
  },
  created() {
    this.fetchData();
  },
  methods: {
    fetchData() {
      this.listLoading = true;
      // Simulate API call with mock data
      setTimeout(() => {
        this.list = this.mockCaseList.filter(item => {
           if (this.listQuery.keyword && !item.name.includes(this.listQuery.keyword)) return false;
           if (this.listQuery.status && item.status != this.listQuery.status) return false;
           return true;
        });
        this.total = this.list.length;
        this.listLoading = false;
      }, 500);
    },
    handleFilter() {
      this.listQuery.page = 1;
      this.fetchData();
    },
    handleAdd() {
      this.resetTemp();
      this.dialogStatus = 'create';
      this.dialogFormVisible = true;
      this.activeStep = 0;
    },
    handleEdit(row) {
      this.temp = Object.assign({}, row);
      this.activeStep = row.status - 1;
      this.dialogStatus = 'update';
      this.dialogFormVisible = true;
    },
    resetTemp() {
      this.temp = {
        id: undefined,
        name: '',
        type: '',
        status: 1,
        priority: 'low',
        priorityVal: 1,
        subject: '',
        location: '',
        description: '',
        evidence: []
      };
    },
    createData() {
      this.$message.success('创建成功');
      this.temp.id = parseInt(Math.random() * 100) + 1024;
      this.temp.time = new Date().toLocaleString();
      this.mockCaseList.unshift(this.temp);
      this.fetchData();
      this.dialogFormVisible = false;
    },
    updateData() {
      const index = this.mockCaseList.findIndex(v => v.id === this.temp.id);
      this.mockCaseList.splice(index, 1, this.temp);
      this.fetchData();
      this.dialogFormVisible = false;
      this.$message.success('更新成功');
    },
    handleStatus(row, status) {
      this.$message.success('状态更新成功');
      row.status = status;
    },
    handleLog() {
      this.$refs.logDialog.open(this.temp.id);
    },
    handleDelete(row) {
      this.$confirm('确认删除?', '提示', { type: 'warning' }).then(() => {
        const index = this.list.indexOf(row);
        this.list.splice(index, 1);
        this.$message.success('删除成功');
      })
    }
  }
}
</script>

<style scoped>
.link-type {
  color: var(--text-color-primary);
  cursor: pointer;
}
.link-type:hover {
  color: #20a0ff;
  text-decoration: underline;
}
</style>
