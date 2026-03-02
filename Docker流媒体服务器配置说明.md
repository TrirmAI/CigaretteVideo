# Docker流媒体服务器配置说明

## 一、配置完成状态

✅ **Docker容器已成功启动**
- 容器名称：`docker-polaris-media-1`
- 镜像：`zlmediakit/zlmediakit:master`
- 状态：运行中

## 二、端口配置

### 已映射的端口

| 服务 | 容器内端口 | 宿主机端口 | 协议 | 说明 |
|------|-----------|-----------|------|------|
| HTTP API | 80 | 8080 | TCP | WVP访问流媒体服务器 |
| WebRTC UDP | 8001 | 8001 | UDP | WebRTC数据传输 |
| WebRTC TCP | 8001 | 8001 | TCP | WebRTC TCP备用 |
| RTMP | 10935 | 10935 | TCP/UDP | RTMP推流 |
| RTSP | 5540 | 5540 | TCP/UDP | RTSP推流 |
| RTP代理 | 10000-10003 | 10000-10003 | TCP/UDP | RTP代理端口 |

## 三、RTC配置

### 配置文件位置
- 容器内：`/conf/config.ini`
- 宿主机：`/Users/andyapple/Downloads/wvp-GB28181-pro/docker/media/config.ini`

### 关键配置项

```ini
[rtc]
externIP=172.31.127.42    # 外部访问IP
port=8001                 # RTC UDP端口
tcpPort=8001              # RTC TCP端口
enableTurn=1              # 启用TURN服务
icePort=3478              # STUN/TURN端口
port_range=49152-65535    # TURN端口池
```

## 四、验证服务

### 1. 检查容器状态

```bash
docker ps | grep polaris-media
```

### 2. 查看日志

```bash
docker logs docker-polaris-media-1
```

### 3. 验证RTC配置

```bash
curl "http://127.0.0.1:8080/index/api/getServerConfig?secret=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR" | jq '.rtc'
```

### 4. 测试WebRTC地址

WebRTC播放地址格式：
```
http://172.31.127.42:8080/index/api/webrtc?app=rtp&stream=xxx&type=play
```

## 五、WVP配置对应

### application-dev.yml配置

```yaml
media:
  ip: 127.0.0.1              # Docker容器内访问使用
  stream-ip: 172.31.127.42   # 返回流地址时的IP（与RTC externIP一致）
  http-port: 8080            # HTTP端口（映射后的端口）
```

**注意**：
- `media.ip` 应该使用Docker容器名称 `polaris-media`（如果在docker-compose网络中）
- 或者使用 `127.0.0.1`（如果WVP也在宿主机上运行）
- `stream-ip` 必须与RTC的 `externIP` 一致

## 六、常用操作

### 启动服务

```bash
cd /Users/andyapple/Downloads/wvp-GB28181-pro/docker
docker-compose up -d polaris-media
```

### 停止服务

```bash
docker-compose stop polaris-media
```

### 重启服务

```bash
docker-compose restart polaris-media
```

### 查看日志

```bash
docker logs -f docker-polaris-media-1
```

### 进入容器

```bash
docker exec -it docker-polaris-media-1 /bin/bash
```

### 更新配置

1. 编辑配置文件：`docker/media/config.ini`
2. 重启容器：`docker-compose restart polaris-media`

## 七、WebRTC功能验证

### 1. 检查WebRTC是否启用

```bash
docker exec docker-polaris-media-1 ls -lh /opt/media/bin/MediaServer
```

### 2. 检查WebRTC库

```bash
docker exec docker-polaris-media-1 ldd /opt/media/bin/MediaServer | grep srtp
```

### 3. 测试WebRTC API

```bash
curl "http://127.0.0.1:8080/index/api/webrtc?app=test&stream=test&type=play"
```

## 八、故障排查

### 问题1：端口冲突

**现象**：容器启动失败，提示端口被占用

**解决**：
```bash
# 检查端口占用
lsof -i :8001
# 停止占用端口的进程
# 或修改docker-compose.yml中的端口映射
```

### 问题2：WebRTC连接失败

**检查项**：
1. `externIP` 是否正确设置为外部可访问的IP
2. 端口映射是否正确（8001:8001）
3. 防火墙是否开放8001端口
4. WVP配置中的`stream-ip`是否与`externIP`一致

### 问题3：配置文件未生效

**解决**：
1. 确认配置文件路径：`docker/media/config.ini`
2. 检查docker-compose.yml中的volume映射
3. 重启容器：`docker-compose restart polaris-media`

## 九、下一步操作

1. ✅ Docker容器已启动
2. ✅ RTC端口已配置为8001
3. ✅ externIP已设置为172.31.127.42
4. ⏳ 更新WVP配置，确保与Docker MediaServer配置一致
5. ⏳ 测试WebRTC播放功能

## 十、配置总结

- **WebRTC端口**：8001（UDP和TCP）
- **HTTP端口**：8080（映射自容器80端口）
- **外部IP**：172.31.127.42
- **配置文件**：`docker/media/config.ini`
- **容器名称**：`docker-polaris-media-1`

