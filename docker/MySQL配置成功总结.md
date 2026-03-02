# WVP使用MySQL数据库配置成功总结

## 问题解决

### 最终解决方案

使用**环境变量直接配置数据库连接**，绕过配置文件加载顺序问题。

### 关键环境变量

```bash
-e SPRING_DATASOURCE_URL='jdbc:mysql://polaris-mysql:3306/wvp?useUnicode=true&characterEncoding=UTF8&rewriteBatchedStatements=true&serverTimezone=PRC&useSSL=false&allowMultiQueries=true&allowPublicKeyRetrieval=true'
-e SPRING_DATASOURCE_USERNAME=wvp_user
-e SPRING_DATASOURCE_PASSWORD=wvp_password
-e SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver
-e SPRING_DATASOURCE_TYPE=com.zaxxer.hikari.HikariDataSource
```

### 验证结果

1. **数据库连接成功**
   - 日志显示：`HikariPool-1 - Added connection com.mysql.cj.jdbc.ConnectionImpl@...`
   - 这是MySQL连接，不再是H2内存数据库

2. **静态资源目录配置成功**
   - 日志显示：`使用外部静态资源目录: /opt/wvp/static/static/`
   - WebMvcConfig已正确加载

## 启动命令

完整的WVP容器启动命令：

```bash
docker run -d \
  --name polaris-wvp \
  --network media-net \
  --restart always \
  -p 18978:18978/tcp \
  -p 8116:8116/udp -p 8116:8116/tcp \
  -p 21078:21078/tcp -p 21078:21078/udp \
  -v /home/wvp/docker/wvp/config:/opt/wvp/config \
  -v /home/wvp/docker/wvp/wvp/:/opt/ylcx/wvp/ \
  -v /home/wvp/docker/logs/wvp:/opt/wvp/logs/ \
  -v /home/wvp/docker/volumes/wvp/static:/opt/wvp/static \
  -e TZ=Asia/Shanghai \
  -e Stream_IP=172.31.127.47 \
  -e SDP_IP=172.31.127.47 \
  -e ZLM_HOOK_HOST=polaris-wvp \
  -e ZLM_HOST=polaris-media \
  -e ZLM_SERCERT=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR \
  -e MediaHttp=8080 \
  -e MediaRtmp=10935 \
  -e MediaRtsp=5540 \
  -e MediaRtp=10000 \
  -e REDIS_HOST=polaris-redis \
  -e REDIS_PORT=6379 \
  -e SPRING_DATASOURCE_URL='jdbc:mysql://polaris-mysql:3306/wvp?useUnicode=true&characterEncoding=UTF8&rewriteBatchedStatements=true&serverTimezone=PRC&useSSL=false&allowMultiQueries=true&allowPublicKeyRetrieval=true' \
  -e SPRING_DATASOURCE_USERNAME=wvp_user \
  -e SPRING_DATASOURCE_PASSWORD=wvp_password \
  -e SPRING_DATASOURCE_DRIVER_CLASS_NAME=com.mysql.cj.jdbc.Driver \
  -e SPRING_DATASOURCE_TYPE=com.zaxxer.hikari.HikariDataSource \
  -e DATABASE_HOST=polaris-mysql \
  -e DATABASE_PORT=3306 \
  -e DATABASE_USER=wvp_user \
  -e DATABASE_PASSWORD=wvp_password \
  -e SIP_ShowIP=172.31.127.47 \
  -e SIP_Port=8116 \
  -e SIP_Domain=4101050000 \
  -e SIP_Id=41010500002000000001 \
  -e SIP_Password=12345678 \
  -e RecordSip=true \
  -e RecordPushLive=true \
  -e JT1078_ENABLE=true \
  -e JT1078_PORT=21078 \
  -e JT1078_PASSWORD=admin123 \
  localhost/wvp-pro:latest \
  java -Xms512m -Xmx1024m \
    -XX:+HeapDumpOnOutOfMemoryError \
    -XX:HeapDumpPath=/opt/wvp/logs/ \
    -jar /opt/wvp/wvp.jar \
    --spring.config.location=file:/opt/ylcx/wvp/
```

## 配置文件修改

### Dockerfile.simple

已更新启动命令，使用配置文件目录：

```dockerfile
ENTRYPOINT ["java", \
  "-Xms512m", \
  "-Xmx1024m", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:HeapDumpPath=/opt/wvp/logs/", \
  "-jar", \
  "/opt/wvp/wvp.jar", \
  "--spring.config.location=file:/opt/ylcx/wvp/"]
```

### application-docker.yml

配置文件中的数据库配置仍然保留，但环境变量优先级更高，会覆盖配置文件中的设置。

## 下一步

1. ✅ MySQL数据库连接已成功
2. ✅ 静态资源目录配置已成功
3. ⏳ 等待服务完全启动
4. ⏳ 验证HTTP服务可访问
5. ⏳ 更新启动脚本以包含环境变量配置

## 注意事项

- 环境变量的优先级高于配置文件
- 使用 `SPRING_DATASOURCE_*` 环境变量可以直接覆盖Spring Boot的数据源配置
- 配置文件路径使用 `file:/opt/ylcx/wvp/` 让Spring Boot自动加载该目录下的所有配置文件

