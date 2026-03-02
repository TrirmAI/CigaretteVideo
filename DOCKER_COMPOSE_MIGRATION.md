# Docker Compose 统一管理迁移指南

## 📋 迁移概述

本指南将帮助您从独立的数据库/Redis 服务迁移到使用 Docker Compose 统一管理的服务。

## ⚠️ 重要提示

**在开始迁移之前，请确保：**
1. 已备份重要数据（MySQL 数据库、Redis 数据）
2. 已停止当前运行的 WVP 应用
3. 了解当前使用的数据库和 Redis 数据是否需要迁移

## 🔧 迁移步骤

### 步骤 1: 停止旧服务

停止当前占用端口的 Docker 容器：

```bash
# 停止并删除 alldata-mysql 容器（如果存在）
docker stop alldata-mysql
docker rm alldata-mysql

# 停止并删除 alldata-redis 容器（如果存在）
docker stop alldata-redis
docker rm alldata-redis
```

**注意：** 如果这些容器属于其他 docker-compose 项目，请使用对应的 docker-compose 命令停止：

```bash
# 如果这些容器是通过 docker-compose 启动的，请进入对应目录执行
cd /path/to/alldata-project
docker-compose down
```

### 步骤 2: 检查端口占用

确认端口已释放：

```bash
# 检查 MySQL 端口 (3306)
lsof -i :3306

# 检查 Redis 端口 (6379)
lsof -i :6379

# 检查流媒体 HTTP 端口 (8080)
lsof -i :8080
```

如果端口仍被占用，请找到对应的进程并停止。

### 步骤 3: 启动 Docker Compose 服务

进入 docker 目录并启动服务：

```bash
cd /Users/andyapple/Downloads/wvp-GB28181-pro/docker

# 启动所有服务（MySQL、Redis、流媒体服务器）
docker-compose up -d

# 查看服务状态
docker-compose ps

# 查看服务日志
docker-compose logs -f
```

### 步骤 4: 验证服务状态

```bash
# 检查 MySQL 是否正常
docker-compose exec polaris-mysql mysql -u wvp_user -pwvp_password -e "SHOW DATABASES;"

# 检查 Redis 是否正常
docker-compose exec polaris-redis redis-cli ping

# 检查流媒体服务器是否正常（访问 HTTP API）
curl http://127.0.0.1:8080/index/api/getServerConfig?secret=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR
```

### 步骤 5: 数据迁移（如需要）

如果您需要将旧数据库的数据迁移到新的 Docker MySQL：

```bash
# 1. 导出旧数据库数据
docker exec alldata-mysql mysqldump -u root -p123456 wvp > wvp_backup.sql

# 2. 导入到新数据库
docker-compose exec -T polaris-mysql mysql -u wvp_user -pwvp_password wvp < wvp_backup.sql
```

**注意：** 如果旧数据库的用户名密码不同，请相应调整命令。

### 步骤 6: 启动 WVP 应用

配置已更新为使用 Docker Compose 中的服务，现在可以启动 WVP 应用：

```bash
cd /Users/andyapple/Downloads/wvp-GB28181-pro

# 使用启动脚本
./start-services.sh
# 选择选项 2: 仅启动 WVP-Pro 服务

# 或直接启动
java -jar -Dspring.profiles.active=dev target/wvp-pro-*.jar
```

## 📝 配置变更说明

### 已修改的配置

1. **MySQL 连接配置** (`application-dev.yml`)
   - 用户名: `root` → `wvp_user`
   - 密码: `123456` → `wvp_password`
   - 地址: `127.0.0.1:3306` (保持不变，现在指向 Docker Compose 中的 MySQL)

2. **Redis 连接配置** (`application-dev.yml`)
   - 移除了密码配置（Docker Compose 中的 Redis 未设置密码）
   - 地址: `127.0.0.1:6379` (保持不变，现在指向 Docker Compose 中的 Redis)

3. **流媒体服务器配置** (`application-dev.yml`)
   - IP: `172.31.127.42` → `127.0.0.1` (本地 Docker 容器)
   - HTTP 端口: `8080` (保持不变，Docker 容器内 80 端口映射到宿主机 8080)
   - Secret: `5j76zqeppUp7mpsawXIGo5gLW1O6j7CR` (保持不变)

### Docker Compose 端口映射

- **MySQL**: `3306:3306` (已启用)
- **Redis**: `6379:6379` (已启用)
- **流媒体服务器 HTTP**: `8080:80` (已启用)
- **流媒体服务器 RTMP**: `10935:10935`
- **流媒体服务器 RTSP**: `5540:5540`
- **流媒体服务器 RTP**: `10000:10000`

## 🔍 故障排查

### 问题 1: 端口已被占用

**错误信息：** `Bind for 0.0.0.0:3306 failed: port is already allocated`

**解决方法：**
```bash
# 查找占用端口的进程
lsof -i :3306
# 停止对应的进程或容器
```

### 问题 2: MySQL 连接失败

**错误信息：** `Access denied for user 'wvp_user'@'172.x.x.x'`

**解决方法：**
1. 检查 Docker Compose 中的 MySQL 是否正常启动
2. 确认用户名密码是否正确：`wvp_user` / `wvp_password`
3. 检查 MySQL 用户权限：
```bash
docker-compose exec polaris-mysql mysql -u root -proot -e "SELECT User, Host FROM mysql.user WHERE User='wvp_user';"
```

### 问题 3: Redis 连接失败

**错误信息：** `Connection refused`

**解决方法：**
1. 检查 Redis 容器是否运行：`docker-compose ps polaris-redis`
2. 检查 Redis 日志：`docker-compose logs polaris-redis`
3. 测试 Redis 连接：`docker-compose exec polaris-redis redis-cli ping`

### 问题 4: 流媒体服务器无法访问

**错误信息：** `Connection refused` 或 `404 Not Found`

**解决方法：**
1. 检查流媒体服务器容器是否运行：`docker-compose ps polaris-media`
2. 检查端口映射：`docker-compose ps` 查看端口映射
3. 测试 API 访问：
```bash
curl http://127.0.0.1:8080/index/api/getServerConfig?secret=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR
```

## 📚 常用命令

```bash
# 启动所有服务
cd docker && docker-compose up -d

# 停止所有服务
cd docker && docker-compose down

# 查看服务状态
cd docker && docker-compose ps

# 查看服务日志
cd docker && docker-compose logs -f [service_name]

# 重启特定服务
cd docker && docker-compose restart polaris-mysql

# 进入容器
docker-compose exec polaris-mysql bash
docker-compose exec polaris-redis bash
docker-compose exec polaris-media bash
```

## ✅ 验证清单

迁移完成后，请确认：

- [ ] MySQL 容器正常运行 (`docker-compose ps polaris-mysql`)
- [ ] Redis 容器正常运行 (`docker-compose ps polaris-redis`)
- [ ] 流媒体服务器容器正常运行 (`docker-compose ps polaris-media`)
- [ ] WVP 应用可以连接到 MySQL
- [ ] WVP 应用可以连接到 Redis
- [ ] WVP 应用可以连接到流媒体服务器
- [ ] 可以通过浏览器访问 WVP 管理界面 (`http://localhost:18080`)
- [ ] 流媒体功能正常（可以播放视频流）

## 🆘 需要帮助？

如果遇到问题，请检查：
1. Docker 和 Docker Compose 版本是否满足要求
2. 端口是否被其他服务占用
3. 防火墙设置是否允许相关端口
4. 查看服务日志：`docker-compose logs -f`

