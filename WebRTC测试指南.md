# WebRTC播放功能测试指南

## 一、配置验证

### ✅ 已完成配置

1. **WVP配置** (`application-dev.yml` 和 `src/main/resources/application-dev.yml`)
   ```yaml
   media:
     ip: 127.0.0.1
     stream-ip: 172.31.127.42
     http-port: 8080  # ✅ 已更新
     secret: 5j76zqeppUp7mpsawXIGo5gLW1O6j7CR
   ```

2. **Docker流媒体服务器配置**
   - RTC端口：8001（UDP和TCP）
   - HTTP端口：8080（映射自容器80端口）
   - externIP：172.31.127.42
   - 容器状态：运行中

## 二、测试步骤

### 步骤1：验证服务状态

```bash
# 检查WVP服务
curl -I http://127.0.0.1:18080/api/device/query/devices

# 检查流媒体服务器
curl http://127.0.0.1:8080/index/api/getMediaList?secret=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR
```

### 步骤2：通过WVP播放接口获取流信息

#### API接口
```
GET /api/play/start/{deviceId}/{channelId}
```

#### 请求示例
```bash
curl -X GET "http://127.0.0.1:18080/api/play/start/34020000001320000001/34020000001320000011" \
  -H "access-token: YOUR_TOKEN"
```

#### 响应示例（成功）
```json
{
  "code": 0,
  "msg": "success",
  "data": {
    "app": "rtp",
    "stream": "34020000001320000001_34020000001320000011",
    "rtc": "http://172.31.127.42:8080/index/api/webrtc?app=rtp&stream=34020000001320000001_34020000001320000011&type=play",
    "rtcs": "https://172.31.127.42:443/index/api/webrtc?app=rtp&stream=34020000001320000001_34020000001320000011&type=play",
    "flv": "http://172.31.127.42:8080/rtp/34020000001320000001_34020000001320000011.flv",
    "hls": "http://172.31.127.42:8080/rtp/34020000001320000001_34020000001320000011/hls.m3u8"
  }
}
```

### 步骤3：验证WebRTC地址格式

返回的WebRTC地址应包含：
- ✅ 协议：`http://` 或 `https://`
- ✅ IP地址：`172.31.127.42`
- ✅ 端口：`8080`（HTTP）或 `443`（HTTPS）
- ✅ 路径：`/index/api/webrtc`
- ✅ 参数：
  - `app=rtp`（应用名）
  - `stream=xxx`（流ID）
  - `type=play`（播放类型）

### 步骤4：前端播放器测试

#### 使用ZLMRTCClient播放

```javascript
import { play } from '@/api/play'

// 1. 调用播放接口获取流信息
const response = await play(deviceId, channelId)
const streamInfo = response.data.data

// 2. 获取WebRTC地址
const rtcUrl = streamInfo.rtc  // 或 streamInfo.rtcs

// 3. 使用ZLMRTCClient播放
const webrtcPlayer = new ZLMRTCClient.Endpoint({
  element: document.getElementById('videoElement'),
  debug: true,
  zlmsdpUrl: rtcUrl,
  recvOnly: true,
  audioEnable: true,
  videoEnable: true
})

webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_REMOTE_STREAMS, (e) => {
  console.log('播放成功', e.streams)
})
```

## 三、测试脚本

已创建测试脚本：`test-webrtc.sh`

运行测试：
```bash
cd /Users/andyapple/Downloads/wvp-GB28181-pro
./test-webrtc.sh
```

## 四、常见问题排查

### 问题1：播放接口返回404或超时

**可能原因**：
- 设备不存在或未上线
- 通道不存在
- 设备未响应INVITE请求

**解决方法**：
1. 检查设备是否在线：`/api/device/query/devices`
2. 检查通道是否存在：`/api/device/query/{deviceId}/channels`
3. 查看WVP日志：`logs/wvp-*.log`

### 问题2：WebRTC地址中端口不正确

**检查项**：
1. WVP配置中的`media.http-port`是否为`8080`
2. Docker端口映射是否正确：`8080:80`
3. 流媒体服务器配置中的HTTP端口是否为`80`（容器内）

### 问题3：WebRTC连接失败

**检查项**：
1. `externIP`是否正确设置为`172.31.127.42`
2. RTC端口8001是否已映射
3. 防火墙是否开放8001端口
4. 流是否已建立（需要先推流）

### 问题4：返回的流信息中没有rtc字段

**可能原因**：
- 流媒体服务器未启用WebRTC功能
- 流尚未建立

**解决方法**：
1. 确认Docker容器中的MediaServer已编译WebRTC支持
2. 先推流，再查询流信息

## 五、完整测试流程

### 1. 准备测试环境

```bash
# 确保Docker流媒体服务器运行
docker ps | grep polaris-media

# 确保WVP服务运行
ps aux | grep wvp-pro
```

### 2. 添加测试设备（如果还没有）

通过WVP管理界面或API添加GB28181设备

### 3. 调用播放接口

```bash
# 替换为实际的设备ID和通道ID
curl -X GET "http://127.0.0.1:18080/api/play/start/{deviceId}/{channelId}" \
  -H "access-token: YOUR_TOKEN" \
  -H "Content-Type: application/json"
```

### 4. 检查返回的流信息

重点关注：
- `rtc`字段是否存在
- `rtc`地址中的IP是否为`172.31.127.42`
- `rtc`地址中的端口是否为`8080`

### 5. 前端播放测试

在前端页面中：
1. 选择设备通道
2. 点击播放
3. 选择WebRTC播放器
4. 检查是否能正常播放

## 六、WebRTC地址格式验证

### 正确的WebRTC地址格式

```
http://172.31.127.42:8080/index/api/webrtc?app=rtp&stream=34020000001320000001_34020000001320000011&type=play
```

### 地址组成部分

- **协议**：`http://` 或 `https://`
- **主机**：`172.31.127.42`（与externIP一致）
- **端口**：`8080`（HTTP）或 `443`（HTTPS）
- **路径**：`/index/api/webrtc`
- **参数**：
  - `app`：应用名（通常为`rtp`）
  - `stream`：流ID（格式：`设备ID_通道ID`）
  - `type`：类型（`play`表示播放）

## 七、配置检查清单

- [x] WVP配置中`media.http-port`设置为`8080`
- [x] WVP配置中`media.stream-ip`设置为`172.31.127.42`
- [x] Docker流媒体服务器RTC端口配置为`8001`
- [x] Docker流媒体服务器`externIP`设置为`172.31.127.42`
- [x] Docker端口映射：`8080:80`和`8001:8001`
- [x] 流媒体服务器已启用WebRTC功能
- [ ] 设备已添加并在线
- [ ] 已成功推流
- [ ] WebRTC播放测试通过

## 八、下一步操作

1. ✅ 配置已更新完成
2. ⏳ 添加测试设备（如果还没有）
3. ⏳ 通过设备推流
4. ⏳ 调用播放接口获取WebRTC地址
5. ⏳ 在前端使用WebRTC播放器测试播放

## 九、参考文档

- WebRTC流媒体调用说明：`WebRTC流媒体调用说明.md`
- Docker流媒体服务器配置：`Docker流媒体服务器配置说明.md`
- WVP API文档：`http://127.0.0.1:18080/doc.html`

