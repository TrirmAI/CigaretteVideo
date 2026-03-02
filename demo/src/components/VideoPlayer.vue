<template>
  <div class="video-player-container">
    <div class="player-header">
      <h3>{{ channelName }}</h3>
      <div class="header-info">
        <el-tag type="info">设备: {{ deviceId }}</el-tag>
        <el-tag type="info" style="margin-left: 10px">通道: {{ channelId }}</el-tag>
        <el-select
          v-model="selectedProtocol"
          placeholder="选择协议"
          style="margin-left: 10px; width: 150px"
          @change="switchProtocol"
          :disabled="!streamInfo"
        >
          <el-option
            v-for="protocol in availableProtocols"
            :key="protocol.value"
            :label="protocol.label"
            :value="protocol.value"
            :disabled="!protocol.available"
          />
        </el-select>
      </div>
    </div>
    <div class="player-content">
      <div v-if="loading" class="loading-container">
        <el-icon class="is-loading" style="font-size: 48px"><Loading /></el-icon>
        <p>正在加载视频流...</p>
      </div>
      <div v-else-if="error" class="error-container">
        <el-icon style="font-size: 48px; color: #f56c6c"><CircleClose /></el-icon>
        <p>{{ error }}</p>
        <el-button type="primary" @click="startPlay">重试</el-button>
      </div>
      <div v-else-if="streamInfo" class="video-wrapper">
        <!-- WebRTC 播放器 -->
        <video
          v-if="selectedProtocol === 'rtc' || selectedProtocol === 'rtcs'"
          ref="rtcVideoRef"
          id="webRtcPlayerBox"
          controls
          autoplay
          playsinline
          muted
          style="width: 100%; height: 100%; object-fit: contain; background-color: #000"
        >
          您的浏览器不支持视频播放
        </video>
        <!-- 其他协议播放器 -->
        <video
          v-else
          ref="videoRef"
          :src="videoUrl"
          controls
          autoplay
          style="width: 100%; height: 100%; object-fit: contain"
          @error="handleVideoError"
        >
          您的浏览器不支持视频播放
        </video>
        <div class="stream-info">
          <el-descriptions :column="2" size="small" border>
            <el-descriptions-item label="流ID">{{ streamInfo.stream }}</el-descriptions-item>
            <el-descriptions-item label="应用">{{ streamInfo.app }}</el-descriptions-item>
            <el-descriptions-item label="流媒体服务ID">{{ streamInfo.mediaServerId }}</el-descriptions-item>
            <el-descriptions-item label="协议">{{ streamProtocol }}</el-descriptions-item>
          </el-descriptions>
        </div>
      </div>
      <div v-else class="empty-container">
        <el-icon style="font-size: 48px"><VideoCamera /></el-icon>
        <p>准备播放</p>
      </div>
    </div>
    <div class="player-footer">
      <el-button type="danger" @click="stopPlay" :disabled="!streamInfo">
        <el-icon><VideoPause /></el-icon>
        停止播放
      </el-button>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import { ElMessage } from 'element-plus'
import { Loading, CircleClose, VideoCamera, VideoPause } from '@element-plus/icons-vue'
import { play, stopPlay as stopPlayApi } from '../api/video'

const props = defineProps({
  deviceId: {
    type: String,
    required: true
  },
  channelId: {
    type: String,
    required: true
  },
  channelName: {
    type: String,
    default: ''
  }
})

const emit = defineEmits(['stop'])

const videoRef = ref(null)
const rtcVideoRef = ref(null)
const loading = ref(false)
const error = ref('')
const streamInfo = ref(null)
const videoUrl = ref('')
const streamProtocol = ref('')
const selectedProtocol = ref('')
const availableProtocols = ref([])
let webrtcPlayer = null // WebRTC 播放器实例

