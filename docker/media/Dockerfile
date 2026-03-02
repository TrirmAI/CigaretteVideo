FROM ubuntu:20.04 AS build

# 支持代理配置（通过构建参数传递）
ARG http_proxy
ARG https_proxy
ARG HTTP_PROXY
ARG HTTPS_PROXY

# 设置代理环境变量（如果提供）
ENV http_proxy=${http_proxy}
ENV https_proxy=${https_proxy}
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}

#shell,rtmp,rtsp,rtsps,http,rtp
EXPOSE 10935/tcp
EXPOSE 5540/tcp
EXPOSE 6080/tcp
EXPOSE 10000/udp
EXPOSE 10000/tcp
EXPOSE 8001/udp
EXPOSE 8001/tcp
EXPOSE 9000/udp

# 配置 apt 使用国内镜像源（阿里云镜像）
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list

# 配置 apt 使用代理（如果设置了代理）
RUN if [ -n "$http_proxy" ]; then \
        echo "Acquire::http::Proxy \"$http_proxy\";" > /etc/apt/apt.conf.d/proxy.conf && \
        echo "Acquire::https::Proxy \"$http_proxy\";" >> /etc/apt/apt.conf.d/proxy.conf && \
        echo "Acquire::http::Timeout \"60\";" >> /etc/apt/apt.conf.d/proxy.conf && \
        echo "Acquire::http::Retries \"3\";" >> /etc/apt/apt.conf.d/proxy.conf; \
    fi

RUN apt-get update && \
         DEBIAN_FRONTEND="noninteractive" \
         apt-get install -y --no-install-recommends --fix-missing \
         build-essential \
         cmake \
         git \
         curl \
         vim \
         wget \
         ca-certificates \
         tzdata \
         libssl-dev \
         gcc \
         g++ \
         gdb && \
         apt-get autoremove -y && \
         apt-get clean -y && \
         rm -rf /var/lib/apt/lists/*

RUN mkdir -p /opt/media
WORKDIR /opt/media
RUN git clone --depth 1 https://gitee.com/xia-chu/ZLMediaKit && \
    cd ZLMediaKit && git submodule update --init

# 3rdpart init
WORKDIR /opt/media/ZLMediaKit/3rdpart
RUN wget https://polaris-tian-generic.pkg.coding.net/qt/dependencies/openssl-1.1.1k.tar.gz?version=latest -O openssl-1.1.1k.tar.gz && \
    tar -xvzf openssl-1.1.1k.tar.gz && \
    cd openssl-1.1.1k && ./config shared --openssldir=/usr/local/openssl --prefix=/usr/local/openssl && \
    make && make install && \
    echo "/usr/local/lib64/" >> /etc/ld.so.conf && \
    echo "/usr/local/openssl/lib" >> /etc/ld.so.conf && \
    ldconfig && \
    ln -s /usr/local/openssl/bin/openssl  /usr/local/bin/openssl

WORKDIR /opt/media/ZLMediaKit/3rdpart
RUN wget https://github.com/cisco/libsrtp/archive/v2.3.0.tar.gz -O libsrtp-2.3.0.tar.gz && \
    tar xfv libsrtp-2.3.0.tar.gz && \
    mv libsrtp-2.3.0 libsrtp && \
    cd libsrtp && ./configure --enable-openssl --with-openssl-dir=/usr/local/openssl && make -j $(nproc) && make install


WORKDIR /opt/media/ZLMediaKit/build
RUN cmake .. -DENABLE_WEBRTC=true  -DOPENSSL_ROOT_DIR=/usr/local/openssl  -DOPENSSL_LIBRARIES=/usr/local/openssl/lib && \
    cmake --build . --target MediaServer
COPY config.ini /opt/media/ZLMediaKit/release/linux/Debug/

FROM ubuntu:20.04

# 配置 apt 使用国内镜像源（阿里云镜像）
RUN sed -i 's|http://archive.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list && \
    sed -i 's|http://security.ubuntu.com|http://mirrors.aliyun.com|g' /etc/apt/sources.list

# 如果设置了代理但连接失败，移除代理配置
RUN if [ -f /etc/apt/apt.conf.d/proxy.conf ]; then \
        rm -f /etc/apt/apt.conf.d/proxy.conf; \
    fi

RUN apt-get update && \
         DEBIAN_FRONTEND="noninteractive" \
         apt-get install -y --no-install-recommends --fix-missing \
         vim \
         wget \
         ca-certificates \
         tzdata \
         curl \
         libssl-dev \
         ffmpeg \
         gcc \
         g++ \
         gdb && \
         apt-get autoremove -y && \
         apt-get clean -y && \
    rm -rf /var/lib/apt/lists/* || \
    (echo "第一次安装失败，重试..." && sleep 10 && apt-get update && \
     DEBIAN_FRONTEND="noninteractive" \
     apt-get install -y --no-install-recommends --fix-missing \
     vim wget ca-certificates tzdata curl libssl-dev ffmpeg gcc g++ gdb && \
     apt-get autoremove -y && apt-get clean -y && \
     rm -rf /var/lib/apt/lists/*)

ENV TZ=Asia/Shanghai
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
        && echo $TZ > /etc/timezone && \
        mkdir -p /opt/media/bin/www

WORKDIR /opt/media/bin/
COPY --from=build /opt/media/ZLMediaKit/release/linux/Debug/MediaServer /opt/media/ZLMediaKit/default.pem /opt/media/bin/
COPY --from=build /opt/media/ZLMediaKit/release/linux/Debug/config.ini /opt/media/conf/
COPY --from=build /opt/media/ZLMediaKit/www/ /opt/media/bin/www/
ENV PATH /opt/media/bin:$PATH
CMD ["./MediaServer","-s", "default.pem", "-c", "../conf/config.ini", "-l","0"]