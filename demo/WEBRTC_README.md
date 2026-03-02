# WebRTC 播放功能使用说明

## 概述

本 Demo 项目已集成 WebRTC 播放功能，支持通过 WVP-GB28181-pro 平台播放 GB28181 设备的视频流。

## 功能特性

- ✅ 支持 WebRTC (HTTP) 播放
- ✅ 支持 WebRTC (HTTPS) 播放
- ✅ 自动协议降级（WebRTC → WebSocket FLV → HTTP FLV → HLS）
- ✅ 流不存在时自动重试
- ✅ 完整的错误处理和用户提示

## 前置条件

### 1. ZLMediaKit 启用 WebRTC 支持

WebRTC 功能需要 ZLMediaKit 流媒体服务器在编译时启用 WebRTC 支持。

**编译步骤**（参考 [ZLMediaKit WebRTC 编译指南](https://github.com/ZLMediaKit/ZLMediaKit/wiki/zlm%E5%90%AF%E7%94%A8webrtc%E7%BC%96%E8%AF%91%E6%8C%87%E5%8D%97)）：

```bash
# 国内用户推荐从同步镜像网站gitee下载 
git clone --depth 1 https://gitee.com/xia-chu/ZLMediaKit
cd ZLMediaKit
# 千万不要忘记执行这句命令
git submodule update --init

# 编译（确保启用了WebRTC支持）
mkdir build
cd build
cmake .. -DENABLE_WEBRTC=ON
make -j4
```

**验证 WebRTC 功能**：
访问 `http://{流媒体IP}:{httpPort}/index/api/getServerConfig`，检查返回的配置中是否包含 WebRTC 相关配置。

### 2. 配置流媒体服务器

确保 ZLMediaKit 配置文件中启用了 WebRTC 相关端口配置。

### 3. 配置代理

在 `vite.config.js` 中配置流媒体服务器代理：

```javascript
'/index': {
  target: 'http://127.0.0.1:8080', // 流媒体服务器地址（ZLMediaKit默认HTTP端口）
  changeOrigin: true,
  secure: false,
  ws: true, // 支持WebSocket
  rewrite: (path) => path
}
```

## 使用方法

### 1. 启动开发服务器

```bash
cd demo
npm install
npm run dev
```

### 2. 播放视频流

1. 在左侧设备树中选择一个在线通道
2. 系统会自动调用播放接口启动流
3. 默认优先使用 WebRTC 协议播放
4. 如果 WebRTC 失败，会自动降级到其他协议

### 3. 切换播放协议

在播放器右上角的下拉菜单中选择不同的协议：
- WebRTC (HTTPS) - 优先使用
- WebRTC (HTTP)
- WebSocket FLV
- HTTP FLV
- HTTP FMP4
- HLS

## API 调用流程

### 1. 启动播放

```javascript
GET /api/play/start/{deviceId}/{channelId}
```

**响应示例**：
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "app": "rtp",
    "stream": "34020000001320000001_34020000001320000011",
    "ip": "192.168.1.100",
    "rtc": "http://192.168.1.100:80/index/api/webrtc?app=rtp&stream=34020000001320000001_34020000001320000011&type=play",
    "rtcs": "https://192.168.1.100:443/index/api/webrtc?app=rtp&stream=34020000001320000001_34020000001320000011&type=play",
    "flv": "http://192.168.1.100:80/rtp/34020000001320000001_34020000001320000011.flv",
    "hls": "http://192.168.1.100:80/rtp/34020000001320000001_34020000001320000011/hls.m3u8"
  }
}
```

### 2. WebRTC 播放器初始化

使用 `ZLMRTCClient.Endpoint` 初始化播放器：

```javascript
webrtcPlayer = new ZLMRTCClient.Endpoint({
  element: videoElement,      // video 标签元素
  debug: true,                // 是否打印日志
  zlmsdpUrl: rtcUrl,          // WebRTC 流地址
  simulecast: false,          // 是否启用联播
  useCamera: false,           // 不使用摄像头
  audioEnable: true,          // 启用音频
  videoEnable: true,          // 启用视频
  recvOnly: true,             // 只接收流（播放模式）
  usedatachannel: false       // 不使用数据通道
})
```

### 3. 事件处理

```javascript
// 播放成功
webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_REMOTE_STREAMS, (e) => {
  console.log('播放成功', e.streams)
})

// ICE 协商出错
webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ICE_CANDIDATE_ERROR, (e) => {
  console.error('ICE 协商出错')
})

// Offer/Answer 交换失败
webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_OFFER_ANWSER_EXCHANGE_FAILED, (e) => {
  if (e.code == -400 && e.msg == '流不存在') {
    // 流不存在，等待后重试
  }
})
```

## WebRTC URL 格式

根据文档，WebRTC URL 格式如下：

### HTTP 格式（rtc）
```
http://{流媒体IP}:{httpPort}/index/api/webrtc?app={app}&stream={stream}&type=play
```

### HTTPS 格式（rtcs）
```
https://{流媒体IP}:{httpSSlPort}/index/api/webrtc?app={app}&stream={stream}&type=play
```

### 参数说明
- `{流媒体IP}`: ZLMediaKit 流媒体服务器的 IP 地址
- `{httpPort}`: HTTP 端口（默认 80）
- `{httpSSlPort}`: HTTPS 端口（默认 443）
- `app`: 应用名（通常为 "rtp"）
- `stream`: 流ID（格式: "设备ID_通道ID"）
- `type`: 类型，播放时为 "play"，推流时为 "push"

## 常见问题

### 1. WebRTC 播放失败，提示"流不存在"

**原因**：流尚未启动完成，需要等待设备推送 RTP 流到流媒体服务器。

**解决方案**：
- 系统会自动等待 5 秒后重试
- 如果多次重试失败，会自动降级到其他协议

### 2. WebRTC API 返回 404 错误

**原因**：ZLMediaKit 未启用 WebRTC 功能或配置不正确。

**解决方案**：
- 检查 ZLMediaKit 是否启用了 WebRTC 编译选项
- 检查流媒体服务器配置文件中是否启用了 WebRTC 端口
- 访问 `http://{流媒体IP}:{httpPort}/index/api/getServerConfig` 验证配置

### 3. ZLMRTCClient.js 加载失败

**原因**：无法从 WVP 服务器加载 ZLMRTCClient.js 文件。

**解决方案**：
- 检查 `index.html` 中的脚本加载路径
- 确保 WVP 服务器正常运行
- 检查网络连接和代理配置

### 4. 浏览器不支持 WebRTC

**原因**：浏览器版本过旧或未启用 WebRTC 支持。

**解决方案**：
- 使用现代浏览器（Chrome、Firefox、Edge 最新版本）
- 检查浏览器是否启用了 WebRTC 功能
- 系统会自动降级到其他协议

## 参考文档

- [WebRTC流媒体调用说明.md](../WebRTC流媒体调用说明.md)
- [ZLMediaKit WebRTC 编译指南](https://github.com/ZLMediaKit/ZLMediaKit/wiki/zlm%E5%90%AF%E7%94%A8webrtc%E7%BC%96%E8%AF%91%E6%8C%87%E5%8D%97)

## 技术栈

- Vue 3
- Element Plus
- ZLMRTCClient.js
- Axios
- Vite

