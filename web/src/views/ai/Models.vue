<template>
  <div class="app-container">
    <el-card>
      <div slot="header" class="clearfix">
        <span style="font-weight: bold; font-size: 16px;">AI 模型仓库</span>
        <el-button style="float: right; padding: 3px 0" type="text" icon="el-icon-plus" @click="handleUploadNew">新建模型</el-button>
      </div>
      
      <el-table :data="modelList" style="width: 100%" v-loading="loading">
         <el-table-column prop="name" label="模型名称" width="200">
           <template slot-scope="scope">
             <span style="font-weight: bold;">{{ scope.row.name }}</span>
             <el-tag size="mini" type="info" style="margin-left: 5px;">CV</el-tag>
           </template>
         </el-table-column>
         <el-table-column prop="version" label="当前版本" width="100" align="center"></el-table-column>
         <el-table-column prop="accuracy" label="准确率(mAP)" width="120" align="center">
            <template slot-scope="scope">
              <span :style="{color: parseFloat(scope.row.accuracy) > 90 ? '#67C23A' : '#E6A23C', fontWeight: 'bold'}">
                {{ scope.row.accuracy }}
              </span>
            </template>
         </el-table-column>
         <el-table-column prop="status" label="状态" width="120" align="center">
           <template slot-scope="scope">
             <el-tag :type="getStatusType(scope.row.status)" effect="dark">
               {{ getStatusLabel(scope.row.status) }}
             </el-tag>
           </template>
         </el-table-column>
         <el-table-column prop="lastUpdate" label="最后更新时间" width="160" align="center"></el-table-column>
         <el-table-column label="操作">
           <template slot-scope="scope">
             <el-button 
               size="mini" 
               type="primary" 
               icon="el-icon-refresh"
               @click="handleTrain(scope.row)"
               :disabled="scope.row.status === 'training'"
             >能力提升 / 增量训练</el-button>
             <el-button size="mini" type="info" plain @click="handleHistory(scope.row)">历史版本</el-button>
           </template>
         </el-table-column>
      </el-table>
    </el-card>

    <!-- 历史版本对话框 -->
    <el-dialog title="模型历史版本" :visible.sync="historyDialogVisible" width="900px">
      <el-table :data="historyList" v-loading="historyLoading" border stripe>
        <el-table-column prop="version" label="版本号" width="120" align="center" fixed></el-table-column>
        <el-table-column prop="createTime" label="开始时间" width="160" align="center"></el-table-column>
        <el-table-column prop="finishTime" label="完成时间" width="160" align="center"></el-table-column>
        <el-table-column prop="status" label="状态" width="100" align="center">
           <template slot-scope="scope">
             <el-tag :type="getStatusType(scope.row.status)">{{ getStatusLabel(scope.row.status) }}</el-tag>
           </template>
        </el-table-column>
        <el-table-column prop="accuracy" label="准确率" width="100" align="center">
           <template slot-scope="scope">
             <span v-if="scope.row.status === 'completed'" style="font-weight: bold; color: #67C23A">
                {{ (scope.row.accuracy * 100).toFixed(1) }}%
             </span>
             <span v-else>-</span>
           </template>
        </el-table-column>
        <el-table-column prop="loss" label="Loss" width="100" align="center">
           <template slot-scope="scope">
             <span v-if="scope.row.status === 'completed'">{{ scope.row.loss ? scope.row.loss.toFixed(4) : '-' }}</span>
             <span v-else>-</span>
           </template>
        </el-table-column>
        <el-table-column prop="filePath" label="模型文件" min-width="200" show-overflow-tooltip></el-table-column>
      </el-table>
      <span slot="footer" class="dialog-footer">
        <el-button @click="historyDialogVisible = false">关 闭</el-button>
        <el-button type="primary" icon="el-icon-refresh" @click="refreshHistory">刷 新</el-button>
      </span>
    </el-dialog>

    <!-- 新建模型对话框 -->
    <el-dialog title="新建 AI 模型" :visible.sync="createDialogVisible" width="500px">
      <el-form :model="createForm" label-width="100px">
        <el-form-item label="模型名称">
          <el-input v-model="createForm.name" placeholder="请输入模型名称"></el-input>
        </el-form-item>
        <el-form-item label="初始版本">
          <el-input v-model="createForm.version" placeholder="默认为 v1.0"></el-input>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="createDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="submitCreateModel">确 定</el-button>
      </span>
    </el-dialog>
  </div>
