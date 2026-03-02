# WVP服务启动失败分析报告

## 问题概述

WVP服务启动失败，容器反复重启。

## 错误日志分析

### 核心错误

```
org.h2.jdbc.JdbcSQLSyntaxErrorException: Table "WVP_JT_TERMINAL" not found (this database is empty)
```

### 错误链

1. **JT1078服务初始化失败**
   - `jt1078ServiceImpl.init()` 方法执行失败
   - 尝试查询 `wvp_jt_terminal` 表
   - 表不存在导致初始化失败

2. **数据库连接问题**
   - **实际连接**：`jdbc:h2:mem:...` (H2内存数据库)
   - **应该连接**：`jdbc:mysql://polaris-mysql:3306/wvp` (MySQL)
   - **问题**：服务连接到了H2内存数据库而不是MySQL

3. **配置文件加载问题**
   - Spring Boot Profile: `docker` (正确)
   - 配置文件路径: `/opt/ylcx/wvp/application.yml` (正确)
   - **问题**：`application-docker.yml` 中的数据库配置可能没有被正确加载

## 根本原因

### 原因1：配置文件优先级问题

Spring Boot配置文件加载顺序：
1. JAR包内的 `application.yml`
2. JAR包内的 `application-docker.yml`
3. 外部配置文件 `/opt/ylcx/wvp/application.yml`
4. 外部配置文件 `/opt/ylcx/wvp/application-docker.yml`

**可能的问题**：
- JAR包内的 `application-docker.yml` 可能没有数据库配置
- 外部配置文件 `/opt/ylcx/wvp/application-docker.yml` 可能没有被正确加载
- Spring Boot可能使用了默认的H2数据库配置

### 原因2：Spring Boot自动配置

当Spring Boot检测到：
- 没有配置 `spring.datasource.url`
- 或者配置的URL无法连接
- 且classpath中有H2依赖

Spring Boot会自动创建一个H2内存数据库作为后备。

## 解决方案

### 方案1：确保外部配置文件正确加载（推荐）

检查并确保 `/opt/ylcx/wvp/application-docker.yml` 中的数据库配置正确：

```yaml
spring:
    datasource:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        url: jdbc:mysql://${DATABASE_HOST:127.0.0.1}:${DATABASE_PORT:3306}/wvp?useUnicode=true&characterEncoding=UTF8&rewriteBatchedStatements=true&serverTimezone=PRC&useSSL=false&allowMultiQueries=true&allowPublicKeyRetrieval=true
        username: ${DATABASE_USER:root}
        password: ${DATABASE_PASSWORD:root}
```

### 方案2：禁用H2自动配置

在 `application-docker.yml` 中添加：

```yaml
spring:
    autoconfigure:
        exclude:
            - org.springframework.boot.autoconfigure.h2.H2ConsoleAutoConfiguration
```

### 方案3：确保JAR包内包含正确的配置

重新构建JAR包，确保 `src/main/resources/application-docker.yml` 包含正确的数据库配置。

## 验证步骤

1. **检查配置文件**
   ```bash
   docker exec polaris-wvp cat /opt/ylcx/wvp/application-docker.yml | grep -A 8 datasource
   ```

2. **检查环境变量**
   ```bash
   docker exec polaris-wvp env | grep DATABASE
   ```

3. **检查实际数据库连接**
   ```bash
   docker logs polaris-wvp | grep "HikariPool.*Added connection"
   ```

4. **检查MySQL连接**
   ```bash
   docker exec polaris-wvp ping -c 2 polaris-mysql
   ```

## 当前状态

- ✅ MyBatis错误已修复（`queryListInCircleForH2`方法已添加）
- ❌ 数据库配置未生效（连接到H2而不是MySQL）
- ❌ JT1078服务初始化失败（因为H2数据库中没有表）
- ❌ 服务启动失败，容器反复重启

## 下一步行动

1. 检查并修复 `application-docker.yml` 配置文件
2. 确保环境变量正确传递
3. 验证MySQL服务可访问
4. 重新启动服务

