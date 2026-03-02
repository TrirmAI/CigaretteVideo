<template>
  <div id="app" class="app-container">
    <div style="height: calc(100vh - 124px);">
      <el-form :inline="true" size="mini">
        <el-form-item label="搜索">
          <el-input
            v-model="search"
            style="margin-right: 1rem; width: auto;"
            placeholder="关键字"
            prefix-icon="el-icon-search"
            clearable
            @input="initData"
          />
        </el-form-item>
        <el-form-item label="Call Id">
          <el-input
            v-model="callId"
            style="margin-right: 1rem; width: auto;"
            placeholder="事务标识"
            prefix-icon="el-icon-search"
            clearable
            @input="initData"
          />
        </el-form-item>
        <el-form-item label="设备">
          <el-input
            v-model="deviceId"
            style="margin-right: 1rem; width: auto;"
            placeholder="设备ID"
            prefix-icon="el-icon-monitor"
            clearable
            @input="initData"
          />
        </el-form-item>
        <el-form-item label="标签">
           <el-input
            v-model="tag"
            style="margin-right: 1rem; width: auto;"
            placeholder="场景标签"
            prefix-icon="el-icon-collection-tag"
            clearable
            @input="initData"
          />
        </el-form-item>
        <el-form-item label="开始时间">
          <el-date-picker
            v-model="startTime"
            type="datetime"
            size="mini"
            style="width: 12rem; margin-right: 1rem;"
            value-format="yyyy-MM-dd HH:mm:ss"
            placeholder="选择日期时间"
            @change="initData"
          />
        </el-form-item>
        <el-form-item label="结束时间">
          <el-date-picker
            v-model="endTime"
            type="datetime"
            size="mini"
            style="width: 12rem; margin-right: 1rem;"
            value-format="yyyy-MM-dd HH:mm:ss"
            placeholder="选择日期时间"
            @change="initData"
          />
        </el-form-item>
        <el-form-item label="节点选择">
          <el-select
            v-model="mediaServerId"
            size="mini"
            style="width: 12rem; margin-right: 1rem;"
            placeholder="请选择"
            @change="initData"
          >
            <el-option label="全部" value="" />
            <el-option
              v-for="item in mediaServerList"
              :key="item.id"
              :label="item.id"
              :value="item.id"
            />
          </el-select>
          <el-button
            icon="el-icon-delete"
            style="margin-right: 1rem;"
            :disabled="multipleSelection.length === 0"
            type="danger"
            @click="deleteRecord"
          >移除
          </el-button>
          <el-button
            icon="el-icon-download"
            style="margin-right: 1rem;"
            :disabled="multipleSelection.length === 0"
            type="primary"
            @click="downloadZip"
          >下载
          </el-button>
          <el-button
            icon="el-icon-download"
            style="margin-right: 1rem;"
            :disabled="multipleSelection.length === 0"
            type="warning"
            @click="downloadWithWatermark"
          >导出(含水印)
          </el-button>
        </el-form-item>
        <el-form-item style="float: right;">
          <el-button icon="el-icon-refresh-right" circle :loading="loading" @click="initData()" />
        </el-form-item>
      </el-form>
      <!--设备列表-->
      <el-table :data="recordList" style="width: 100%" size="small" :loading="loading" height="calc(100% - 64px)" @selection-change="handleSelectionChange">
        <el-table-column
          type="selection"
          width="55"
        />
        <el-table-column prop="app" label="应用名" />
        <el-table-column prop="stream" label="流ID" />
        <el-table-column prop="callId" label="Call Id"/>
        <el-table-column label="开始时间">
          <template v-slot:default="scope">
            {{ formatTimeStamp(scope.row.startTime) }}
          </template>
        </el-table-column>
        <el-table-column label="结束时间">
          <template v-slot:default="scope">
            {{ formatTimeStamp(scope.row.endTime) }}
          </template>
        </el-table-column>
        <el-table-column label="时长">
          <template v-slot:default="scope">
            <el-tag v-if="myServerId !== scope.row.serverId" style="border-color: #ecf1af">{{ formatTime(scope.row.timeLen) }}</el-tag>
            <el-tag v-if="myServerId === scope.row.serverId">{{ formatTime(scope.row.timeLen) }}</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="fileName" label="文件名称" width="200" />
        <el-table-column prop="mediaServerId" label="流媒体" />
        <el-table-column label="操作" fixed="right" width="260">
          <template v-slot:default="scope">
            <el-button size="medium" icon="el-icon-video-play" type="text" @click="play(scope.row)">播放
            </el-button>
            <el-button size="medium" icon="el-icon-download" type="text" @click="downloadFile(scope.row)">下载
            </el-button>
            <el-button size="medium" icon="el-icon-info" type="text" @click="showDetail(scope.row)">详情
            </el-button>
            <el-button
              size="medium"
              icon="el-icon-delete"
              type="text"
              style="color: #f56c6c"
              @click="deleteOneRecord(scope.row)"
            >删除
            </el-button>
          </template>
        </el-table-column>
      </el-table>
      <el-pagination
        style="text-align: right"
        :current-page="currentPage"
        :page-size="count"
        :page-sizes="[15, 25, 35, 50]"
        layout="total, sizes, prev, pager, next"
        :total="total"
        @size-change="handleSizeChange"
        @current-change="currentChange"
      />
    </div>
    <playerDialog ref="playerDialog"></playerDialog>
  </div>
