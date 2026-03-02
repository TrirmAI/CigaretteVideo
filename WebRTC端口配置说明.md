# WebRTC端口配置说明

## 问题：WVP中是否需要配置WebRTC端口？

**答案：不需要单独配置WebRTC端口。**

## 详细说明

### 1. WebRTC地址生成机制

WVP生成WebRTC地址时，使用的是**HTTP端口**（`http-port`），而不是RTC端口（8001）。

#### 代码分析

**StreamInfo.java** 中的 `setRtc()` 方法：

```207:219:src/main/java/com/genersoft/iot/vmp/common/StreamInfo.java
    public void setRtc(String host, Integer port, Integer sslPort, String app, String stream, String callIdParam, boolean isPlay) {
        if (callIdParam != null) {
            callIdParam = Objects.equals(callIdParam, "") ? callIdParam : callIdParam.replace("?", "&");
        }
//        String file = String.format("%s/%s?type=%s%s", app, stream, isPlay?"play":"push", callIdParam);
        String file = String.format("index/api/webrtc?app=%s&stream=%s&type=%s%s", app, stream, isPlay?"play":"push", callIdParam);
        if (port > 0) {
            this.rtc = new StreamURL("http", host, port, file);
        }
        if (sslPort > 0) {
            this.rtcs = new StreamURL("https", host, sslPort, file);
        }
    }
```

**ZLMMediaNodeServerService.java** 中调用 `setRtc()` 时传入的参数：

```java
streamInfoResult.setRtc(addr, mediaServer.getHttpPort(), mediaServer.getHttpSSlPort(), app, stream, callIdParam, isPlay);
```

可以看到，传入的是 `getHttpPort()` 和 `getHttpSSlPort()`，而不是RTC端口。

### 2. 端口的作用区分

| 端口类型 | 端口号 | 作用 | 配置位置 |
|---------|--------|------|---------|
| **HTTP端口** | 8080 | WebRTC API接口访问<br/>（`/index/api/webrtc`） | WVP配置：`media.http-port` |
| **RTC端口** | 8001 | WebRTC实际数据传输<br/>（UDP/TCP） | ZLMediaKit配置：`[rtc].port` |

### 3. WebRTC工作流程

```
客户端浏览器
    ↓
1. HTTP请求（端口8080）
   GET /index/api/webrtc?app=rtp&stream=xxx&type=play
    ↓
2. ZLMediaKit返回SDP
    ↓
3. WebRTC协商（使用RTC端口8001）
   - STUN/DTLS/SRTP数据传输
    ↓
4. 媒体流传输（使用RTC端口8001）
```

### 4. 配置总结

#### WVP配置（application-dev.yml）

```yaml
media:
  ip: 127.0.0.1
  stream-ip: 172.31.127.42
  http-port: 8080  # ✅ 用于WebRTC API访问
  secret: 5j76zqeppUp7mpsawXIGo5gLW1O6j7CR
```

**不需要配置**：
- ❌ `rtc-port`（不存在此配置项）
- ❌ `webrtc-port`（不存在此配置项）

#### ZLMediaKit配置（config.ini）

```ini
[rtc]
externIP=172.31.127.42
port=8001          # ✅ WebRTC数据传输端口
tcpPort=8001       # ✅ WebRTC TCP端口
enableTurn=1
```

### 5. 生成的WebRTC地址格式

```
http://172.31.127.42:8080/index/api/webrtc?app=rtp&stream=xxx&type=play
```

**地址组成部分**：
- **协议**：`http://`（使用HTTP端口）
- **IP**：`172.31.127.42`（来自`stream-ip`）
- **端口**：`8080`（来自`http-port`）
- **路径**：`/index/api/webrtc`
- **参数**：`app`, `stream`, `type`

### 6. 为什么不需要配置RTC端口？

1. **API访问**：WebRTC的API接口（`/index/api/webrtc`）通过HTTP端口访问
2. **自动协商**：RTC端口（8001）由ZLMediaKit自动管理，客户端通过SDP协商获取
3. **分离设计**：HTTP端口用于控制，RTC端口用于数据传输

### 7. 配置检查清单

#### ✅ WVP配置（必须）

- [x] `media.http-port: 8080` - WebRTC API访问端口
- [x] `media.stream-ip: 172.31.127.42` - 返回流地址时的IP

#### ✅ ZLMediaKit配置（必须）

- [x] `[rtc].port: 8001` - WebRTC数据传输端口
- [x] `[rtc].externIP: 172.31.127.42` - 外部访问IP

#### ❌ WVP不需要配置

- [ ] `media.rtc-port` - 不存在此配置项
- [ ] `media.webrtc-port` - 不存在此配置项

### 8. 常见误解

**误解1**：需要在WVP中配置RTC端口8001
- **正确理解**：WVP只需要配置HTTP端口（8080），RTC端口在ZLMediaKit中配置

**误解2**：WebRTC地址中的端口应该是8001
- **正确理解**：WebRTC地址使用HTTP端口（8080），RTC端口（8001）用于实际数据传输

**误解3**：需要同时配置HTTP端口和RTC端口
- **正确理解**：WVP只配置HTTP端口，RTC端口由ZLMediaKit管理

## 总结

**WVP中不需要配置WebRTC端口**。只需要配置：
- `media.http-port: 8080` - 用于WebRTC API访问
- `media.stream-ip: 172.31.127.42` - 用于返回流地址

RTC端口（8001）在ZLMediaKit服务器端配置，用于WebRTC的实际数据传输，不需要在WVP中配置。

