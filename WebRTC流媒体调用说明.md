# WebRTC流媒体外部调用方式和过程说明

## 一、概述

WebRTC（Web Real-Time Communication）是一种实时音视频通信技术，在WVP-GB28181-pro系统中，WebRTC流媒体功能通过ZLMediaKit流媒体服务器提供支持。本文档说明如何通过WVP API获取WebRTC播放地址，以及完整的调用流程。

## 二、WebRTC流地址格式

根据代码实现，WebRTC流地址格式如下：

### HTTP格式（rtc）
```
http://{流媒体IP}:{httpPort}/index/api/webrtc?app={app}&stream={stream}&type=play&callId={callId}&sign={sign}
```

### HTTPS格式（rtcs）
```
https://{流媒体IP}:{httpSSlPort}/index/api/webrtc?app={app}&stream={stream}&type=play&callId={callId}&sign={sign}
```

### 参数说明
- `{流媒体IP}`: ZLMediaKit流媒体服务器的IP地址
- `{httpPort}`: HTTP端口（默认80）
- `{httpSSlPort}`: HTTPS端口（默认443）
- `app`: 应用名（通常为固定值，如"rtp"）
- `stream`: 流ID（格式通常为"设备ID_通道ID"）
- `type`: 类型，播放时为"play"，推流时为"push"
- `callId`: 可选的调用ID，用于鉴权
- `sign`: 可选的签名参数，用于安全验证

## 三、外部调用方式

### 1. 通过WVP播放接口获取流信息

#### 接口地址
```
GET /api/play/start/{deviceId}/{channelId}
```

#### 请求示例
```http
GET /api/play/start/34020000001320000001/34020000001320000011 HTTP/1.1
Host: wvp-server:18080
access-token: {your-token}
```

#### 响应示例
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
    "hls": "http://192.168.1.100:80/rtp/34020000001320000001_34020000001320000011/hls.m3u8",
    "mediaServerId": "auto",
    "mediaInfo": {
      "codec": "H264",
      "codecId": 7,
      "codecName": "H264"
    }
  }
}
```

### 2. 通过应用名和流ID获取流信息

#### 接口地址
```
GET /api/media/stream_info_by_app_and_stream
```

#### 请求参数
- `app`: 应用名（必填）
- `stream`: 流ID（必填）
- `mediaServerId`: 流媒体服务器ID（可选）
- `callId`: 推流时携带的自定义鉴权ID（可选）
- `useSourceIpAsStreamIp`: 是否使用请求IP作为返回的地址IP（可选）

#### 请求示例
```http
GET /api/media/stream_info_by_app_and_stream?app=rtp&stream=34020000001320000001_34020000001320000011 HTTP/1.1
Host: wvp-server:18080
access-token: {your-token}
```

## 四、完整调用流程

### 流程步骤

```
外部系统/前端
    │
    ├─1. 调用WVP播放接口
    │   GET /api/play/start/{deviceId}/{channelId}
    │
    ├─2. WVP验证设备和通道
    │   - 检查设备是否存在
    │   - 检查通道是否存在
    │
    ├─3. WVP通过GB28181协议向设备发起INVITE请求
    │   - SIP INVITE消息
    │   - 携带SDP信息
    │
    ├─4. 设备响应INVITE请求
    │   - 返回200 OK
    │   - 携带设备SDP信息
    │
    ├─5. WVP与ZLMediaKit流媒体服务器交互
    │   - 创建RTP接收端口
    │   - 配置流媒体服务器接收RTP流
    │
    ├─6. 设备开始推送RTP流
    │   - 推送到流媒体服务器
    │   - 流媒体服务器接收并转码
    │
    ├─7. WVP从流媒体服务器获取流信息
    │   - 查询流状态
    │   - 获取各种格式的播放地址（包括WebRTC）
    │
    ├─8. WVP返回流信息给调用方
    │   - 包含rtc和rtcs字段（WebRTC地址）
    │   - 包含其他格式的播放地址（FLV、HLS等）
    │
    └─9. 前端使用WebRTC播放器连接
        - 使用ZLMRTCClient连接到rtc/rtcs地址
        - 进行WebRTC信令交换（Offer/Answer）
        - 建立P2P连接
        - 开始播放视频流