// 开始播放
const startPlay = async () => {
  loading.value = true
  error.value = ''
  streamInfo.value = null
  videoUrl.value = ''

  try {
    console.log('开始播放:', props.deviceId, props.channelId)
    const response = await play(props.deviceId, props.channelId)
    console.log('播放接口响应:', response.data)
    
    if (response.data && response.data.code === 0) {
      const streamContent = response.data.data
      if (streamContent) {
        streamInfo.value = streamContent
        
        // 收集所有可用的协议
        const protocols = []
        
        // WebRTC 协议处理
        // 根据文档，WebRTC URL 格式为: http://{流媒体IP}:{httpPort}/index/api/webrtc?app={app}&stream={stream}&type=play
        if (streamContent.rtc) {
          let rtcUrl = streamContent.rtc
          try {
            // 确保 URL 格式正确
            if (rtcUrl.startsWith('http://') || rtcUrl.startsWith('https://')) {
              const urlObj = new URL(rtcUrl)
              const urlParams = new URLSearchParams(urlObj.search)
              
              // 确保必需参数存在
              if (!urlParams.has('app')) {
                urlParams.set('app', streamContent.app || 'rtp')
              }
              if (!urlParams.has('stream')) {
                urlParams.set('stream', streamContent.stream || '')
              }
              if (!urlParams.has('type')) {
                urlParams.set('type', 'play')
              }
              
              // 重新构建 URL，确保格式正确
              rtcUrl = `${urlObj.protocol}//${urlObj.host}${urlObj.pathname}?${urlParams.toString()}`
              console.log('WebRTC URL (处理后的):', rtcUrl)
            }
          } catch (e) {
            console.warn('WebRTC URL解析失败，使用原始URL:', e)
          }
          protocols.push({ value: 'rtc', label: 'WebRTC', url: rtcUrl, available: true })
        }
        
        // HTTPS WebRTC 协议（rtcs）
        if (streamContent.rtcs) {
          let rtcsUrl = streamContent.rtcs
          try {
            if (rtcsUrl.startsWith('https://')) {
              const urlObj = new URL(rtcsUrl)
              const urlParams = new URLSearchParams(urlObj.search)
              
              if (!urlParams.has('app')) {
                urlParams.set('app', streamContent.app || 'rtp')
              }
              if (!urlParams.has('stream')) {
                urlParams.set('stream', streamContent.stream || '')
              }
              if (!urlParams.has('type')) {
                urlParams.set('type', 'play')
              }
              
              rtcsUrl = `${urlObj.protocol}//${urlObj.host}${urlObj.pathname}?${urlParams.toString()}`
            }
          } catch (e) {
            console.warn('WebRTC HTTPS URL解析失败，使用原始URL:', e)
          }
          protocols.push({ value: 'rtcs', label: 'WebRTC (HTTPS)', url: rtcsUrl, available: true })
        }
        
        // 其他协议保持原始URL，不进行转换（它们可以直接访问流媒体服务器）
        if (streamContent.ws_flv) {
          protocols.push({ value: 'ws_flv', label: 'WebSocket FLV', url: streamContent.ws_flv, available: true })
        }
        if (streamContent.flv) {
          protocols.push({ value: 'flv', label: 'HTTP FLV', url: streamContent.flv, available: true })
        }
        if (streamContent.ws_fmp4) {
          protocols.push({ value: 'ws_fmp4', label: 'WebSocket FMP4', url: streamContent.ws_fmp4, available: true })
        }
        if (streamContent.fmp4) {
          protocols.push({ value: 'fmp4', label: 'HTTP FMP4', url: streamContent.fmp4, available: true })
        }
        if (streamContent.hls) {
          protocols.push({ value: 'hls', label: 'HLS', url: streamContent.hls, available: true })
        }
        
        availableProtocols.value = protocols
        
        // 默认优先使用 WebRTC，但如果WebRTC失败则降级到其他协议
        // 优先顺序：WebRTC HTTPS > WebRTC HTTP > WebSocket FLV > HTTP FLV > FMP4 > HLS
        const protocolPriority = ['rtcs', 'rtc', 'ws_flv', 'flv', 'ws_fmp4', 'fmp4', 'hls']
        let defaultProtocol = null
        
        // 按优先级查找可用协议
        for (const priority of protocolPriority) {
          const found = protocols.find(p => p.value === priority)
          if (found) {
            defaultProtocol = found
            break
          }
        }
        
        // 如果没找到，使用第一个可用协议
        if (!defaultProtocol && protocols.length > 0) {
          defaultProtocol = protocols[0]
        }
        
        if (defaultProtocol) {
          selectedProtocol.value = defaultProtocol.value
          videoUrl.value = defaultProtocol.url
          streamProtocol.value = defaultProtocol.label
          
          // 如果是 WebRTC（rtc 或 rtcs），使用专门的播放器，并添加延迟确保流已启动
          if (defaultProtocol.value === 'rtc' || defaultProtocol.value === 'rtcs') {
            // 等待流启动（流启动需要时间，通常需要5-8秒）
            console.log('等待流启动...')
            nextTick(() => {
              setTimeout(() => {
                console.log('开始尝试 WebRTC 播放')
                playWebRTC(defaultProtocol.url)
              }, 5000) // 等待5秒让流启动完成
            })
          } else {
            // 其他协议使用普通 video 标签
            nextTick(() => {
              if (videoRef.value) {
                videoRef.value.load()
              }
            })
          }
          
          ElMessage.success('播放成功')
        } else {
          error.value = '未找到可用的视频流地址'
        }
      } else {
        error.value = '未获取到流信息'
      }
    } else {
      error.value = response.data?.msg || '播放失败'
      console.error('播放失败:', response.data)
      ElMessage.error(error.value)
    }
  } catch (err) {
    console.error('播放失败:', err)
    if (err.response) {
      error.value = err.response.data?.msg || `播放失败: ${err.response.status} ${err.response.statusText}`
      console.error('错误详情:', err.response.data)
    } else if (err.message) {
      error.value = err.message
    } else {
      error.value = '播放失败，请检查网络连接或设备状态'
    }
    ElMessage.error(error.value)
  } finally {
    loading.value = false
  }
}

