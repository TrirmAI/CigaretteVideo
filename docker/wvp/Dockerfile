FROM eclipse-temurin:21-jdk AS builder

# 支持代理配置（通过构建参数传递）
ARG http_proxy
ARG https_proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY
ARG no_proxy
ARG NO_PROXY

# 设置代理环境变量（如果提供）
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV no_proxy=${no_proxy}
ENV NO_PROXY=${NO_PROXY}

# 暴露 WVP 服务所需的所有端口
# HTTP 服务端口（Docker 环境默认 18978，可通过环境变量修改）
EXPOSE 18978/tcp
# SIP 端口（GB28181 协议，UDP 和 TCP）
EXPOSE 8116/tcp
EXPOSE 8116/udp
# JT1078 端口（如果启用）
EXPOSE 21078/tcp
EXPOSE 21078/udp

#RUN apt-get update && \
         #DEBIAN_FRONTEND="noninteractive" \
         #apt-get install -y --no-install-recommends \
         #wget \
         #cmake \
         #maven \
         #git \
         #ca-certificates \
         #tzdata \
         #curl \
         #libpcre3 \
         #libpcre3-dev \
         #zlib1g-dev \
         #openssl \
         #libssl-dev \
         #gdb && \
         #apt-get autoremove -y && \
         #apt-get clean -y && \
         #rm -rf /var/lib/apt/lists/*

## install jdk1.8
#RUN mkdir -p /opt/download
#WORKDIR /opt/download
#RUN if [ "$Platfrom" = "arm64" ]; \
    #then \
        #wget https://polaris-tian-generic.pkg.coding.net/qt/autopliot/jdk-8u411-linux-aarch64.tar.gz?version=latest --no-check-certificate -O jdk-8.tar.gz && \
        #tar -zxvf /opt/download/jdk-8.tar.gz -C /usr/local/ --transform 's/jdk1.8.0_411/java/' && \
        #rm /opt/download/jdk-8.tar.gz; \
    #else \
        #wget https://polaris-tian-generic.pkg.coding.net/qt/autopliot/jdk-8u202-linux-x64.tar.gz?version=latest --no-check-certificate -O jdk-8.tar.gz && \
        #tar -zxvf /opt/download/jdk-8.tar.gz -C /usr/local/ --transform 's/jdk1.8.0_202/java/' && \
        #rm /opt/download/jdk-8.tar.gz; \
    #fi

#ENV JAVA_HOME /usr/local/java/
#ENV JRE_HOME ${JAVA_HOME}/jre
#ENV CLASSPATH .:${JAVA_HOME}/lib:${JRE_HOME}/lib 
#ENV PATH ${JAVA_HOME}/bin:$PATH 

RUN java -version && javac -version

# 配置 apt 使用国内镜像源（阿里云镜像）
RUN sed -i 's|http://ports.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || \
    sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list

# 配置 apt 使用代理（如果设置了代理）
# 同时配置超时和重试，以及错误处理
RUN if [ -n "$http_proxy" ]; then \
        echo "Acquire::http::Proxy \"$http_proxy\";" > /etc/apt/apt.conf.d/proxy.conf && \
        if [ -n "$https_proxy" ]; then \
            echo "Acquire::https::Proxy \"$https_proxy\";" >> /etc/apt/apt.conf.d/proxy.conf; \
        else \
            echo "Acquire::https::Proxy \"$http_proxy\";" >> /etc/apt/apt.conf.d/proxy.conf; \
        fi && \
        echo "Acquire::http::Timeout \"60\";" >> /etc/apt/apt.conf.d/proxy.conf && \
        echo "Acquire::http::Retries \"3\";" >> /etc/apt/apt.conf.d/proxy.conf && \
        echo "Acquire::https::Timeout \"60\";" >> /etc/apt/apt.conf.d/proxy.conf && \
        echo "Acquire::https::Retries \"3\";" >> /etc/apt/apt.conf.d/proxy.conf; \
    fi

# 配置 Maven 使用国内镜像源和代理
RUN mkdir -p /root/.m2 && \
    echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > /root/.m2/settings.xml && \
    echo "<settings>" >> /root/.m2/settings.xml && \
    echo "  <mirrors>" >> /root/.m2/settings.xml && \
    echo "    <mirror>" >> /root/.m2/settings.xml && \
    echo "      <id>aliyunmaven</id>" >> /root/.m2/settings.xml && \
    echo "      <mirrorOf>central</mirrorOf>" >> /root/.m2/settings.xml && \
    echo "      <name>阿里云公共仓库</name>" >> /root/.m2/settings.xml && \
    echo "      <url>https://maven.aliyun.com/repository/public</url>" >> /root/.m2/settings.xml && \
    echo "    </mirror>" >> /root/.m2/settings.xml && \
    echo "  </mirrors>" >> /root/.m2/settings.xml && \
    if [ -n "$http_proxy" ]; then \
        PROXY_HOST=$(echo $http_proxy | sed 's|http://||' | sed 's|https://||' | cut -d: -f1) && \
        PROXY_PORT=$(echo $http_proxy | sed 's|http://||' | sed 's|https://||' | cut -d: -f2 | cut -d/ -f1) && \
        echo "  <proxies>" >> /root/.m2/settings.xml && \
        echo "    <proxy>" >> /root/.m2/settings.xml && \
        echo "      <id>proxy</id>" >> /root/.m2/settings.xml && \
        echo "      <active>true</active>" >> /root/.m2/settings.xml && \
        echo "      <protocol>http</protocol>" >> /root/.m2/settings.xml && \
        echo "      <host>${PROXY_HOST}</host>" >> /root/.m2/settings.xml && \
        echo "      <port>${PROXY_PORT}</port>" >> /root/.m2/settings.xml && \
        echo "    </proxy>" >> /root/.m2/settings.xml && \
        echo "  </proxies>" >> /root/.m2/settings.xml; \
    fi && \
    echo "</settings>" >> /root/.m2/settings.xml

