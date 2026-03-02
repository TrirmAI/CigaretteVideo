# WVP-Pro Docker 镜像构建和使用说明

## 概述

本文档说明如何将 WVP-Pro 服务构建为 Docker 镜像，以及如何使用 Docker Compose 部署完整的 WVP-Pro 系统。

## 端口说明

WVP-Pro 服务需要暴露以下端口：

| 端口 | 协议 | 用途 | 必选 |
|------|------|------|------|
| 18978 | TCP | HTTP 服务端口（Web 界面和 API） | 是 |
| 8116 | UDP/TCP | SIP 端口（GB28181 协议） | 是 |
| 21078 | UDP/TCP | JT1078 端口（如果启用） | 否 |

## 构建 Docker 镜像

### 方法一：使用 Docker Compose（推荐）

在项目根目录执行：

```bash
cd docker
docker-compose build polaris-wvp
```

### 方法二：直接使用 Dockerfile

```bash
# 在项目根目录执行
docker build -f docker/wvp/Dockerfile -t wvp-pro:latest .
```

### 方法三：使用构建脚本

```bash
cd docker/wvp
./build.sh
```

## 使用 Docker Compose 部署

### 1. 配置环境变量

创建 `.env` 文件（如果不存在），配置以下变量：

```bash
# SIP 配置
SIP_ShowIP=your-server-ip
SIP_Port=8116
SIP_Domain=3402000000
SIP_Id=34020000002000000001
SIP_Password=your-password

# 流媒体服务器配置
Stream_IP=your-server-ip
SDP_IP=your-server-ip

# 流媒体服务器端口
WebHttp=8080
MediaRtmp=10935
MediaRtsp=5540
MediaRtp=10000

# WVP HTTP 端口
WVP_HTTP_PORT=18978

# JT1078 端口（如果启用）
JT1078_Port=21078

# 录制配置
RecordSip=false
RecordPushLive=false
```

### 2. 启动服务

```bash
cd docker
docker-compose up -d
```

### 3. 查看日志

```bash
# 查看所有服务日志
docker-compose logs -f

# 查看 WVP 服务日志
docker-compose logs -f polaris-wvp
```

### 4. 停止服务

```bash
docker-compose down
```

## 单独运行 WVP 容器

如果只需要运行 WVP 服务（不依赖其他服务），可以使用以下命令：

```bash
docker run -d \
  --name wvp-pro \
  -p 18978:18978 \
  -p 8116:8116/udp \
  -p 8116:8116/tcp \
  -p 21078:21078/udp \
  -p 21078:21078/tcp \
  -e REDIS_HOST=your-redis-host \
  -e REDIS_PORT=6379 \
  -e DATABASE_HOST=your-mysql-host \
  -e DATABASE_PORT=3306 \
  -e DATABASE_USER=wvp_user \
  -e DATABASE_PASSWORD=wvp_password \
  -e ZLM_HOST=your-zlm-host \
  -e Stream_IP=your-server-ip \
  -e SDP_IP=your-server-ip \
  -e SIP_Port=8116 \
  -e SIP_Domain=3402000000 \
  -e SIP_Id=34020000002000000001 \
  -e SIP_Password=your-password \
  -v $(pwd)/docker/wvp/wvp:/opt/ylcx/wvp \
  -v $(pwd)/docker/logs/wvp:/opt/wvp/logs \
  wvp-pro:latest
```

## 镜像结构

构建后的镜像包含以下内容：

```
/opt/wvp/
├── wvp.jar                    # WVP 主程序
└── logs/                      # 日志目录

/opt/ylcx/wvp/
├── application.yml            # 主配置文件
├── application-base.yml       # 基础配置
└── application-docker.yml    # Docker 环境配置
```

## 配置文件说明

WVP 的配置文件位于 `/opt/ylcx/wvp/` 目录：

- `application.yml`: 主配置文件，会加载其他配置文件
- `application-base.yml`: 基础配置
- `application-docker.yml`: Docker 环境专用配置，通过环境变量覆盖

### 环境变量配置

