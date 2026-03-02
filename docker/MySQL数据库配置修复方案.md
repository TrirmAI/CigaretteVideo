# WVP使用MySQL数据库配置修复方案

## 问题分析

### 当前问题
1. **WVP服务连接到H2内存数据库而不是MySQL**
   - 日志显示：`jdbc:h2:mem:...`
   - 应该连接：`jdbc:mysql://polaris-mysql:3306/wvp`

2. **配置文件已正确设置**
   - `/opt/ylcx/wvp/application-docker.yml` 中已配置MySQL连接
   - 环境变量已正确传递：`DATABASE_HOST=polaris-mysql`

3. **根本原因**
   - Spring Boot配置文件加载顺序问题
   - JAR包内可能没有 `application-docker.yml`，导致使用了默认的H2配置
   - 或者外部配置文件没有被正确加载

## 解决方案

### 方案1：确保外部配置文件正确加载（推荐）

修改启动命令，明确指定配置文件路径：

```bash
--spring.config.location=file:/opt/ylcx/wvp/application.yml,file:/opt/ylcx/wvp/application-docker.yml
```

或者使用Spring Boot的配置文件目录方式：

```bash
--spring.config.location=file:/opt/ylcx/wvp/
```

### 方案2：在JAR包内包含正确的配置

重新构建JAR包，确保 `src/main/resources/application-docker.yml` 包含MySQL配置。

### 方案3：使用环境变量直接配置

在启动命令中直接指定数据库连接参数：

```bash
-e SPRING_DATASOURCE_URL=jdbc:mysql://polaris-mysql:3306/wvp?useUnicode=true&characterEncoding=UTF8&rewriteBatchedStatements=true&serverTimezone=PRC&useSSL=false&allowMultiQueries=true&allowPublicKeyRetrieval=true
-e SPRING_DATASOURCE_USERNAME=wvp_user
-e SPRING_DATASOURCE_PASSWORD=wvp_password
-e SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver
```

## 当前配置状态

### 配置文件位置
- 宿主机：`/home/wvp/docker/wvp/wvp/application-docker.yml`
- 容器内：`/opt/ylcx/wvp/application-docker.yml`

### 数据库配置
```yaml
spring:
    datasource:
        type: com.zaxxer.hikari.HikariDataSource
        driver-class-name: com.mysql.cj.jdbc.Driver
        url: jdbc:mysql://${DATABASE_HOST:polaris-mysql}:${DATABASE_PORT:3306}/wvp?useUnicode=true&characterEncoding=UTF8&rewriteBatchedStatements=true&serverTimezone=PRC&useSSL=false&allowMultiQueries=true&allowPublicKeyRetrieval=true
        username: ${DATABASE_USER:wvp_user}
        password: ${DATABASE_PASSWORD:wvp_password}
```

### 环境变量
- `DATABASE_HOST=polaris-mysql`
- `DATABASE_PORT=3306`
- `DATABASE_USER=wvp_user`
- `DATABASE_PASSWORD=wvp_password`

## 验证步骤

1. **检查配置文件**
   ```bash
   docker exec polaris-wvp cat /opt/ylcx/wvp/application-docker.yml | grep -A 10 datasource
   ```

2. **检查环境变量**
   ```bash
   docker exec polaris-wvp env | grep DATABASE
   ```

3. **检查数据库连接**
   ```bash
   docker logs polaris-wvp | grep "HikariPool.*Added connection"
   ```
   应该看到：`jdbc:mysql://polaris-mysql:3306/wvp` 而不是 `jdbc:h2:mem:...`

4. **检查MySQL连接**
   ```bash
   docker exec polaris-wvp ping -c 2 polaris-mysql
   ```

## 下一步行动

1. 修改Dockerfile或启动脚本，明确指定配置文件路径
2. 或者使用环境变量直接配置数据库连接
3. 重新启动服务并验证

