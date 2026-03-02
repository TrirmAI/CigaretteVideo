# 流媒体服务器日志分析报告

## 关键问题发现

### 1. Hook连接失败（主要问题）
```
hook http://127.0.0.1:18080/index/hook/on_server_keepalive 
failed[network err]:3(connection refused)
```
- **问题**：ZLMediaKit容器无法连接到WVP的Hook端点
- **原因**：容器内使用 `127.0.0.1` 无法访问宿主机上的WVP服务
- **影响**：导致所有Hook回调失败，包括 `on_publish`、`on_play` 等

### 2. RTP推流被禁止
```
禁止RTP推流:[network err]:3(connection refused)
RTP推流器(__defaultVhost__/rtp/06423868)断开
```
- **问题**：RTP推流被禁止
- **原因**：`on_publish` Hook调用失败，导致无法验证推流权限
- **流ID**：`06423868` (RTP流) vs `44011200001180000001_44011200001320000011` (WVP期望的流ID)

### 3. 播放流程状态
- ✅ WVP已发送点播请求
- ✅ SIP INVITE已发送
- ✅ 收到ACK确认
- ❌ RTP流未成功推送到ZLMediaKit
- ❌ Hook验证失败导致推流被禁止

## 根本原因

**Hook连接失败**是核心问题：
1. ZLMediaKit容器内使用 `127.0.0.1:18080` 无法访问宿主机上的WVP
2. 当设备尝试推送RTP流时，ZLMediaKit调用 `on_publish` Hook验证
3. Hook调用失败，ZLMediaKit拒绝RTP推流
4. 导致播放失败

## 解决方案

### 方案1：修改Hook地址为宿主机IP（推荐）
将 `docker/media/config.ini` 中的所有Hook地址从 `127.0.0.1` 改为 `172.31.127.42`

### 方案2：使用host网络模式
修改docker-compose.yml，让容器使用host网络模式

### 方案3：将WVP也部署到Docker网络
将WVP部署为Docker容器，使用Docker网络内部通信

## 当前状态

- **WVP服务**：正常运行（端口18080）
- **ZLMediaKit服务**：正常运行（端口8080）
- **Hook连接**：失败（connection refused）
- **RTP推流**：被禁止
- **播放状态**：失败

## 下一步操作

1. 修复Hook连接问题（修改Hook地址为宿主机IP）
2. 重启ZLMediaKit容器
3. 重新测试播放功能
4. 验证RTP流是否成功推送

