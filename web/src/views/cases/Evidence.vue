<template>
  <div class="app-container">
    <el-row :gutter="20">
      <!-- 左侧：案事件列表 -->
      <el-col :span="6">
        <el-card class="box-card" style="height: calc(100vh - 120px); overflow-y: auto;">
          <div slot="header" class="clearfix">
            <span>案事件列表</span>
          </div>
          <el-table
            :data="caseList"
            highlight-current-row
            @current-change="handleCaseSelect"
            style="width: 100%"
            v-loading="caseListLoading">
            <el-table-column prop="name" label="案件名称"></el-table-column>
            <el-table-column prop="time" label="时间" width="100"></el-table-column>
          </el-table>
        </el-card>
      </el-col>

      <!-- 右侧：证据管理 -->
      <el-col :span="18">
        <el-card class="box-card" style="height: calc(100vh - 120px); overflow-y: auto;">
          <div slot="header" class="clearfix">
            <span>{{ currentCase ? currentCase.name + ' - 证据管理' : '请选择案事件' }}</span>
            <el-button 
              style="float: right; padding: 3px 0" 
              type="text" 
              icon="el-icon-plus" 
              @click="showAddDialog"
              :disabled="!currentCase">
              添加证据
            </el-button>
          </div>

          <div v-if="!currentCase" class="empty-block">
            <i class="el-icon-folder-opened" style="font-size: 64px; color: #E4E7ED;"></i>
            <p style="color: #909399;">请先选择案事件以查看关联证据</p>
          </div>

          <div v-else>
            <el-row :gutter="20">
              <el-col :span="8" v-for="item in evidenceList" :key="item.id" style="margin-bottom: 20px;">
                <el-card :body-style="{ padding: '0px' }">
                  <div class="video-placeholder" @click="playVideo(item)">
                    <i class="el-icon-video-play"></i>
                  </div>
                  <div style="padding: 14px;">
                    <div class="evidence-desc">
                       <span v-if="!item.editing">{{ item.description || '暂无标注' }}</span>
                       <el-input v-else v-model="item.tempDesc" size="mini"></el-input>
                    </div>
                    <div class="bottom clearfix">
                      <time class="time">{{ item.createTime }}</time>
                      <el-button type="text" class="button" @click="toggleEdit(item)">{{ item.editing ? '保存' : '标注' }}</el-button>
                      <el-button type="text" class="button" style="color: #F56C6C" @click="handleDelete(item)">删除</el-button>
                    </div>
                  </div>
                </el-card>
              </el-col>
            </el-row>
            <div v-if="evidenceList.length === 0" class="empty-block">
               <p style="color: #909399;">暂无证据，请点击右上角添加</p>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 添加证据弹窗 (复用云端录像选择) -->
    <el-dialog title="选择云端录像" :visible.sync="addDialogVisible" width="80%">
        <div class="filter-container">
          <el-date-picker
            v-model="recordListQuery.timeRange"
            type="datetimerange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            value-format="yyyy-MM-dd HH:mm:ss"
            style="width: 380px;"
            class="filter-item"
            :default-time="['00:00:00', '23:59:59']"
          />
          <el-input placeholder="流ID(设备ID)" v-model="recordListQuery.stream" style="width: 200px; margin-left: 10px;" class="filter-item" />
          <el-button class="filter-item" type="primary" icon="el-icon-search" @click="getRecordList" style="margin-left: 10px;">查询</el-button>
       </div>
       <el-table 
          :data="recordList" 
          v-loading="recordListLoading" 
          border 
          style="width: 100%" 
          height="400"
          @selection-change="handleSelectionChange">
          <el-table-column type="selection" width="55"></el-table-column>
          <el-table-column label="设备ID" prop="stream" width="180"></el-table-column>
          <el-table-column label="开始时间" prop="startTime" :formatter="formatTime"></el-table-column>
          <el-table-column label="时长(秒)" prop="timeLen">
             <template slot-scope="scope">
                {{ scope.row.timeLen ? (scope.row.timeLen / 1000).toFixed(2) : '0.00' }}
             </template>
          </el-table-column>
          <el-table-column label="文件名" prop="fileName"></el-table-column>
       </el-table>
       <el-pagination
        v-show="recordTotal>0"
        :current-page="recordListQuery.page"
        :page-sizes="[10, 20, 30, 50]"
        :page-size="recordListQuery.count"
        layout="total, sizes, prev, pager, next, jumper"
        :total="recordTotal"
        @size-change="handleRecordSizeChange"
        @current-change="handleRecordCurrentChange"
        style="float: right; margin-top: 20px;"
       />
       <div slot="footer" class="dialog-footer">
        <el-button @click="addDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="confirmAddEvidence">确 定</el-button>
      </div>
    </el-dialog>
    
    <!-- 证据标注弹窗 -->
    <el-dialog title="证据标注与智能分析" :visible.sync="editDialogVisible" width="900px" append-to-body>
      <div class="evidence-edit-container">
        <el-row :gutter="20">
          <!-- 左侧：媒体预览 -->
          <el-col :span="12">
             <div class="media-preview">
                <div v-if="currentEditingItem && currentEditingItem.type === 'video'" class="video-box">
                   <!-- 如果有预览地址，优先显示视频 -->
                   <video v-if="previewUrl" :src="previewUrl" controls autoplay width="100%" height="100%" style="background: #000;"></video>
                   <div v-else>
                      <i class="el-icon-video-camera" style="font-size: 60px; color: #ccc;"></i>
                      <p style="color: #999; margin-top: 10px;">{{ currentEditingItem.name }}</p>
                      <p v-if="!previewUrl" style="font-size: 12px; color: #666;">(加载预览中...)</p>
                   </div>
                </div>
                <div v-else class="image-box">
                   <el-image :src="currentEditingItem ? currentEditingItem.url : ''" fit="contain">
                     <div slot="error" class="image-slot">
                        <i class="el-icon-picture-outline"></i>
                     </div>
                   </el-image>
                </div>
             </div>
          </el-col>
          
          <!-- 右侧：标注与AI分析 -->
          <el-col :span="12">
             <div class="section-title">手动标注</div>
             <el-input 
               type="textarea" 
               :rows="4" 
               placeholder="请输入证据描述信息..." 
               v-model="editForm.description">
             </el-input>
             
             <div class="section-title" style="margin-top: 20px; display: flex; align-items: center; justify-content: space-between;">
               <span>AI 智能分析 (多模态)</span>
               <el-button type="primary" size="small" icon="el-icon-cpu" @click="handleAnalyze" :loading="analyzing">开始分析</el-button>
             </div>
             
             <div class="ai-result-area" v-loading="analyzing" element-loading-text="正在提取物品信息...">
               <div v-if="aiTags.length === 0 && !analyzing" style="color: #999; text-align: center; padding: 20px;">
                 点击“开始分析”提取画面中的关键信息
               </div>
               <div v-else class="tag-cloud">
                 <el-tag 
                   v-for="(tag, index) in aiTags" 
                   :key="index" 
                   :type="getTagType(tag.type)"
                   effect="plain"
                   class="ai-tag"
                   @click="applyTag(tag)">
                   {{ tag.label }} <i class="el-icon-plus"></i>
                 </el-tag>
               </div>
             </div>
             
             <div class="tips" v-if="aiTags.length > 0">
               <i class="el-icon-info"></i> 点击标签可直接填入描述框
             </div>
          </el-col>
        </el-row>
      </div>
      <span slot="footer" class="dialog-footer">
        <el-button @click="editDialogVisible = false">取 消</el-button>
        <el-button type="primary" @click="saveEdit">保存标注</el-button>
      </span>
    </el-dialog>

    <playerDialog ref="playerDialog"></playerDialog>
  </div>
