<template>
  <div class="app-container">
    <el-container>
      <el-header>
        <h1>WVP-Pro OpenAPI Demo - 视频目录树</h1>
        <div class="header-actions">
          <el-input
            v-model="searchKeyword"
            placeholder="搜索设备或通道"
            style="width: 300px; margin-right: 10px"
            clearable
            @clear="handleSearch"
            @keyup.enter="handleSearch"
          >
            <template #prefix>
              <el-icon><Search /></el-icon>
            </template>
          </el-input>
          <el-button type="primary" @click="handleSearch">
            <el-icon><Search /></el-icon>
            搜索
          </el-button>
          <el-button @click="loadDeviceTree">
            <el-icon><Refresh /></el-icon>
            刷新
          </el-button>
        </div>
      </el-header>
      <el-container>
        <el-aside width="400px">
          <VideoTree
            ref="treeRef"
            :key="treeDataKey"
            :tree-data="treeData"
            :loading="treeLoading"
            @node-click="handleNodeClick"
            @load-channels="loadChannels"
          />
        </el-aside>
        <el-main>
          <VideoPlayer
            v-if="currentChannel"
            :device-id="currentChannel.deviceId"
            :channel-id="currentChannel.channelId"
            :channel-name="currentChannel.name"
            @stop="handleStop"
          />
          <el-empty v-else description="请从左侧选择通道进行播放" />
        </el-main>
      </el-container>
    </el-container>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Search, Refresh } from '@element-plus/icons-vue'
import VideoTree from './components/VideoTree.vue'
import VideoPlayer from './components/VideoPlayer.vue'
import { getDeviceTree, getChannels } from './api/video'

const treeRef = ref(null)
const treeData = ref([])
const treeLoading = ref(false)
const searchKeyword = ref('')
const currentChannel = ref(null)
const treeDataKey = ref(0) // 用于强制重新渲染树组件

// 加载设备树（包含所有通道）
const loadDeviceTree = async () => {
  treeLoading.value = true
  try {
    const response = await getDeviceTree({
      query: searchKeyword.value || undefined,
      status: undefined
    })
    if (response.data && response.data.code === 0) {
      // 将设备列表转换为树形结构
      const devices = response.data.data?.list || []
      
      // 并行加载所有设备的通道
      const devicePromises = devices.map(async (device) => {
        try {
          const channelResponse = await getChannels(device.deviceId, {
            page: 1,
            count: 1000
          })
          
          let channels = []
          if (channelResponse.data && channelResponse.data.code === 0) {
            channels = (channelResponse.data.data?.list || []).map(channel => ({
              id: `${device.deviceId}_${channel.deviceId}`,
              label: channel.name || channel.deviceId || '未知通道',
              type: 'channel',
              deviceId: device.deviceId,
              channelId: channel.deviceId,
              online: channel.status === 'ON',
              leaf: true
            }))
          }
          
          return {
            id: device.deviceId,
            label: (device.name || '未知设备') + ' (' + device.deviceId + ')',
            type: 'device',
            online: device.onLine || false,
            deviceId: device.deviceId,
            children: channels,
            leaf: channels.length === 0
          }
        } catch (error) {
          console.error(`加载设备 ${device.deviceId} 的通道失败:`, error)
          return {
            id: device.deviceId,
            label: (device.name || '未知设备') + ' (' + device.deviceId + ')',
            type: 'device',
            online: device.onLine || false,
            deviceId: device.deviceId,
            children: [],
            leaf: true
          }
        }
      })
      
      treeData.value = await Promise.all(devicePromises)
      
      // 更新 key 以强制重新渲染树组件
      treeDataKey.value++
      
      const totalChannels = treeData.value.reduce((sum, device) => sum + (device.children?.length || 0), 0)
      if (treeData.value.length > 0) {
        ElMessage.success(`加载成功，共 ${treeData.value.length} 个设备，${totalChannels} 个通道`)
      } else {
        ElMessage.warning('未找到设备')
      }
    } else {
      ElMessage.error(response.data?.msg || '加载失败')
    }
  } catch (error) {
    console.error('加载设备树失败:', error)
    ElMessage.error('加载设备树失败: ' + (error.message || '未知错误'))
  } finally {
    treeLoading.value = false
  }
}

// 搜索
const handleSearch = () => {
  loadDeviceTree()
}

// 加载通道（已废弃，现在在loadDeviceTree中一次性加载）
const loadChannels = async (deviceId) => {
  // 不再需要，所有通道已在loadDeviceTree中加载
}

// 节点点击
const handleNodeClick = (node) => {
  if (node.type === 'channel' && node.online) {
    currentChannel.value = {
      deviceId: node.deviceId,
      channelId: node.channelId,
      name: node.label
    }
  } else if (node.type === 'channel' && !node.online) {
    ElMessage.warning('该通道不在线，无法播放')
  }
}

// 停止播放
const handleStop = () => {
  currentChannel.value = null
}

onMounted(() => {
  loadDeviceTree()
})
</script>

<style scoped>
.app-container {
  width: 100%;
  height: 100vh;
  display: flex;
  flex-direction: column;
}

.el-header {
  background-color: #409eff;
  color: white;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 20px;
}

.el-header h1 {
  font-size: 20px;
  font-weight: 500;
}

.header-actions {
  display: flex;
  align-items: center;
}

.el-aside {
  border-right: 1px solid #e4e7ed;
  overflow: hidden;
}

.el-main {
  padding: 20px;
  background-color: #f5f7fa;
}
</style>

