# MySQL 连接问题修复说明

## 🔍 问题诊断

**错误信息：**
```
Caused by: com.mysql.cj.exceptions.CJCommunicationsException: Communications link failure
Caused by: java.net.ConnectException: Connection refused
```

**原因：**
1. ✅ **已修复**: 配置文件中的 MySQL 密码错误（`123456` → `root`）
2. ⚠️ **需要检查**: MySQL 容器的端口映射可能未启用

## ✅ 已修复

已更新 `src/main/resources/application-dev.yml` 中的 MySQL 密码：
- 从 `password: 123456` 
- 改为 `password: root`（与 Docker 容器配置一致）

## 🔧 需要执行的步骤

### 步骤 1: 检查 MySQL 容器端口映射

```bash
docker ps | grep mysql
```

如果端口映射显示为空或没有 `0.0.0.0:3306->3306/tcp`，需要重新启动容器。

### 步骤 2: 重新启动 MySQL 容器（如果需要）

**选项 A: 如果使用 docker-compose**

编辑 `docker/docker-compose.yml`，取消注释端口映射：

```yaml
ports:
  - 3306:3306
```

然后重启：
```bash
cd docker
docker-compose restart polaris-mysql
```

**选项 B: 如果单独运行 MySQL 容器**

停止并重新启动容器，启用端口映射：

```bash
docker stop alldata-mysql
docker rm alldata-mysql
docker run -d --name alldata-mysql \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=wvp \
  -p 3306:3306 \
  mysql:8
```

### 步骤 3: 验证连接

```bash
# 测试端口连接
nc -zv 127.0.0.1 3306

# 测试数据库连接
mysql -h 127.0.0.1 -P 3306 -uroot -proot -e "SHOW DATABASES;"
```

### 步骤 4: 重启 WVP-Pro

修复配置后，重启 WVP-Pro 服务：

```bash
# 停止当前服务
kill $(lsof -ti:18080)

# 重新启动
cd /Users/andyapple/Downloads/wvp-GB28181-pro
nohup java -jar -Dspring.profiles.active=dev \
  -Dfile.encoding=UTF-8 \
  -Xms512m -Xmx2048m \
  target/wvp-pro-2.7.4-12111153.jar \
  > logs/wvp-startup.log 2>&1 &
```

## 📋 配置文件位置

- **主配置文件**: `src/main/resources/application-dev.yml`
- **Docker Compose 配置**: `docker/docker-compose.yml`

## ✅ 验证修复

启动后检查日志：

```bash
tail -f logs/wvp-startup.log
```

应该看到成功连接到数据库的消息，而不是连接错误。







