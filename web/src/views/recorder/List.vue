<template>
  <div class="app-container">
    <div class="filter-container">
       <el-input placeholder="执法仪编号/名称" v-model="listQuery.query" style="width: 200px;" class="filter-item" @keyup.enter.native="handleFilter" />
       <el-button class="filter-item" type="primary" icon="el-icon-search" style="margin-left: 10px;" @click="handleFilter">
        搜索
      </el-button>
      <el-button class="filter-item" type="success" icon="el-icon-upload" style="margin-left: 10px;" @click="showUploadDialog">
        上传录像
      </el-button>
    </div>
    <el-card>
      <div slot="header" class="clearfix">
        <span>执法仪列表 (推流设备)</span>
      </div>
      <el-table :data="list" v-loading="listLoading" border style="width: 100%">
         <el-table-column label="设备ID (Stream)" prop="stream" width="180"></el-table-column>
         <el-table-column label="设备名称" prop="gbName" width="180"></el-table-column>
         <el-table-column label="应用名" prop="app" width="100"></el-table-column>
         <el-table-column label="接入时间" prop="createTime"></el-table-column>
         <el-table-column label="在线状态" width="100">
            <template slot-scope="scope">
              <el-tag :type="scope.row.status ? 'success' : 'info'">{{ scope.row.status ? '在线' : '离线' }}</el-tag>
            </template>
         </el-table-column>
         <el-table-column label="操作" width="250" fixed="right">
           <template slot-scope="scope">
             <el-button type="primary" size="mini" icon="el-icon-video-camera" @click="handleViewRecords(scope.row)">
               查看录像
             </el-button>
             <el-button type="danger" size="mini" icon="el-icon-delete" @click="handleDeletePush(scope.row)">
               删除
             </el-button>
           </template>
         </el-table-column>
      </el-table>
      
      <el-pagination
        v-show="total>0"
        :current-page="listQuery.page"
        :page-sizes="[10, 20, 30, 50]"
        :page-size="listQuery.count"
        layout="total, sizes, prev, pager, next, jumper"
        :total="total"
        @size-change="handleSizeChange"
        @current-change="handleCurrentChange"
        style="float: right; margin-top: 20px;"
      />
    </el-card>

    <!-- Upload Dialog -->
    <el-dialog title="上传执法仪录像" :visible.sync="uploadVisible" width="500px">
      <el-form label-width="100px">
        <el-form-item label="选择文件">
          <el-upload
            class="upload-demo"
            ref="upload"
            action="#"
            :auto-upload="false"
            :on-change="handleFileChange"
            :on-remove="handleFileRemove"
            :file-list="fileList"
            :limit="1"
            accept=".mp4">
            <el-button slot="trigger" size="small" type="primary">选取文件</el-button>
            <div slot="tip" class="el-upload__tip">
              只能上传mp4文件<br/>
              命名格式: <b>设备名_开始时间_结束时间.mp4</b><br/>
              例如: Police001_20230101120000_20230101130000.mp4
            </div>
          </el-upload>
        </el-form-item>
        <el-form-item v-if="uploading">
           <el-progress :percentage="percentage"></el-progress>
           <div style="margin-top: 5px">{{ uploadStatusText }}</div>
        </el-form-item>
      </el-form>
      <span slot="footer" class="dialog-footer">
        <el-button @click="uploadVisible = false" :disabled="uploading">取 消</el-button>
        <el-button type="primary" @click="submitUpload" :loading="uploading">开始上传</el-button>
      </span>
    </el-dialog>

    <!-- Record List Dialog -->
    <el-dialog :title="'云端录像列表 - ' + currentStreamName" :visible.sync="recordDialogVisible" width="80%">
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
          />
          <el-button class="filter-item" type="primary" icon="el-icon-search" @click="getRecordList" style="margin-left: 10px;">查询</el-button>
       </div>
       <el-table :data="recordList" v-loading="recordListLoading" border style="width: 100%" height="400">
          <el-table-column label="开始时间" prop="startTime" :formatter="formatTime"></el-table-column>
          <el-table-column label="结束时间" prop="endTime" :formatter="formatTime"></el-table-column>
          <el-table-column label="时长(秒)" prop="timeLen">
             <template slot-scope="scope">
                {{ scope.row.timeLen ? (scope.row.timeLen / 1000).toFixed(2) : '0.00' }}
             </template>
          </el-table-column>
          <el-table-column label="文件名" prop="fileName"></el-table-column>
          <el-table-column label="操作" width="250">
            <template slot-scope="scope">
                <el-button size="mini" icon="el-icon-video-play" type="text" @click="play(scope.row)">播放</el-button>
                <el-button size="mini" icon="el-icon-download" type="text" @click="downloadFile(scope.row)">下载</el-button>
                <el-button type="text" size="mini" icon="el-icon-delete" style="color: #f56c6c;" @click="handleDelete(scope.row)">
                 删除
               </el-button>
            </template>
          </el-table-column>
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
       <playerDialog ref="playerDialog"></playerDialog>
    </el-dialog>
  </div>