</template>

<script>
import { getCaseList, getEvidenceList, addEvidence, updateEvidence, deleteEvidence, analyzeEvidence } from '@/api/caseEvidence'
import { queryList as getCloudRecordList } from '@/api/cloudRecord'
import { parseTime } from '@/utils'
import playerDialog from '../cloudRecord/playerDialog'

export default {
  components: {
    playerDialog
  },
  data() {
    return {
      // Case List
      caseList: [],
      caseListLoading: false,
      currentCase: null,

      // Evidence List
      evidenceList: [],
      
      // Add Dialog
      addDialogVisible: false,
      recordList: [],
      recordTotal: 0,
      recordListLoading: false,
      recordListQuery: {
        page: 1,
        count: 10,
        app: 'live', // Default app
        stream: '',
        timeRange: []
      },
      selectedRecords: [],

      // Edit & AI Dialog
      editDialogVisible: false,
      currentEditingItem: null,
      editForm: {
        description: ''
      },
      analyzing: false,
      aiTags: [],
      previewUrl: '',
      isVideo: false
    }
  },
  mounted() {
    this.fetchCaseList();
  },
  methods: {
    fetchCaseList() {
      this.caseListLoading = true;
      getCaseList().then(res => {
        // request.js returns res directly, which includes code and data if wrapped by GlobalResponseAdvice
        // But GlobalResponseAdvice wraps everything in WVPResult (code, msg, data)
        // And request.js says: const res = response.data; if (res.code !== 0) throw; else return res;
        // So 'res' here IS the WVPResult object: { code: 0, msg: "success", data: [...] }
        if (res.data) {
           this.caseList = res.data;
        } else {
           // Fallback if data is directly returned (though unlikely with GlobalResponseAdvice)
           this.caseList = Array.isArray(res) ? res : [];
        }
        this.caseListLoading = false;
      }).catch(err => {
        console.error(err);
        this.caseListLoading = false;
      });
    },
    handleCaseSelect(val) {
      this.currentCase = val;
      if (val) {
        this.fetchEvidenceList(val.id);
      } else {
        this.evidenceList = [];
      }
    },
    fetchEvidenceList(caseId) {
      getEvidenceList(caseId).then(res => {
        let list = [];
        if (res.data) {
            list = res.data;
        } else if (Array.isArray(res)) {
            list = res;
        }
        
        this.evidenceList = list.map(item => ({
            ...item, 
            editing: false, 
            tempDesc: item.description 
        }));
      });
    },
    
    // Add Evidence
    showAddDialog() {
      this.addDialogVisible = true;
      // Set default time range: last 30 days
      const end = new Date();
      const start = new Date();
      start.setTime(start.getTime() - 3600 * 1000 * 24 * 30);
      this.recordListQuery.timeRange = [parseTime(start), parseTime(end)];
      this.getRecordList();
    },
    getRecordList() {
      this.recordListLoading = true;
      const params = {
        page: this.recordListQuery.page,
        count: this.recordListQuery.count,
        app: this.recordListQuery.app,
        stream: this.recordListQuery.stream
      };
      if (this.recordListQuery.timeRange && this.recordListQuery.timeRange.length > 0) {
        params.startTime = this.recordListQuery.timeRange[0];
        params.endTime = this.recordListQuery.timeRange[1];
      }

      getCloudRecordList(params).then(res => {
        this.recordList = res.data.list;
        this.recordTotal = res.data.total;
        this.recordListLoading = false;
      }).catch(() => {
        this.recordListLoading = false;
      });
    },
    formatTime(row, column, cellValue) {
      if (!cellValue) return '';
      return parseTime(new Date(cellValue));
    },
    handleRecordSizeChange(val) {
      this.recordListQuery.count = val;
      this.getRecordList();
    },
    handleRecordCurrentChange(val) {
      this.recordListQuery.page = val;
      this.getRecordList();
    },
    handleSelectionChange(val) {
      this.selectedRecords = val;
    },
    confirmAddEvidence() {
      if (this.selectedRecords.length === 0) {
        this.$message.warning('请选择至少一条录像');
        return;
      }
      
      const promises = this.selectedRecords.map(record => {
        return addEvidence({
          caseId: this.currentCase.id,
          recordId: record.id,
          type: 'video',
          description: record.fileName // Default description
        });
      });
      
      Promise.all(promises).then(() => {
        this.$message.success('添加成功');
        this.addDialogVisible = false;
        this.fetchEvidenceList(this.currentCase.id);
      });
    },

    // Edit & Delete
    toggleEdit(item) {
      // 打开新的标注弹窗，不再使用行内编辑
      this.currentEditingItem = item;
      this.editForm.description = item.description;
      this.aiTags = []; // 重置 AI 标签
      this.editDialogVisible = true;
      this.previewUrl = '';
      this.isVideo = item.type === 'video';
      
      if (this.isVideo) {
        this.initPreview(item);
      }
    },
    initPreview(item) {
       // 优先使用直链预览
       if (item.url && (item.url.startsWith('http') || item.url.startsWith('/'))) {
          this.previewUrl = item.url;
          return;
       }
       
       if (!item.recordId) return;

       this.$store.dispatch('cloudRecord/getPlayPath', item.recordId)
          .then((data) => {
             let playUrl = null;
             if (location.protocol === 'https:') {
               if (data.httpsPath) playUrl = data.httpsPath;
               else if (data.httpPath) playUrl = data.httpPath;
             } else {
               if (data.httpPath) playUrl = data.httpPath;
               else if (data.httpsPath) playUrl = data.httpsPath;
             }
             
             if (playUrl) {
               this.previewUrl = playUrl;
             }
          })
          .catch(e => {
             console.error('Preview init failed', e);
          });
    },
    handleAnalyze() {
      if (!this.currentEditingItem) return;
      this.analyzing = true;
      this.aiTags = [];
      
      // 调用模拟的 AI 分析接口
      analyzeEvidence(this.currentEditingItem.id).then(res => {
        this.analyzing = false;
        if (res.data) {
          this.aiTags = res.data;
          this.$message.success('分析完成，发现 ' + res.data.length + ' 个关键信息');
        } else {
          this.$message.info('未提取到有效信息');
        }
      }).catch(() => {
        this.analyzing = false;
        this.$message.error('分析失败，请重试');
      });
    },
    getTagType(type) {
      const map = {
        'person': 'danger',
        'vehicle': 'warning',
        'clothing': 'primary',
        'object': 'info',
        'location': 'success'
      }
      return map[type] || ''
    },
    applyTag(tag) {
      const text = tag.label;
      if (this.editForm.description) {
        if (!this.editForm.description.includes(text)) {
           this.editForm.description += `，${text}`;
        }
      } else {
        this.editForm.description = text;
      }
    },
    saveEdit() {
      if (!this.currentEditingItem) return;
      
      updateEvidence({
        id: this.currentEditingItem.id,
        description: this.editForm.description
      }).then(() => {
        // Update local list
        const item = this.evidenceList.find(e => e.id === this.currentEditingItem.id);
        if (item) {
          item.description = this.editForm.description;
          item.tempDesc = this.editForm.description; // sync temp
        }
        this.$message.success('标注保存成功');
        this.editDialogVisible = false;
      });
    },
    handleDelete(item) {
      this.$confirm('确认移除该证据吗?', '提示', {
        type: 'warning'
      }).then(() => {
        deleteEvidence(item.id).then(() => {
          this.$message.success('删除成功');
          this.fetchEvidenceList(this.currentCase.id);
        });
      });
    },
    playVideo(item) {
       let watermarkText = '中国烟草';
       let deviceText = item.description || '案件证据';

       // 1. 如果有静态直链（Mock数据或已解析的地址），直接播放
       if (item.url && (item.url.startsWith('http') || item.url.startsWith('/'))) {
          const streamInfo = {
             app: 'live', 
             stream: 'evidence', 
             mediaServerId: 'auto',
             ws_flv: item.url,
             wss_flv: item.url,
             duration: 0
          };
          this.$refs.playerDialog.openDialog(streamInfo, 0, null, watermarkText, deviceText);
          return;
       }

       // 2. 如果没有 recordId，无法请求后端
       if (!item.recordId) {
          this.$message.warning('该证据无关联录像且无有效播放地址');
          return;
       }

       this.$store.dispatch('cloudRecord/getPlayPath', item.recordId)
          .then((data) => {
             let playUrl = null;
             if (location.protocol === 'https:') {
               if (data.httpsPath) playUrl = data.httpsPath;
               else if (data.httpPath) playUrl = data.httpPath;
             } else {
               if (data.httpPath) playUrl = data.httpPath;
               else if (data.httpsPath) playUrl = data.httpsPath;
             }

             // If it is a MinIO/S3 direct link (not ZLM proxy), play directly
             if (playUrl && playUrl.indexOf('/index/api/downloadFile') === -1) {
                 const streamInfo = {
                     app: 'live', 
                     stream: 'evidence', 
                     mediaServerId: 'auto',
                     ws_flv: playUrl,
                     wss_flv: playUrl,
                     duration: 0
                 };
                 // Try to use info from item if available (it might be extended by backend)
                 if (item.cloudRecord) {
                     streamInfo.app = item.cloudRecord.app;
                     streamInfo.stream = item.cloudRecord.stream;
                     streamInfo.duration = item.cloudRecord.timeLen;
                     streamInfo.mediaServerId = item.cloudRecord.mediaServerId;
                     deviceText = item.cloudRecord.gbName || item.cloudRecord.stream;
                 }
                 
                 this.$refs.playerDialog.openDialog(streamInfo, streamInfo.duration, null, watermarkText, deviceText);
                 return;
             }

             // Fallback to original ZLM loadRecord logic
             // Try to use info from item.cloudRecord if available
             let app = 'live';
             let stream = 'evidence';
             if (item.cloudRecord) {
                 app = item.cloudRecord.app;
                 stream = item.cloudRecord.stream;
             }
             
             this.$store.dispatch('cloudRecord/loadRecord', {
               app: app,
               stream: stream,
               cloudRecordId: item.recordId
             })
               .then(data => {
                 this.$refs.playerDialog.openDialog(data, item.cloudRecord ? item.cloudRecord.timeLen : 0, null, watermarkText, deviceText)
               })
               .catch((error) => {
                 console.log(error)
                 this.$message.error('无法播放：' + (error.msg || '获取流信息失败'));
               })
          })
          .catch((e) => {
             console.error(e);
             // Last resort fallback attempt
             let app = 'live';
             let stream = 'evidence';
             if (item.cloudRecord) {
                 app = item.cloudRecord.app;
                 stream = item.cloudRecord.stream;
             }
             this.$store.dispatch('cloudRecord/loadRecord', {
               app: app,
               stream: stream,
               cloudRecordId: item.recordId
             })
               .then(data => {
                 this.$refs.playerDialog.openDialog(data, item.cloudRecord ? item.cloudRecord.timeLen : 0, null, watermarkText, deviceText)
               })
               .catch((error) => {
                 console.log(error)
                 this.$message.error('获取播放地址失败');
               })
          })
    }
  }
}
</script>