// 降级到其他协议
const fallbackToOtherProtocol = () => {
  // 停止WebRTC播放器
  if (webrtcPlayer) {
    try {
      webrtcPlayer.close()
    } catch (e) {
      console.error('关闭WebRTC播放器失败:', e)
    }
    webrtcPlayer = null
  }
  
  // 查找其他可用协议（排除WebRTC）
  const otherProtocols = availableProtocols.value.filter(p => p.value !== 'rtc' && p.value !== 'rtcs')
  if (otherProtocols.length > 0) {
    const fallbackProtocol = otherProtocols[0]
    console.log('降级到协议:', fallbackProtocol.label)
    selectedProtocol.value = fallbackProtocol.value
    videoUrl.value = fallbackProtocol.url
    streamProtocol.value = fallbackProtocol.label
    
    // 使用普通video标签播放
    nextTick(() => {
      if (videoRef.value) {
        videoRef.value.load()
      }
    })
    ElMessage.success(`已切换到 ${fallbackProtocol.label}`)
  } else {
    error.value = '流不存在或已过期，请先启动视频流'
    ElMessage.error('流不存在或已过期，请先启动视频流')
  }
}

// WebRTC 播放
const playWebRTC = (url) => {
  console.log('开始初始化WebRTC播放器, URL:', url)
  
  // 根据文档，WebRTC URL 格式为: http://{流媒体IP}:{httpPort}/index/api/webrtc?app={app}&stream={stream}&type=play
  // ZLMRTCClient 需要完整的 URL，它会自动使用 POST 方法发送 SDP
  let finalUrl = url
  try {
    // 确保 URL 格式正确
    if (url.startsWith('http://') || url.startsWith('https://')) {
      const urlObj = new URL(url)
      const urlParams = new URLSearchParams(urlObj.search)
      
      // 确保必需参数存在
      if (!urlParams.has('app')) {
        urlParams.set('app', streamInfo.value?.app || 'rtp')
      }
      if (!urlParams.has('stream')) {
        urlParams.set('stream', streamInfo.value?.stream || '')
      }
      if (!urlParams.has('type')) {
        urlParams.set('type', 'play')
      }
      
      // 重新构建完整 URL
      finalUrl = `${urlObj.protocol}//${urlObj.host}${urlObj.pathname}?${urlParams.toString()}`
      console.log('WebRTC URL (最终):', finalUrl)
      
      // 如果流媒体服务器在内网，可能需要通过代理访问
      // 检查是否是内网地址（127.0.0.1, localhost, 或私有IP段）
      const hostname = urlObj.hostname
      const isLocalhost = hostname === 'localhost' || hostname === '127.0.0.1' || hostname.startsWith('192.168.') || hostname.startsWith('10.') || hostname.startsWith('172.')
      
      // 如果流媒体服务器在内网且前端无法直接访问，使用代理
      // 注意：这需要根据实际部署情况调整
      if (isLocalhost && urlObj.port !== '18080') {
        // 通过代理访问，转换为相对路径
        finalUrl = `${urlObj.pathname}?${urlParams.toString()}`
        console.log('WebRTC URL 转换为代理路径:', finalUrl)
      }
    } else {
      // 如果已经是相对路径，确保格式正确
      if (!url.startsWith('/')) {
        finalUrl = `/${url}`
      }
      console.log('WebRTC URL (相对路径):', finalUrl)
    }
  } catch (e) {
    console.warn('WebRTC URL 处理失败，使用原始URL:', e)
  }
  
  // 停止之前的播放器
  if (webrtcPlayer) {
    try {
      webrtcPlayer.close()
    } catch (e) {
      console.error('关闭WebRTC播放器失败:', e)
    }
    webrtcPlayer = null
  }
  
  // 检查 ZLMRTCClient 是否加载
  if (typeof ZLMRTCClient === 'undefined') {
    error.value = 'WebRTC播放器库未加载，请刷新页面重试'
    ElMessage.error('WebRTC播放器库未加载')
    return
  }
  
        // 使用 nextTick 确保DOM已更新
        nextTick(() => {
          // 再次等待确保video元素已渲染（增加延迟，给流更多时间启动）
          setTimeout(() => {
            const videoElement = document.getElementById('webRtcPlayerBox')
      if (!videoElement) {
        console.error('找不到WebRTC播放器元素')
        error.value = '找不到WebRTC播放器元素'
        return
      }
      
      console.log('找到video元素:', videoElement)
      console.log('WebRTC URL (最终):', finalUrl)
      console.log('ZLMRTCClient 是否可用:', typeof ZLMRTCClient !== 'undefined')
      console.log('ZLMRTCClient 将使用 POST 方法调用:', finalUrl)
      
      // 确保 video 元素存在且有效
      if (!videoElement || !videoElement.tagName || videoElement.tagName.toLowerCase() !== 'video') {
        console.error('video 元素无效:', videoElement)
        error.value = 'video 元素无效'
        ElMessage.error('video 元素无效')
        return
      }
      
      try {
        // 根据文档，使用 ZLMRTCClient.Endpoint 初始化 WebRTC 播放器
        // zlmsdpUrl 可以是完整 URL 或相对路径（通过代理访问）
        webrtcPlayer = new ZLMRTCClient.Endpoint({
          element: videoElement, // video 标签元素
          debug: true, // 是否打印日志
          zlmsdpUrl: finalUrl, // WebRTC 流地址（完整 URL 或相对路径）
          simulecast: false, // 注意：文档中使用的是 simulecast（不是 simulcast）
          useCamera: false, // 不使用摄像头
          audioEnable: true, // 启用音频
          videoEnable: true, // 启用视频
          recvOnly: true, // 只接收流（播放模式）
          usedatachannel: false // 不使用数据通道
        })
        
        console.log('WebRTC 播放器已创建，将使用 POST 方法调用:', finalUrl)
        
        console.log('WebRTC 播放器已创建:', webrtcPlayer)
        
        webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ICE_CANDIDATE_ERROR, (e) => {
          console.error('ICE 协商出错:', e)
          error.value = 'WebRTC连接失败: ICE协商出错'
          ElMessage.error('WebRTC连接失败')
        })
        
        webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_REMOTE_STREAMS, (e) => {
          console.log('WebRTC播放成功，获取到远端流:', e.streams)
          // ZLMRTCClient会自动将流绑定到element，但我们需要确保video元素正确设置
          if (videoElement && e.streams && e.streams.length > 0) {
            // 确保流已绑定到video元素
            if (!videoElement.srcObject && e.streams[0]) {
              videoElement.srcObject = e.streams[0]
            }
            // 尝试自动播放
            videoElement.play().catch(err => {
              console.error('自动播放失败，用户可能需要手动点击播放:', err)
            })
          }
          ElMessage.success('WebRTC播放成功')
        })
        
        webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_OFFER_ANWSER_EXCHANGE_FAILED, (e) => {
          console.error('offer answer 交换失败:', e)
          console.error('错误详情:', JSON.stringify(e, null, 2))
          
          // 根据文档和参考代码，处理不同的错误情况
          if (e.code == -400 && (e.msg == '流不存在' || (e.msg && e.msg.includes('流不存在')))) {
            // 流不存在，可能是流尚未启动完成，等待后重试
            error.value = '流不存在，可能流尚未启动完成，正在重试...'
            ElMessage.warning('流不存在，等待流启动...')
            // 等待一段时间后重试（流可能还在启动中，通常需要5-8秒）
            setTimeout(() => {
              console.log('重试 WebRTC 播放...')
              if (webrtcPlayer) {
                try {
                  webrtcPlayer.close()
                } catch (err) {
                  console.error('关闭播放器失败:', err)
                }
                webrtcPlayer = null
              }
              playWebRTC(url)
            }, 3000)
          } else if (e.code == 500) {
            // 500 错误通常表示服务器内部错误，可能是流不存在或 WebRTC 未启用
            error.value = '流不存在或服务器错误，正在切换到其他协议...'
            ElMessage.warning('WebRTC 连接失败（500错误），正在切换到其他协议')
            fallbackToOtherProtocol()
          } else if (e.code == 404) {
            // 404 错误表示 WebRTC API 不可用
            error.value = 'WebRTC API 不可用，正在切换到其他协议...'
            ElMessage.warning('WebRTC API 不可用，正在切换到其他协议')
            fallbackToOtherProtocol()
          } else {
            // 其他错误，自动降级到其他协议
            error.value = `WebRTC连接失败: ${e.msg || '未知错误'} (code: ${e.code})`
            ElMessage.warning('WebRTC连接失败，正在切换到其他协议')
            fallbackToOtherProtocol()
          }
        })
        
        webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_CONNECTION_STATE_CHANGE, (state) => {
          console.log('WebRTC连接状态变化:', state)
        })
        
        webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_LOCAL_STREAM, (stream) => {
          console.log('获取到本地流:', stream)
        })
        
        webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_NOT_SUPPORT, (e) => {
          console.error('浏览器不支持WebRTC:', e)
          error.value = '您的浏览器不支持WebRTC播放'
          ElMessage.error('浏览器不支持WebRTC')
          fallbackToOtherProtocol()
        })
        
        // 注意：ZLMRTCClient.Endpoint 构造函数会自动调用 start() 或 receive()，不需要手动调用
      } catch (err) {
        console.error('初始化WebRTC播放器失败:', err)
        error.value = '初始化WebRTC播放器失败: ' + err.message
        ElMessage.error('初始化WebRTC播放器失败')
      }
    }, 200)
  })
}

