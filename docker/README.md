# Docker 部署说明

## 快速开始

在当前目录下：

1. **直接运行**（使用已有镜像）：
   ```bash
   docker compose up -d
   ```

2. **重新构建并运行**（强制重新构建所有服务的镜像并删除旧容器）：
   ```bash
   docker compose up -d --build --force-recreate
   ```

3. **只构建 WVP 服务镜像**：
   ```bash
   ./build-wvp.sh
   # 或
   docker compose build polaris-wvp
   ```

## 配置文件

- **`.env`**: 环境变量配置文件，配置好后其他配置会自动联动
- **`docker-compose.yml`**: Docker Compose 配置文件，定义所有服务

## 构建脚本

- **`build.sh`**: 以日期为 tag 构建镜像，推送到指定的容器注册表内（Windows 下可以使用 `Git Bash` 运行）
- **`build-wvp.sh`**: 快速构建 WVP-Pro 服务镜像

## WVP-Pro Docker 镜像

WVP-Pro 服务已配置为 Docker 镜像，包含以下特性：

- ✅ 多阶段构建，优化镜像大小
- ✅ 健康检查支持
- ✅ 完整的端口暴露（HTTP、SIP、JT1078）
- ✅ 环境变量配置支持
- ✅ 日志目录挂载

### 端口说明

| 端口 | 协议 | 用途 |
|------|------|------|
| 18978 | TCP | HTTP 服务（Web 界面和 API） |
| 8116 | UDP/TCP | SIP 端口（GB28181 协议） |
| 21078 | UDP/TCP | JT1078 端口（如果启用） |

详细说明请参考：[WVP_DOCKER_BUILD.md](./WVP_DOCKER_BUILD.md)

## 服务说明

- **polaris-redis**: Redis 服务
- **polaris-mysql**: MySQL 数据库服务
- **polaris-media**: ZLMediaKit 流媒体服务器
- **polaris-wvp**: WVP-Pro 视频平台服务
- **polaris-nginx**: Nginx 反向代理服务

## 注意事项

1. 首次运行前，请确保配置好 `.env` 文件
2. 确保所需端口未被占用
3. 数据库初始化脚本会自动执行（首次启动时）
4. 日志文件会保存在 `./logs/` 目录下