```

### 详细流程说明

#### 步骤1-2: 接口调用和验证
```83:94:src/main/java/com/genersoft/iot/vmp/gb28181/controller/PlayController.java
	@GetMapping("/start/{deviceId}/{channelId}")
	public DeferredResult<WVPResult<StreamContent>> play(HttpServletRequest request, @PathVariable String deviceId,
														 @PathVariable String channelId) {

		log.info("[开始点播] deviceId：{}, channelId：{}, ", deviceId, channelId);
		Assert.notNull(deviceId, "设备国标编号不可为NULL");
		Assert.notNull(channelId, "通道国标编号不可为NULL");
		// 获取可用的zlm
		Device device = deviceService.getDeviceByDeviceId(deviceId);
		Assert.notNull(device, "设备不存在");
		DeviceChannel channel = deviceChannelService.getOne(deviceId, channelId);
		Assert.notNull(channel, "通道不存在");
```

#### 步骤3-6: GB28181协议交互和流建立
WVP通过SIP协议与设备通信，建立RTP流传输通道。

#### 步骤7: 获取流信息
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

#### 步骤8: 返回流信息
```180:185:src/main/java/com/genersoft/iot/vmp/vmanager/bean/StreamContent.java
        if (streamInfo.getRtc() != null) {
            this.rtc = streamInfo.getRtc().getUrl();
        }
        if (streamInfo.getRtcs() != null) {
            this.rtcs = streamInfo.getRtcs().getUrl();
        }
```

## 五、前端WebRTC播放器使用

### 使用ZLMRTCClient播放

根据前端代码实现，WebRTC播放器的使用方式如下：

```40:78:web/src/views/common/rtcPlayer.vue
    play: function(url) {
      webrtcPlayer = new ZLMRTCClient.Endpoint({
        element: document.getElementById('webRtcPlayerBox'), // video 标签
        debug: true, // 是否打印日志
        zlmsdpUrl: url, // 流地址
        simulecast: false,
        useCamera: false,
        audioEnable: true,
        videoEnable: true,
        recvOnly: true,
        usedatachannel: false
      })
      webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ICE_CANDIDATE_ERROR, (e) => { // ICE 协商出错
        console.error('ICE 协商出错')
        this.eventcallbacK('ICE ERROR', 'ICE 协商出错')
      })

      webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_REMOTE_STREAMS, (e) => { // 获取到了远端流，可以播放
        console.log('播放成功', e.streams)
        this.eventcallbacK('playing', '播放成功')
      })

      webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_OFFER_ANWSER_EXCHANGE_FAILED, (e) => { // offer anwser 交换失败
        console.error('offer anwser 交换失败', e)
        this.eventcallbacK('OFFER ANSWER ERROR ', 'offer anwser 交换失败')
        if (e.code == -400 && e.msg == '流不存在') {
          console.log('流不存在')
          this.timer = setTimeout(() => {
            this.webrtcPlayer.close()
            this.play(url)
          }, 100)
        }
      })

      webrtcPlayer.on(ZLMRTCClient.Events.WEBRTC_ON_LOCAL_STREAM, (s) => { // 获取到了本地流
        // document.getElementById('selfVideo').srcObject=s;
        this.eventcallbacK('LOCAL STREAM', '获取到了本地流')
      })
    },
