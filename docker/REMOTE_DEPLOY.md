# 远程服务器部署指南

## 前置条件

1. 远程服务器已安装 Docker 和 Docker Compose
2. 镜像已推送到远程服务器（位于 `/home/wvp/wvp-images.tar`）

## 快速开始

### 1. 加载镜像（如果还未加载）

```bash
ssh root@172.31.127.47
cd /home/wvp
docker load -i wvp-images.tar
```

### 2. 创建部署目录

```bash
mkdir -p /home/wvp/docker
cd /home/wvp/docker
```

### 3. 上传配置文件

将以下文件上传到 `/home/wvp/docker/` 目录：
- `docker-compose-remote.yml`
- `start-remote.sh`
- `media/config.ini`（可选，脚本会自动创建默认配置）
- `wvp/wvp/application.yml`（必需，需要从项目复制）

### 4. 配置环境变量

编辑 `.env` 文件（脚本会自动创建，但需要配置SIP相关参数）：

```bash
# 编辑 .env 文件
vi .env
```

重要配置项：
- `SIP_Domain`: SIP域
- `SIP_Id`: SIP ID
- `SIP_Password`: SIP密码
- `Stream_IP`: 流媒体IP地址（默认：172.31.127.47）
- `SDP_IP`: SDP IP地址（默认：172.31.127.47）

### 5. 启动服务

```bash
chmod +x start-remote.sh
./start-remote.sh
```

## 服务说明

启动后会有以下4个服务：

1. **polaris-redis** - Redis缓存服务
2. **polaris-mysql** - MySQL数据库服务
3. **polaris-media** - ZLMediaKit流媒体服务器
4. **polaris-wvp** - WVP-Pro视频平台服务

## 端口说明

| 端口 | 协议 | 服务 | 说明 |
|------|------|------|------|
| 18978 | TCP | WVP | Web界面和API |
| 8116 | UDP/TCP | WVP | SIP端口（GB28181） |
| 8080 | TCP | Media | 流媒体HTTP服务 |
| 10935 | TCP/UDP | Media | RTMP收流端口 |
| 5540 | TCP/UDP | Media | RTSP收流端口 |
| 10000 | TCP/UDP | Media | RTP收流端口 |
| 8001 | TCP/UDP | Media | WebRTC端口 |

## 常用命令

### 查看服务状态
```bash
docker-compose -f docker-compose-remote.yml ps
```

### 查看日志
```bash
# 查看所有服务日志
docker-compose -f docker-compose-remote.yml logs -f

# 查看特定服务日志
docker-compose -f docker-compose-remote.yml logs -f polaris-wvp
```

### 停止服务
```bash
docker-compose -f docker-compose-remote.yml down
```

### 重启服务
```bash
docker-compose -f docker-compose-remote.yml restart
```

### 重启特定服务
```bash
docker-compose -f docker-compose-remote.yml restart polaris-wvp
```

## 数据库初始化

首次启动时，MySQL会自动创建数据库，但需要手动执行初始化SQL脚本。

如果需要初始化数据库：

```bash
# 复制SQL文件到容器
docker cp 初始化-mysql-2.7.4.sql polaris-mysql:/tmp/

# 进入MySQL容器
docker exec -it polaris-mysql bash

# 执行SQL
mysql -uroot -proot wvp < /tmp/初始化-mysql-2.7.4.sql
```

或者从外部执行：

```bash
docker exec -i polaris-mysql mysql -uroot -proot wvp < 初始化-mysql-2.7.4.sql
```

## 配置文件位置

- WVP配置: `./wvp/wvp/application.yml`
- 流媒体配置: `./media/config.ini`
- 环境变量: `./.env`
- 日志目录: `./logs/`
- 数据目录: `./volumes/`

## 故障排查

### 1. 服务无法启动

检查日志：
```bash
docker-compose -f docker-compose-remote.yml logs
```

### 2. 端口冲突

检查端口占用：
```bash
netstat -tulpn | grep -E "18978|8116|8080"
```

修改 `.env` 文件中的端口配置。

### 3. 数据库连接失败

检查MySQL容器状态：
```bash
docker exec -it polaris-mysql mysql -uroot -proot -e "SHOW DATABASES;"
```

### 4. 镜像不存在

确保镜像已加载：
```bash
docker images | grep -E "redis|mysql|zlmediakit|wvp-pro"
```

如果镜像不存在，执行：
```bash
docker load -i /home/wvp/wvp-images.tar
```

## 注意事项

1. 首次启动前，确保配置好 `.env` 文件中的SIP参数
2. 确保所需端口未被占用
3. 数据库初始化脚本需要手动执行（如果需要）
4. 日志文件保存在 `./logs/` 目录下
5. 视频录制文件保存在 `./volumes/video/` 目录下