Docker 容器支持通过环境变量配置以下参数：

| 环境变量 | 说明 | 默认值 |
|---------|------|--------|
| `REDIS_HOST` | Redis 服务器地址 | 127.0.0.1 |
| `REDIS_PORT` | Redis 端口 | 6379 |
| `DATABASE_HOST` | MySQL 服务器地址 | 127.0.0.1 |
| `DATABASE_PORT` | MySQL 端口 | 3306 |
| `DATABASE_USER` | MySQL 用户名 | root |
| `DATABASE_PASSWORD` | MySQL 密码 | root |
| `ZLM_HOST` | ZLMediaKit 服务器地址 | 127.0.0.1 |
| `ZLM_HOOK_HOST` | ZLMediaKit Hook 回调地址 | 127.0.0.1 |
| `ZLM_SERCERT` | ZLMediaKit Secret | - |
| `Stream_IP` | 流地址 IP | - |
| `SDP_IP` | SDP IP | - |
| `SIP_Port` | SIP 端口 | 8116 |
| `SIP_Domain` | SIP 域 | 3402000000 |
| `SIP_Id` | SIP ID | - |
| `SIP_Password` | SIP 密码 | - |
| `MediaHttp` | 流媒体 HTTP 端口 | 8080 |
| `MediaRtmp` | RTMP 端口 | 10935 |
| `MediaRtsp` | RTSP 端口 | 5540 |
| `MediaRtp` | RTP 端口 | 10000 |
| `RecordSip` | 是否录制 SIP | false |
| `RecordPushLive` | 是否录制推流 | false |

## 健康检查

镜像包含健康检查功能，每 30 秒检查一次 HTTP 服务是否正常：

```bash
# 查看容器健康状态
docker ps
# 或
docker inspect wvp-pro | grep Health -A 10
```

## 常见问题

### 1. 构建失败：Maven 下载依赖超时

**解决方案**：
- 检查网络连接
- 使用国内 Maven 镜像（已在 pom.xml 中配置阿里云镜像）

### 2. 容器启动失败：无法连接数据库

**解决方案**：
- 确保 MySQL 和 Redis 服务已启动
- 检查环境变量配置是否正确
- 检查网络连接（如果数据库在另一个容器中，确保在同一 Docker 网络中）

### 3. SIP 端口无法访问

**解决方案**：
- 确保端口映射正确：`-p 8116:8116/udp -p 8116:8116/tcp`
- 检查防火墙设置
- 确保 SIP 端口配置与映射端口一致

### 4. 流媒体服务器连接失败

**解决方案**：
- 检查 `ZLM_HOST` 环境变量是否正确
- 确保 ZLMediaKit 服务已启动
- 检查网络连接（如果 ZLM 在另一个容器中，使用容器名称而非 IP）

## 构建优化

### 使用多阶段构建

Dockerfile 使用多阶段构建，分为：
1. **builder 阶段**：编译 Java 项目，生成 JAR 文件
2. **运行阶段**：只包含运行时需要的文件，减小镜像体积

### 使用 .dockerignore

项目根目录包含 `.dockerignore` 文件，排除不必要的文件，加快构建速度。

## 更新镜像

```bash
# 重新构建镜像
docker-compose build --no-cache polaris-wvp

# 重启服务
docker-compose up -d polaris-wvp
```

## 查看镜像信息

```bash
# 查看镜像大小
docker images wvp-pro

# 查看镜像详细信息
docker inspect wvp-pro:latest
```

## 注意事项

1. **端口映射**：确保宿主机端口未被占用
2. **配置文件**：修改配置文件后需要重启容器
3. **日志目录**：建议将日志目录挂载到宿主机，方便查看和备份
4. **数据持久化**：数据库和 Redis 数据需要持久化存储
5. **网络配置**：如果服务分布在多个容器，确保它们在同一 Docker 网络中

## 参考文档

- [Docker 官方文档](https://docs.docker.com/)
- [Docker Compose 文档](https://docs.docker.com/compose/)
- [WVP-Pro 部署文档](../doc/_content/introduction/deployment.md)