</template>

<script>
import playerDialog from './playerDialog.vue'
import moment from 'moment'
import Vue from 'vue'
import { queryOne } from '../../api/commonChannel.js'
import { getPushList } from '../../api/push.js'

export default {
  name: 'CloudRecord',
  components: { playerDialog },
  data() {
    return {
      search: '',
      callId: '',
      deviceId: '',
      tag: '',
      startTime: '',
      endTime: '',
      playerTitle: '',
      videoUrl: '',
      mediaServerList: [], // 滅体节点列表
      multipleSelection: [],
      mediaServerId: '', // 媒体服务
      mediaServerPath: null, // 媒体服务地址
      recordList: [], // 设备列表
      chooseRecord: null, // 媒体服务
      updateLooper: 0, // 数据刷新轮训标志
      currentPage: 1,
      count: 15,
      total: 0,
      loading: false

    }
  },
  computed: {
    Vue() {
      return Vue
    },
    myServerId() {
      return this.$store.getters.serverId
    }
  },
  mounted() {
    this.initData()
    this.getMediaServerList()
  },
  destroyed() {
    // this.$destroy('recordVideoPlayer')
  },
  methods: {
    initData: function() {
      this.currentPage = 1
      this.getRecordList()
    },
    currentChange: function(val) {
      this.currentPage = val
      this.getRecordList()
    },
    handleSizeChange: function(val) {
      this.count = val
      this.getRecordList()
    },
    handleSelectionChange: function(val) {
      this.multipleSelection = val
    },
    getMediaServerList: function() {
      this.$store.dispatch('server/getOnlineMediaServerList')
        .then((data) => {
          this.mediaServerList = data
        })
    },
    getRecordList: function() {
      this.$store.dispatch('cloudRecord/queryList', {
        query: this.search,
        callId: this.callId,
        deviceId: this.deviceId, // Mock param
        tag: this.tag, // Mock param
        startTime: this.startTime,
        endTime: this.endTime,
        mediaServerId: this.mediaServerId,
        page: this.currentPage,
        count: this.count
      })
        .then((data) => {
          this.total = data.total
          this.recordList = data.list
        })
        .catch((error) => {
          console.log(error)
        })
        .finally(() => {
          this.loading = false
        })
    },
    play(row) {
      this.chooseRecord = row
      this.$refs.playerDialog.stopPlay()
      
      // Fetch channel info for watermark
      let watermarkText = '中国烟草'
      let deviceText = row.stream // Default to stream ID
      
      let queryPromise;
      // Check if stream is a valid database ID (integer)
      // Max Java Integer is 2147483647.
      const isDbId = !isNaN(row.stream) && parseInt(row.stream) <= 2147483647;

      if (isDbId) {
        queryPromise = queryOne(row.stream);
      } else {
        // It's a stream ID (string) or long number, try to find it in push list
        queryPromise = new Promise((resolve, reject) => {
          getPushList({ query: row.stream, page: 1, count: 1 }).then(res => {
            if (res.data.list && res.data.list.length > 0) {
              // Find exact match
              const pushItem = res.data.list.find(item => item.app === row.app && item.stream === row.stream);
              if (pushItem) {
                resolve({
                  name: pushItem.gbName,
                  gbName: pushItem.gbName,
                  gbDeviceId: pushItem.gbDeviceId,
                  isPush: true
                });
                return;
              }
            }
            resolve(null);
          }).catch(() => resolve(null));
        });
      }
      
      queryPromise.then(data => {
        if (data) {
          if (data.isPush) {
            deviceText = (data.gbName || row.stream);
            if (data.gbDeviceId) {
              deviceText += ` (${data.gbDeviceId})`;
            }
          } else {
            deviceText = (data.parentName || '市烟草局') + ' ' + (data.name || data.gbName || row.stream)
          }
        } else {
          deviceText = '市烟草局 ' + row.stream
        }
      }).catch(e => {
        console.log('Failed to fetch channel info for watermark', e)
        deviceText = '市烟草局 ' + row.stream
      }).finally(() => {
        // First check if it is a MinIO file that can be played directly
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
                 // Construct a fake streamInfo for the player
                 const streamInfo = {
                     app: row.app,
                     stream: row.stream,
                     mediaServerId: row.mediaServerId,
                     ws_flv: playUrl, // Use ws_flv field to pass MP4 URL, player will handle it
                     wss_flv: playUrl,
                     duration: row.timeLen
                 };
                 this.$refs.playerDialog.openDialog(streamInfo, row.timeLen, row.startTime, watermarkText, deviceText);
                 this.playLoading = false;
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
               .finally(() => {
                 this.playLoading = false
               })
          })
          .catch(() => {
             // Fallback if getPlayPath fails
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
               .finally(() => {
                 this.playLoading = false
               })
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

          // If URL contains MinIO port (e.g. 9000) or looks like a direct file link (not ZLM API)
          // Try to download via Blob to force download instead of play
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
                    console.error('Blob download failed, falling back to direct link', err);
                    const link = document.createElement('a');
                    link.target = '_blank';
                    link.href = downloadUrl;
                    link.click();
                });
          } else {
             // ZLM API download
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
    showDetail(row) {
      this.$router.push(`/cloudRecord/detail/${row.app}/${row.stream}`)
    },
    deleteRecord() {
      this.$confirm(`确定删除选中的${this.multipleSelection.length}个文件?`, '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ids = []
        for (let i = 0; i < this.multipleSelection.length; i++) {
          ids.push(this.multipleSelection[i].id)
        }
        this.$store.dispatch('cloudRecord/deleteRecord', ids)
          .then((data) => {
            this.$message.success({
              showClose: true,
              message: '删除成功'
            })
            this.getRecordList()
          })
      }).catch(() => {

      })
    },
    downloadZip(withWatermark = false) {
      const ids = []
      for (let i = 0; i < this.multipleSelection.length; i++) {
        ids.push(this.multipleSelection[i].id)
      }
      let idsStr = ids.join(',')
      const link = document.createElement('a')
      link.target = '_blank'
      let baseUri = (process.env.NODE_ENV === 'development') ? process.env.VUE_APP_BASE_API : process.env.VUE_APP_BASE_API
      let downloadUrl = `${location.origin}${baseUri}/api/cloud/record/download/zip?ids=${idsStr}`
      if (withWatermark) {
        downloadUrl += '&watermark=true'
      }
      console.log(downloadUrl)
      link.href = downloadUrl
      link.click()
    },
    downloadWithWatermark() {
      this.$message.success('正在添加数字水印并打包下载，请稍候...')
      setTimeout(() => {
        this.downloadZip(true)
      }, 1500)
    },
    deleteOneRecord(row) {
      this.$confirm('确定删除?', '提示', {
        confirmButtonText: '确定',
        cancelButtonText: '取消',
        type: 'warning'
      }).then(() => {
        const ids = []
        ids.push(row.id)
        this.$store.dispatch('cloudRecord/deleteRecord', ids)
          .then((data) => {
            this.$message.success({
              showClose: true,
              message: '删除成功'
            })
            this.getRecordList()
          })
      }).catch(() => {

      })
    },
    formatTime(time) {
      const h = parseInt(time / 3600 / 1000)
      const minute = parseInt((time - h * 3600 * 1000) / 60 / 1000)
      let second = Math.ceil((time - h * 3600 * 1000 - minute * 60 * 1000) / 1000)
      if (second < 0) {
        second = 0
      }
      return (h > 0 ? h + `小时` : '') + (minute > 0 ? minute + '分' : '') + (second > 0 ? second + '秒' : '')
    },
    formatTimeStamp(time) {
      return moment.unix(time / 1000).format('yyyy-MM-DD HH:mm:ss')
    }
  }
}
</script>

<style>
.el-dialog__body {
  padding: 20px 0 0 0 !important;
}
</style>