// 切换协议
const switchProtocol = () => {
  if (!streamInfo.value || !selectedProtocol.value) return
  
  const protocol = availableProtocols.value.find(p => p.value === selectedProtocol.value)
  if (protocol && protocol.available) {
    videoUrl.value = protocol.url
    streamProtocol.value = protocol.label
    
    // 停止之前的WebRTC播放器
    if (webrtcPlayer) {
      try {
        webrtcPlayer.close()
      } catch (e) {
        console.error('关闭WebRTC播放器失败:', e)
      }
      webrtcPlayer = null
    }
    
    // 根据协议类型选择播放方式
    if (protocol.value === 'rtc' || protocol.value === 'rtcs') {
      nextTick(() => {
        setTimeout(() => {
          playWebRTC(protocol.url)
        }, 300)
      })
    } else {
      // 其他协议使用普通 video 标签
      nextTick(() => {
        if (videoRef.value) {
          videoRef.value.load()
        }
      })
    }
    
    ElMessage.success(`已切换到 ${protocol.label}`)
  }
}

// 停止播放
const stopPlay = async () => {
  try {
    // 停止WebRTC播放器
    if (webrtcPlayer) {
      try {
        webrtcPlayer.close()
      } catch (e) {
        console.error('关闭WebRTC播放器失败:', e)
      }
      webrtcPlayer = null
    }
    
    // 停止普通视频播放
    if (videoRef.value) {
      videoRef.value.pause()
      videoRef.value.src = ''
    }
    
    // 调用停止API
    await stopPlayApi(props.deviceId, props.channelId)
    ElMessage.success('已停止播放')
    streamInfo.value = null
    videoUrl.value = ''
    selectedProtocol.value = ''
    availableProtocols.value = []
    emit('stop')
  } catch (err) {
    console.error('停止播放失败:', err)
    ElMessage.error('停止播放失败: ' + (err.message || '未知错误'))
  }
}