</template>

<script>
import { uploadRecorderFile } from '@/api/recorder'
import { getPushList, deletePush } from '@/api/push'
import { queryList as getCloudRecordList, deleteRecord } from '@/api/cloudRecord'
import { parseTime } from '@/utils'
import playerDialog from '../cloudRecord/playerDialog'

export default {
  components: {
    playerDialog
  },
  data() {
    return {
      // List
      list: [],
      total: 0,
      listLoading: false,
      listQuery: {
        page: 1,
        count: 10,
        query: '',
        pushing: null // true for online, false for offline
      },

      // Upload
      uploadVisible: false,
      fileList: [],
      uploading: false,
      percentage: 0,
      uploadStatusText: '',

      // Record Dialog
      recordDialogVisible: false,
      currentStream: '',
      currentStreamName: '',
      recordList: [],
      recordTotal: 0,
      recordListLoading: false,
      recordListQuery: {
        page: 1,
        count: 10,
        app: 'live',
        stream: '',
        timeRange: []
      }
    }
  },
  mounted() {
    this.getList();
  },
  methods: {
    getList() {
      this.listLoading = true;
      getPushList(this.listQuery).then(response => {
        this.list = response.data.list;
        this.total = response.data.total;
        this.listLoading = false;
      }).catch(() => {
        this.listLoading = false;
      })
    },
    handleFilter() {
      this.listQuery.page = 1;
      this.getList();
    },
    
    // Upload Methods
    showUploadDialog() {
      this.uploadVisible = true;
      this.fileList = [];
      this.uploading = false;
      this.percentage = 0;
      this.uploadStatusText = '';
    },
    handleFileChange(file, fileList) {
      this.fileList = fileList.slice(-1);
    },
    handleFileRemove(file, fileList) {
      this.fileList = fileList;
    },
    submitUpload() {
      if (this.fileList.length === 0) {
        this.$message.warning('请选择文件');
        return;
      }
      const file = this.fileList[0].raw;
      
      const pattern = /^(.*)_(\d{14})_(\d{14})\.mp4$/;
      if (!pattern.test(file.name)) {
        this.$message.error('文件名格式不正确，请参考示例');
        return;
      }

      const formData = new FormData();
      formData.append('file', file);

      this.uploading = true;
      this.percentage = 0;
      this.uploadStatusText = '正在上传并处理...';

      const progressTimer = setInterval(() => {
        if (this.percentage < 90) {
          this.percentage += 5;
        }
      }, 500);

      uploadRecorderFile(formData).then(response => {
        clearInterval(progressTimer);
        this.percentage = 100;
        this.uploadStatusText = '上传成功! 后台正在进行推流和同步。';
        this.$message.success('上传成功');
        setTimeout(() => {
          this.uploadVisible = false;
          this.getList(); // Refresh list after upload
        }, 1500);
      }).catch(err => {
        clearInterval(progressTimer);
        this.percentage = 0;
        this.uploadStatusText = '上传失败: ' + (err.msg || err.message);
        this.$message.error(this.uploadStatusText);
      }).finally(() => {
        this.uploading = false;
      });
    },

    // Record View Methods
    handleViewRecords(row) {
      this.currentStreamName = row.stream; // Display name
      
      // Use GB ID if available, otherwise use stream ID
      this.currentStream = row.gbDeviceId ? row.gbDeviceId : row.stream;
      
      this.recordListQuery.stream = this.currentStream;
      this.recordListQuery.app = row.app;
      this.recordListQuery.page = 1;
      
      // Set default time range: last 30 days
      const end = new Date();
      const start = new Date();
      start.setTime(start.getTime() - 3600 * 1000 * 24 * 30);
      this.recordListQuery.timeRange = [parseTime(start), parseTime(end)];
      
      this.recordDialogVisible = true;
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
    handleSizeChange(val) {
      this.listQuery.count = val;
      this.getList();
    },
    handleCurrentChange(val) {
      this.listQuery.page = val;
      this.getList();
    },
    handleRecordSizeChange(val) {
      this.recordListQuery.count = val;
      this.getRecordList();
    },
    handleRecordCurrentChange(val) {
      this.recordListQuery.page = val;
      this.getRecordList();
    },
    
    play(row) {
        // Watermark info
        let watermarkText = '中国烟草';
        let deviceText = this.currentStreamName; // Use stream name from list
        
        this.$store.dispatch('cloudRecord/getPlayPath', row.id)
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
                     app: row.app,
                     stream: row.stream,
                     mediaServerId: row.mediaServerId,
                     ws_flv: playUrl,
                     wss_flv: playUrl,
                     duration: row.timeLen
                 };
                 this.$refs.playerDialog.openDialog(streamInfo, row.timeLen, row.startTime, watermarkText, deviceText);
                 return;
             }

             // Fallback to original ZLM loadRecord logic
             this.$store.dispatch('cloudRecord/loadRecord', {
               app: row.app,
               stream: row.stream,
               cloudRecordId: row.id
             })
               .then(data => {
                 this.$refs.playerDialog.openDialog(data, row.timeLen, row.startTime, watermarkText, deviceText)
               })
               .catch((error) => {
                 console.log(error)
               })
          })
          .catch(() => {
             // Fallback
             this.$store.dispatch('cloudRecord/loadRecord', {
               app: row.app,
               stream: row.stream,
               cloudRecordId: row.id
             })
               .then(data => {
                 this.$refs.playerDialog.openDialog(data, row.timeLen, row.startTime, watermarkText, deviceText)
               })
               .catch((error) => {
                 console.log(error)
               })
          })
    },
    downloadFile(row) {
      this.$store.dispatch('cloudRecord/getPlayPath', row.id)
        .then((data) => {
          let downloadUrl = null;
          if (location.protocol === 'https:') {
            if (data.httpsPath) {
              downloadUrl = data.httpsPath;
            } else if (data.httpPath){
              downloadUrl = data.httpPath;
            }
          } else {
            if (data.httpPath) {
              downloadUrl = data.httpPath;
            } else if (data.httpsPath){
              downloadUrl = data.httpsPath;
            }
          }
          
          if (!downloadUrl) {
            this.$message.error({
              showClose: true,
              message: '获取下载地址失败'
            })
            return;
          }

          if (downloadUrl.indexOf('/index/api/downloadFile') === -1) {
             fetch(downloadUrl)
                .then(response => response.blob())
                .then(blob => {
                    const link = document.createElement('a');
                    link.href = URL.createObjectURL(blob);
                    link.download = row.fileName || 'record.mp4';
                    link.target = '_blank';
                    document.body.appendChild(link);
                    link.click();
                    document.body.removeChild(link);
                    URL.revokeObjectURL(link.href);
                })
                .catch(err => {
                    console.error('Blob download failed', err);
                    const link = document.createElement('a');
                    link.target = '_blank';
                    link.href = downloadUrl;
                    link.click();
                });
          } else {
             downloadUrl += '&save_name=' + row.fileName;
             const link = document.createElement('a');
             link.target = '_blank';
             link.href = downloadUrl;
             link.click();
          }
        })
        .catch((error) => {
          console.log(error)
        })
    },

    handleDelete(row) {
      this.$confirm('确认删除该录像文件吗？如果文件存储在云端，也将一并删除。', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deleteRecord([row.id]).then(() => {
          this.$message({
            type: 'success',
            message: '删除成功!'
          });
          this.getRecordList();
        }).catch((err) => {
          console.error(err);
          this.$message.error('删除失败');
        });
      }).catch(() => {});
    },
    handleDeletePush(row) {
      this.$confirm('确认删除该执法仪设备吗？', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        deletePush(row.id).then(() => {
          this.$message({
            type: 'success',
            message: '删除成功!'
          });
          this.getList();
        });
      }).catch(() => {});
    }
  }
}
</script>

<style scoped>
.empty-block {
  text-align: center;
  padding: 50px 0;
}
</style>
