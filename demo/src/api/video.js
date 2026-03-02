import axios from 'axios'

// 配置 token
const TOKEN = 'eyJhbGciOiJSUzI1NiIsImtpZCI6IjNlNzk2NDZjNGRiYzQwODM4M2E5ZWVkMDlmMmI4NWFlIn0.eyJqdGkiOiJzVWFFUE1fOThMTENENU5WTHFKSHNBIiwiaWF0IjoxNzY1Nzk1MzI4LCJleHAiOjEwNzkyMDU1MzQwMzkwNCwibmJmIjoxNzY1Nzk1MzI4LCJzdWIiOiJsb2dpbiIsImF1ZCI6IkF1ZGllbmNlIiwidXNlck5hbWUiOiJhZG1pbiIsImFwaUtleUlkIjoxfQ.kbqVeTb-TwYhVIkgDTBe0eY5gH4i6gsq6T7tt44Z1gE1rYGy0NN3EgRjAtoBz8-9uWunW-_s0eu1DO2jZot3muBMDX5sbndhLtI3EoBo4laZER-mV__8mX0qM_02NwKtMVxh-iDQLscxF1uaukgaiukGIbfFJFIhTrmdQ2UXerLp9CAE6buhmhu1TDjJooQlIY3adr7tulfO4ibLDIs-SVAq_Y8Bop1I6pOHuwmrSIXtDS-A7IwFjUrMmVfuqNVm9YjvP4r6mxSFL5xaMcJXkChKjxsMkLFMgQc3qZqRi4oEm2SaSVywbOlivkHpkBn1X2o44CA6UcduWvADi_egcg'

// 创建 axios 实例
// 注意：如果 /openapi/v1/video 接口不可用，可以使用 /api/device/query 接口
const service = axios.create({
  baseURL: '/api/device/query',
  timeout: 30000
})

// 请求拦截器
service.interceptors.request.use(
  config => {
    // 使用配置的 token
    if (TOKEN && TOKEN !== 'your-token-here') {
      config.headers['access-token'] = TOKEN
    } else {
      // 如果未配置token，尝试从 localStorage 获取（向后兼容）
      const token = localStorage.getItem('wvp-token')
      if (token) {
        config.headers['access-token'] = token
      }
    }
    return config
  },
  error => {
    console.error('请求错误:', error)
    return Promise.reject(error)
  }
)

// 响应拦截器
service.interceptors.response.use(
  response => {
    return response
  },
  error => {
    if (error.response && error.response.status === 401) {
      // 未授权，清除 token
      localStorage.removeItem('wvp-token')
      alert('登录已过期，请重新登录')
    }
    return Promise.reject(error)
  }
)

/**
 * 获取设备树
 * 使用 /api/device/query/devices 接口获取设备列表，然后构建树形结构
 */
export function getDeviceTree(params = {}) {
  return service.get('/devices', { 
    params: {
      page: 1,
      count: 1000,
      ...params
    }
  })
}

/**
 * 获取设备列表
 */
export function getDevices(params = {}) {
  return service.get('/devices', { params })
}

/**
 * 获取设备通道列表
 */
export function getChannels(deviceId, params = {}) {
  return service.get(`/devices/${deviceId}/channels`, { params })
}

/**
 * 开始播放
 * 使用 /api/play/start/{deviceId}/{channelId} 接口
 * 
 * 返回的响应中包含以下字段：
 * - rtc: WebRTC HTTP 播放地址，格式: http://{流媒体IP}:{httpPort}/index/api/webrtc?app={app}&stream={stream}&type=play
 * - rtcs: WebRTC HTTPS 播放地址，格式: https://{流媒体IP}:{httpSSlPort}/index/api/webrtc?app={app}&stream={stream}&type=play
 * - flv: HTTP FLV 播放地址
 * - hls: HLS 播放地址
 * - app: 应用名（通常为 "rtp"）
 * - stream: 流ID（格式: "设备ID_通道ID"）
 * 
 * 参考文档: WebRTC流媒体调用说明.md
 */
export function play(deviceId, channelId) {
  // 创建新的axios实例用于播放接口
  const playService = axios.create({
    baseURL: '/api/play',
    timeout: 180000 // 增加超时时间到180秒，因为播放接口是异步的，需要等待设备响应
  })
  // 添加token
  playService.interceptors.request.use(config => {
    if (TOKEN && TOKEN !== 'your-token-here') {
      config.headers['access-token'] = TOKEN
    }
    return config
  })
  return playService.get(`/start/${deviceId}/${channelId}`)
}

/**
 * 停止播放
 * 使用 /api/play/stop/{deviceId}/{channelId} 接口
 */
export function stopPlay(deviceId, channelId) {
  // 创建新的axios实例用于播放接口
  const playService = axios.create({
    baseURL: '/api/play',
    timeout: 30000
  })
  // 添加token
  playService.interceptors.request.use(config => {
    if (TOKEN && TOKEN !== 'your-token-here') {
      config.headers['access-token'] = TOKEN
    }
    return config
  })
  return playService.get(`/stop/${deviceId}/${channelId}`)
}

export default service

