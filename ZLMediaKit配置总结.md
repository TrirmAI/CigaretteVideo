# ZLMediaKit WebRTC配置总结

## 一、编译状态

✅ **WebRTC功能已成功编译**
- MediaServer可执行文件：`/Users/andyapple/Downloads/ZLMediaKit/release/darwin/Debug/MediaServer`
- WebRTC库：`libwebrtc.a` (106MB)
- 已链接：`libsrtp2.dylib`

## 二、配置文件位置

**主要配置文件**：`/Users/andyapple/Downloads/ZLMediaKit/conf/config.ini`

## 三、RTC配置项

### 已配置项

```ini
[rtc]
# 本机对rtc客户端的可见ip（已配置）
externIP=172.31.127.42

# RTC UDP服务器监听端口
port=8000

# RTC TCP服务器监听端口
tcpPort=8000

# STUN/TURN服务器端口
icePort=3478
iceTcpPort=3478

# TURN服务分配端口池
port_range=49152-65535

# 支持的编解码器
preferredCodecA=PCMA,PCMU,opus,mpeg4-generic
preferredCodecV=H264,H265,AV1,VP9,VP8
```

### 关键配置说明

1. **externIP**: 设置为 `172.31.127.42`，这是外部设备访问WebRTC流时使用的IP地址
2. **port**: RTC UDP端口，默认8000
3. **tcpPort**: RTC TCP端口，默认8000（UDP不通时使用）

## 四、WVP配置对应关系

**WVP配置文件**：`application-dev.yml`

```yaml
media:
  ip: 127.0.0.1              # WVP连接ZLMediaKit使用的IP
  stream-ip: 172.31.127.42   # 返回流地址时的IP（与RTC externIP一致）
  http-port: 8080            # ⚠️ 注意：ZLMediaKit默认是80端口
```

### 配置一致性检查

- ✅ **stream-ip** 与 **RTC externIP** 一致：`172.31.127.42`
- ⚠️ **http-port** 不一致：
  - WVP配置：`8080`
  - ZLMediaKit配置：`80`
  
  **建议**：如果MediaServer使用80端口，需要修改WVP配置中的`http-port`为`80`，或者修改MediaServer的HTTP端口为`8080`

## 五、启动MediaServer

### 启动命令

```bash
cd /Users/andyapple/Downloads/ZLMediaKit/release/darwin/Debug
./MediaServer -c ../../conf/config.ini -d
```

### 注意事项

1. **端口冲突**：如果遇到端口占用问题，需要：
   - 停止Docker中的MediaServer服务（如果存在）
   - 或修改配置文件中的端口设置

2. **验证启动**：启动后检查日志，确认：
   - HTTP API接口已启动（端口80）
   - WebRTC编解码器已加载（VP8, VP9, H264, H265等）
   - ICE Transport已初始化

## 六、验证WebRTC功能

### 1. 检查配置

```bash
curl "http://127.0.0.1:80/index/api/getServerConfig?secret=YOUR_SECRET" | jq '.rtc'
```

### 2. 测试WebRTC播放

通过WVP平台调用播放接口，返回的流信息中应包含：
- `rtc`: `http://172.31.127.42:80/index/api/webrtc?app=rtp&stream=xxx&type=play`
- `rtcs`: `https://172.31.127.42:443/index/api/webrtc?app=rtp&stream=xxx&type=play`

## 七、常见问题

### 问题1：端口冲突

**现象**：启动失败，提示"address already in use"

**解决**：
- 检查是否有其他MediaServer实例运行：`ps aux | grep MediaServer`
- 检查Docker服务：`docker ps | grep media`
- 修改配置文件中的端口设置

### 问题2：externIP配置

**现象**：WebRTC连接失败

**解决**：
- 确保`externIP`设置为外部可访问的IP地址
- 确保WVP配置中的`stream-ip`与`externIP`一致

### 问题3：HTTP端口不一致

**现象**：WVP无法连接MediaServer

**解决**：
- 修改WVP配置：`media.http-port: 80`
- 或修改MediaServer配置：`[http].port=8080`

## 八、下一步操作

1. ✅ 编译完成（WebRTC功能已启用）
2. ✅ RTC配置已更新（externIP已设置）
3. ⚠️ 需要解决端口冲突问题后启动MediaServer
4. ⚠️ 需要确认HTTP端口配置一致性
5. ⏳ 启动MediaServer并验证功能
6. ⏳ 通过WVP平台测试WebRTC播放功能