</template>

<script>
import * as aiModelsApi from '@/api/aiModels'

export default {
  data() {
    return {
      loading: false,
      modelList: [],
      historyDialogVisible: false,
      historyList: [],
      historyLoading: false,
      currentHistoryModelId: null,
      dialogVisible: false,
      isTraining: false,
      trainForm: {
        name: '',
        description: '',
        epochs: 50
      },
      createDialogVisible: false,
      createForm: {
        name: '',
        version: 'v1.0'
      },
      fileList: [],
      activeStep: 0,
      progress: 0,
      logs: [],
      timer: null,
      currentRow: null
    }
  },
  created() {
    this.fetchModels();
  },
  methods: {
    fetchModels() {
      this.loading = true;
      aiModelsApi.getModels().then(res => {
        this.modelList = res;
        this.loading = false;
      }).catch(() => {
        this.loading = false;
      });
    },
    getStatusType(status) {
      if (status === 'ready' || status === 'completed') return 'success';
      if (status === 'training') return 'primary';
      if (status === 'failed') return 'danger';
      return 'info';
    },
    getStatusLabel(status) {
      const map = {
        'ready': '就绪',
        'training': '训练中',
        'completed': '已完成',
        'failed': '失败'
      };
      return map[status] || status;
    },
    handleTrain(row) {
      this.trainForm.name = row.name;
      this.trainForm.description = '';
      this.fileList = [];
      this.isTraining = false;
      this.activeStep = 0;
      this.progress = 0;
      this.logs = [];
      this.dialogVisible = true;
      this.currentRow = row;
    },
    handleFileChange(file, fileList) {
      this.fileList = fileList;
    },
    handleUploadNew() {
      this.createForm = { name: '', version: 'v1.0' };
      this.createDialogVisible = true;
    },
    submitCreateModel() {
      if (!this.createForm.name) {
        this.$message.warning('请输入模型名称');
        return;
      }
      aiModelsApi.createModel(this.createForm).then(() => {
        this.$message.success('创建成功');
        this.createDialogVisible = false;
        this.fetchModels();
      });
    },
    handleHistory(row) {
      this.currentHistoryModelId = row.id;
      this.historyDialogVisible = true;
      this.refreshHistory();
    },
    refreshHistory() {
      if (!this.currentHistoryModelId) return;
      this.historyLoading = true;
      aiModelsApi.getModelHistory(this.currentHistoryModelId).then(res => {
        this.historyList = res;
        this.historyLoading = false;
      }).catch(() => {
        this.historyLoading = false;
      });
    },
    startTraining() {
      if (this.fileList.length === 0) {
        this.$message.warning('请至少上传一个样本文件');
        return;
      }
      
      this.isTraining = true;
      this.logs.push(`[System] 正在提交训练任务: ${this.trainForm.name}`);
      
      aiModelsApi.trainModel(this.trainForm.name).then(() => {
         this.logs.push(`[System] 任务提交成功！后台正在训练中...`);
         this.logs.push(`[System] 请在“历史版本”中查看进度。`);
         this.progress = 100;
         this.activeStep = 4;
         // Refresh main list to show "training" status
         this.fetchModels();
      }).catch(err => {
         this.logs.push(`[Error] 提交失败: ${err}`);
         this.isTraining = false;
      });
    },
    finishTraining() {
      this.dialogVisible = false;
      this.$message.success('后台训练已启动，请关注历史版本记录');
    },
    scrollToBottom() {
      this.$nextTick(() => {
        const consoleEl = this.$refs.logConsole;
        if (consoleEl) {
          consoleEl.scrollTop = consoleEl.scrollHeight;
        }
      });
    }
  }
}
</script>

<style scoped>
.log-console {
  background: #1e1e1e;
  color: #00ff00;
  font-family: 'Consolas', 'Monaco', monospace;
  padding: 15px;
  height: 250px;
  overflow-y: auto;
  border-radius: 4px;
  font-size: 12px;
  line-height: 1.5;
  box-shadow: inset 0 0 10px rgba(0,0,0,0.5);
}
.log-line {
  margin-bottom: 2px;
}
.blinking {
  animation: blink 1s infinite;
}
@keyframes blink {
  0% { opacity: 1; }
  50% { opacity: 0; }
  100% { opacity: 1; }
}
.training-process {
  padding: 10px;
}
</style>