<style scoped>
.empty-block {
  text-align: center;
  padding: 100px 0;
}
.video-placeholder {
  height: 150px;
  background-color: #000;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;
}
.video-placeholder i {
  font-size: 48px;
  color: #fff;
  opacity: 0.7;
}
.video-placeholder:hover i {
  opacity: 1;
}
.evidence-desc {
  height: 40px;
  overflow: hidden;
  margin-bottom: 10px;
  font-size: 14px;
  color: #606266;
}
.time {
  font-size: 13px;
  color: #999;
}
.bottom {
  margin-top: 13px;
  line-height: 12px;
}
.button {
  padding: 0;
  float: right;
  margin-left: 10px;
}
.clearfix:before,
.clearfix:after {
    display: table;
    content: "";
}
.clearfix:after {
    clear: both
}

/* Edit Dialog Styles */
.evidence-edit-container {
  min-height: 400px;
}
.media-preview {
  background: #000;
  height: 400px;
  display: flex;
  justify-content: center;
  align-items: center;
  border-radius: 4px;
  overflow: hidden;
}
.video-box {
  text-align: center;
}
.image-box {
  width: 100%;
  height: 100%;
}
.section-title {
  font-weight: bold;
  font-size: 15px;
  margin-bottom: 10px;
  padding-left: 10px;
  border-left: 4px solid #409EFF;
}
.ai-result-area {
  margin-top: 15px;
  min-height: 150px;
  border: 1px dashed #d9d9d9;
  border-radius: 4px;
  padding: 10px;
  background: #fafafa;
}
.tag-cloud {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
}
.ai-tag {
  cursor: pointer;
  transition: all 0.2s;
}
.ai-tag:hover {
  transform: scale(1.05);
}
.tips {
  margin-top: 10px;
  font-size: 12px;
  color: #909399;
}
</style>
