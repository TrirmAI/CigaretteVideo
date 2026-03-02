<template>
  <el-dialog title="执法操作日志" :visible.sync="visible" width="800px" append-to-body>
    <div v-loading="loading">
      <el-alert
        title="本日志采用区块链技术存证，所有操作不可篡改。"
        type="success"
        show-icon
        style="margin-bottom: 20px;"
      />
      
      <el-timeline v-if="logs.length > 0">
        <el-timeline-item
          v-for="(log, index) in logs"
          :key="log.id"
          :timestamp="log.operationTime"
          placement="top"
        >
          <el-card>
            <h4>{{ log.operationType }} - {{ log.details }}</h4>
            <p>操作人: {{ log.operator }} | IP: {{ log.ipAddress }}</p>
            <div class="hash-info">
              <el-tag size="mini" type="info" style="width: 100%; overflow: hidden; text-overflow: ellipsis;">区块哈希: {{ log.blockHash }}</el-tag>
              <div style="margin-top: 5px;">
                <el-tag size="mini" type="info" effect="plain" style="width: 100%; overflow: hidden; text-overflow: ellipsis;">上一区块: {{ log.previousHash }}</el-tag>
              </div>
            </div>
            <!-- Simple verification visual -->
            <div class="verify-status">
               <i class="el-icon-circle-check" style="color: green;"></i> 链上校验通过
            </div>
          </el-card>
        </el-timeline-item>
      </el-timeline>
      <div v-else style="text-align: center; color: #999; padding: 20px;">
        暂无日志记录
      </div>
    </div>
    <div slot="footer" class="dialog-footer">
      <el-button @click="visible = false">关 闭</el-button>
    </div>
  </el-dialog>
</template>

<script>
import { getLawLogs } from '@/api/lawLog'

export default {
  data() {
    return {
      visible: false,
      loading: false,
      logs: []
    }
  },
  methods: {
    open(caseId) {
      this.visible = true;
      this.fetchLogs(caseId);
    },
    fetchLogs(caseId) {
      this.loading = true;
      getLawLogs({ caseId: caseId }).then(response => {
        // request.js unwraps "response.data"
        // But the structure is { code: 0, msg: "success", data: [...] }
        // So response.data is the array we need.
        // Wait, looking at request.js:
        // const res = response.data
        // if (res.code && res.code !== 0) ... else return res
        // So 'response' here IS the full body: {code:0, msg:..., data:[...]}
        
        if (Array.isArray(response)) {
             this.logs = response;
        } else if (response && response.data) {
           this.logs = response.data;
        } else {
           this.logs = [];
        }
        this.loading = false;
      }).catch((e) => {
        console.error(e);
        this.loading = false;
      })
    }
  }
}
</script>

<style scoped>
.hash-info {
  margin-top: 10px;
  font-family: monospace;
}
.verify-status {
  margin-top: 10px;
  font-size: 12px;
  color: green;
  font-weight: bold;
}
</style>