RUN apt-get update && \
    apt-get install -y --fix-missing --allow-unauthenticated maven 2>&1 | tee /tmp/apt-install.log || \
    (echo "第一次安装失败，重试..." && sleep 10 && apt-get update && apt-get install -y --fix-missing --allow-unauthenticated maven 2>&1 | tee -a /tmp/apt-install.log || \
     (echo "第二次安装失败，再次重试..." && sleep 10 && apt-get update && apt-get install -y --fix-missing --allow-unauthenticated maven)) && \
    rm -rf /var/lib/apt/lists/* && \
    mvn -version || (echo "Maven安装可能有问题，但继续构建..." && true)
    

COPY . /build
WORKDIR /build
RUN ls && mvn clean package -Dmaven.test.skip=true
WORKDIR /build/target
#ȷ���ļ���һ��
RUN mv wvp-pro-*.jar wvp.jar


FROM eclipse-temurin:21-jdk

# 设置时区
ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# 创建工作目录
RUN mkdir -p /opt/wvp /opt/ylcx/wvp /opt/wvp/logs
WORKDIR /opt/wvp

# 从构建阶段复制 JAR 文件
COPY --from=builder /build/target/wvp.jar /opt/wvp/wvp.jar

# 复制配置文件
COPY ./docker/wvp/wvp /opt/ylcx/wvp

# 设置工作目录为 /opt/ylcx（与配置文件路径一致）
WORKDIR /opt/ylcx

# 安装 curl 用于健康检查
# 配置 apt 使用国内镜像源
RUN sed -i 's|http://ports.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list.d/ubuntu.sources 2>/dev/null || \
    sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list 2>/dev/null || \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble main restricted universe multiverse" > /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-updates main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-backports main restricted universe multiverse" >> /etc/apt/sources.list && \
    echo "deb http://mirrors.aliyun.com/ubuntu/ noble-security main restricted universe multiverse" >> /etc/apt/sources.list

RUN apt-get update && \
    apt-get install -y --fix-missing curl 2>&1 | tee /tmp/apt-install.log || \
    (echo "第一次安装失败，重试..." && sleep 10 && apt-get update && apt-get install -y --fix-missing curl 2>&1 | tee -a /tmp/apt-install.log || \
     (echo "第二次安装失败，再次重试..." && sleep 10 && apt-get update && apt-get install -y --fix-missing curl)) && \
    rm -rf /var/lib/apt/lists/*

# 健康检查（检查 HTTP 服务是否正常）
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD curl -f http://localhost:18978/api/user/login || exit 1

# 暴露端口
EXPOSE 18978/tcp
EXPOSE 8116/tcp
EXPOSE 8116/udp
EXPOSE 21078/tcp
EXPOSE 21078/udp

# 启动 WVP 服务
ENTRYPOINT ["java", \
  "-Xms512m", \
  "-Xmx1024m", \
  "-XX:+HeapDumpOnOutOfMemoryError", \
  "-XX:HeapDumpPath=/opt/wvp/logs/", \
  "-jar", \
  "/opt/wvp/wvp.jar", \
  "--spring.config.location=/opt/ylcx/wvp/application.yml"]



#RUN mkdir -p /opt/wvp
#WORKDIR /opt/wvp
#COPY ./wvp /opt/wvp
#
#WORKDIR /home
#RUN cd /home && \
    #git clone https://gitee.com/pan648540858/wvp-GB28181-pro.git
#
#RUN cd /home/wvp-GB28181-pro && \
    #mvn clean package -Dmaven.test.skip=true && \
    #cp /home/wvp-GB28181-pro/target/*.jar /opt/wvp/wvp.jar
#
#WORKDIR /opt/wvp
#ENTRYPOINT ["java", "-Xms512m", "-Xmx1024m", "-XX:+HeapDumpOnOutOfMemoryError", "-XX:HeapDumpPath=/opt/ylcx/", "-jar", "wvp.jar", "--spring.config.location=/opt/ylcx/wvp/application.yml"]