// 视频错误处理
const handleVideoError = (e) => {
  console.error('视频播放错误:', e)
  ElMessage.error('视频播放出错，请检查流地址')
}

// 监听设备或通道变化
watch([() => props.deviceId, () => props.channelId], () => {
  if (props.deviceId && props.channelId) {
    startPlay()
  }
}, { immediate: true })

onBeforeUnmount(() => {
  // 清理WebRTC播放器
  if (webrtcPlayer) {
    try {
      webrtcPlayer.close()
    } catch (e) {
      console.error('清理WebRTC播放器失败:', e)
    }
    webrtcPlayer = null
  }
  
  if (streamInfo.value) {
    stopPlay()
  }
})
</script>

<style scoped>
.video-player-container {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
  background-color: #000;
  border-radius: 4px;
  overflow: hidden;
}

.player-header {
  padding: 15px 20px;
  background-color: #303133;
  color: white;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.player-header h3 {
  margin: 0;
  font-size: 16px;
  font-weight: 500;
}

.header-info {
  display: flex;
  align-items: center;
}

.player-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  position: relative;
  background-color: #000;
}

.loading-container,
.error-container,
.empty-container {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  color: #909399;
}

.loading-container p,
.error-container p,
.empty-container p {
  margin-top: 16px;
  font-size: 14px;
}

.error-container {
  color: #f56c6c;
}

.video-wrapper {
  width: 100%;
  height: 100%;
  display: flex;
  flex-direction: column;
}

.stream-info {
  padding: 10px 20px;
  background-color: #303133;
  color: white;
}

.player-footer {
  padding: 15px 20px;
  background-color: #303133;
  display: flex;
  justify-content: flex-end;
}
</style>

