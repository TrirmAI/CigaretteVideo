FROM --platform=linux/amd64 redis:latest

RUN mkdir -p /opt/polaris/redis
WORKDIR /opt/polaris/redis
COPY ./conf/redis.conf /opt/polaris/redis/redis.conf