```

### 播放器参数说明
- `element`: video标签的DOM元素
- `zlmsdpUrl`: WebRTC流地址（从API返回的rtc或rtcs字段）
- `recvOnly`: 设置为true，表示只接收流（播放模式）
- `audioEnable`: 是否启用音频
- `videoEnable`: 是否启用视频

## 六、WebRTC地址生成规则

根据代码实现，WebRTC地址的生成规则如下：

```127:148:web/src/views/streamPush/buildPushStreamUrl.vue
    rtc(){
      if (!this.mediaServer || !this.stream || !this.app) {
        return ''
      }
      if (this.callId) {
        return `http://${this.mediaServer.streamIp}:${this.mediaServer.httpPort}/index/api/webrtc?app=${this.app}&stream=${this.stream}&callId=${this.callId}&sign=${this.sign}`
      }else {
        return `http://${this.mediaServer.streamIp}:${this.mediaServer.httpPort}/index/api/webrtc?app=${this.app}&stream=${this.stream}&sign=${this.sign}`
      }

    },
    rtcs(){
      if (!this.mediaServer || !this.stream || !this.app) {
        return ''
      }
      if (this.callId) {
        return `https://${this.mediaServer.streamIp}:${this.mediaServer.httpSSlPort}/index/api/webrtc?app=${this.app}&stream=${this.stream}&callId=${this.callId}&sign=${this.sign}`
      }else {
        return `https://${this.mediaServer.streamIp}:${this.mediaServer.httpSSlPort}/index/api/webrtc?app=${this.app}&stream=${this.stream}&sign=${this.sign}`
      }

    }
```

## 七、注意事项

1. **WebRTC功能需要ZLMediaKit支持**: 
   
   WebRTC功能需要ZLMediaKit流媒体服务器在编译时启用WebRTC支持。默认情况下，ZLMediaKit可能未启用WebRTC功能，需要重新编译流媒体服务器。
   
   **编译步骤**：
   
   - 参考官方文档：[zlm启用webrtc编译指南](https://github.com/ZLMediaKit/ZLMediaKit/wiki/zlm%E5%90%AF%E7%94%A8webrtc%E7%BC%96%E8%AF%91%E6%8C%87%E5%8D%97)
   
   - 关键步骤（以Linux为例）：
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
   
   - 编译完成后，确保ZLMediaKit的配置文件中启用了WebRTC相关端口配置
   
   - 验证WebRTC功能是否启用：访问 `http://{流媒体IP}:{httpPort}/index/api/getServerConfig`，检查返回的配置中是否包含WebRTC相关配置
   
   **重要提示**：如果ZLMediaKit未启用WebRTC功能，调用WebRTC播放接口会失败，返回"流不存在"或连接错误。请确保在部署前完成WebRTC功能的编译和配置。

2. **鉴权**: 如果流媒体服务器启用了签名验证，需要在URL中包含`sign`参数

3. **callId参数**: 某些场景下可能需要传递`callId`参数用于鉴权，特别是在推流场景

4. **HTTPS支持**: 如果使用HTTPS（rtcs），需要确保流媒体服务器配置了SSL证书

5. **超时处理**: 播放接口是异步的，使用DeferredResult实现，需要设置合理的超时时间

6. **流不存在处理**: 如果流尚未建立，WebRTC连接会失败，前端需要实现重试机制

## 八、相关API接口

### 停止播放
```
GET /api/play/stop/{deviceId}/{channelId}
```

### 获取流信息（通过app和stream）
```
GET /api/media/stream_info_by_app_and_stream?app={app}&stream={stream}
```

### 获取推流播放地址
```
GET /api/media/getPlayUrl?app={app}&stream={stream}
```

## 九、总结

WebRTC流媒体的外部调用流程可以概括为：
1. 调用WVP播放接口启动流
2. WVP通过GB28181协议与设备建立连接
3. 设备推送RTP流到流媒体服务器
4. 流媒体服务器转码并提供WebRTC服务
5. WVP返回包含WebRTC地址的流信息
6. 前端使用WebRTC播放器连接到流媒体服务器进行播放

整个过程涉及WVP平台、GB28181设备、ZLMediaKit流媒体服务器和前端播放器四个组件的协同工作。

