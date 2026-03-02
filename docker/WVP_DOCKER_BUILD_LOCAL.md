# WVP-Pro Docker 镜像构建说明（使用本地 JAR）

## 概述

本文档说明如何使用本地已编译的 JAR 文件快速构建 WVP-Pro Docker 镜像，无需在 Docker 中重新编译。

## 前置条件

1. 本地已编译 WVP-Pro JAR 文件（位于 `target/wvp-pro-*.jar`）
2. 已安装 Docker

## 快速开始

### 方法一：使用构建脚本（推荐）

```bash
cd docker
./build-wvp-local.sh
```

### 方法二：直接使用 Docker 命令

```bash
# 在项目根目录执行
docker build -f docker/wvp/Dockerfile.local -t wvp-pro:latest .
```

## 构建说明

### Dockerfile.local

`Dockerfile.local` 是专门用于使用本地 JAR 文件构建的 Dockerfile，特点：

- ✅ 不需要在 Docker 中编译（节省时间）
- ✅ 直接使用本地已编译的 JAR 文件
- ✅ 使用国内镜像源加速构建
- ✅ 包含健康检查功能
- ✅ 暴露所有必要端口

### 构建过程

1. 检查本地 JAR 文件是否存在
2. 使用 JDK 11 基础镜像
3. 复制本地 JAR 文件到镜像
4. 复制配置文件
5. 安装必要的工具（curl）
6. 配置健康检查
7. 暴露端口

## 端口说明

| 端口 | 协议 | 用途 |
|------|------|------|
| 18978 | TCP | HTTP 服务（Web 界面和 API） |
| 8116 | UDP/TCP | SIP 端口（GB28181 协议） |
| 21078 | UDP/TCP | JT1078 端口（如果启用） |

## 运行容器

### 使用 Docker 命令

```bash
docker run -d \
  --name wvp-pro \
  -p 18978:18978 \
  -p 8116:8116/udp \
  -p 8116:8116/tcp \
  -p 21078:21078/udp \
  -p 21078:21078/tcp \
  wvp-pro:latest
```

### 使用 Docker Compose

```bash
cd docker
docker-compose up -d polaris-wvp
```

## 注意事项

1. **JAR 文件位置**：确保 `target/wvp-pro-*.jar` 文件存在
2. **构建上下文**：必须在项目根目录执行构建命令
3. **.dockerignore**：已配置允许 `target/*.jar` 文件被包含
4. **配置文件**：配置文件位于 `docker/wvp/wvp/` 目录

## 与完整构建的区别

| 特性 | Dockerfile（完整构建） | Dockerfile.local（本地构建） |
|------|----------------------|---------------------------|
| 构建时间 | 较长（需要编译） | 较短（直接使用 JAR） |
| 网络要求 | 需要下载依赖 | 仅需基础镜像 |
| 适用场景 | CI/CD、无本地环境 | 本地开发、快速构建 |
| 镜像大小 | 较大（包含构建工具） | 较小（仅运行时） |

## 常见问题

### 1. 找不到 JAR 文件

**错误**：`未找到已编译的 JAR 文件`

**解决方案**：
```bash
# 先编译项目
mvn clean package -Dmaven.test.skip=true
```

### 2. COPY 失败

**错误**：`lstat /target: no such file or directory`

**解决方案**：
- 确保在项目根目录执行构建命令
- 检查 `.dockerignore` 是否排除了 `target/` 目录（应该允许 `!target/*.jar`）

### 3. 配置文件路径错误

**错误**：容器启动后找不到配置文件

**解决方案**：
- 确保 `docker/wvp/wvp/` 目录存在
- 检查配置文件路径是否正确

## 更新镜像

当本地 JAR 文件更新后，重新构建：

```bash
cd docker
./build-wvp-local.sh
```

或使用 Docker Compose：

```bash
docker-compose build --no-cache polaris-wvp
```

## 参考文档

- [WVP_DOCKER_BUILD.md](./WVP_DOCKER_BUILD.md) - 完整构建说明
- [README.md](./README.md) - Docker 部署说明

