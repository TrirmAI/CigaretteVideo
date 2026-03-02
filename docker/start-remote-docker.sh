#!/bin/bash
# 远程服务器启动脚本（使用docker命令直接启动）
# 使用方法: ./start-remote-docker.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志文件
LOG_FILE="logs/startup.log"
mkdir -p logs

# 日志函数
log() {
    echo -e "$1" | tee -a "${LOG_FILE}"
}

# 错误处理函数
handle_error() {
    local error_msg="$1"
    log "${RED}错误: ${error_msg}${NC}"
    log "${YELLOW}请检查日志文件: ${LOG_FILE}${NC}"
    exit 1
}

# 端口检查函数
check_port() {
    local port=$1
    local protocol=${2:-tcp}
    local service_name=$3
    
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":${port} "; then
            log "${RED}✗ 端口 ${port}/${protocol} 已被占用 (${service_name})${NC}"
            return 1
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":${port} "; then
            log "${RED}✗ 端口 ${port}/${protocol} 已被占用 (${service_name})${NC}"
            return 1
        fi
    elif command -v lsof &> /dev/null; then
        if lsof -i :${port} &>/dev/null; then
            log "${RED}✗ 端口 ${port}/${protocol} 已被占用 (${service_name})${NC}"
            return 1
        fi
    fi
    log "${GREEN}✓ 端口 ${port}/${protocol} 可用 (${service_name})${NC}"
    return 0
}

# 检查所有端口
check_all_ports() {
    log "${BLUE}检查端口占用情况...${NC}"
    
    # 加载环境变量
    source .env 2>/dev/null || true
    
    local port_errors=0
    
    # WVP HTTP端口
    if ! check_port "${WVP_HTTP_PORT:-18978}" "tcp" "WVP HTTP"; then
        port_errors=$((port_errors + 1))
    fi
    
    # SIP端口
    if ! check_port "${SIP_Port:-8116}" "udp" "SIP UDP"; then
        port_errors=$((port_errors + 1))
    fi
    if ! check_port "${SIP_Port:-8116}" "tcp" "SIP TCP"; then
        port_errors=$((port_errors + 1))
    fi
    
    # 流媒体HTTP端口
    if ! check_port "${WebHttp:-8080}" "tcp" "流媒体HTTP"; then
        port_errors=$((port_errors + 1))
    fi
    
    # RTMP端口
    if ! check_port "${MediaRtmp:-10935}" "tcp" "RTMP TCP"; then
        port_errors=$((port_errors + 1))
    fi
    if ! check_port "${MediaRtmp:-10935}" "udp" "RTMP UDP"; then
        port_errors=$((port_errors + 1))
    fi
    
    # RTSP端口
    if ! check_port "${MediaRtsp:-5540}" "tcp" "RTSP TCP"; then
        port_errors=$((port_errors + 1))
    fi
    if ! check_port "${MediaRtsp:-5540}" "udp" "RTSP UDP"; then
        port_errors=$((port_errors + 1))
    fi
    
    # RTP端口
    if ! check_port "${MediaRtp:-10000}" "tcp" "RTP TCP"; then
        port_errors=$((port_errors + 1))
    fi
    if ! check_port "${MediaRtp:-10000}" "udp" "RTP UDP"; then
        port_errors=$((port_errors + 1))
    fi
    
    # JT1078端口
    if ! check_port "${JT1078_Port:-21078}" "tcp" "JT1078 TCP"; then
        port_errors=$((port_errors + 1))
    fi
    if ! check_port "${JT1078_Port:-21078}" "udp" "JT1078 UDP"; then
        port_errors=$((port_errors + 1))
    fi
    
    if [ $port_errors -gt 0 ]; then
        log "${RED}发现 ${port_errors} 个端口被占用！${NC}"
        log "${YELLOW}解决方案:${NC}"
        log "  1. 停止占用端口的服务"
        log "  2. 修改 .env 文件中的端口配置"
        log "  3. 使用命令查看端口占用: netstat -tulpn | grep <端口号>"
        return 1
    fi
    
    log "${GREEN}✓ 所有端口检查通过${NC}"
    return 0
}

# 配置验证函数
validate_config() {
    log "${BLUE}验证配置文件...${NC}"
    local config_errors=0
    
    # 检查.env文件
    if [ ! -f ".env" ]; then
        log "${YELLOW}警告: .env 文件不存在，将创建默认配置${NC}"
        config_errors=$((config_errors + 1))
    else
        # 检查必需的SIP配置
        source .env 2>/dev/null || true
        
        if [ -z "${SIP_Domain:-}" ] || [ "${SIP_Domain}" = "4101050000" ]; then
            log "${YELLOW}警告: SIP_Domain 未配置或使用默认值，请确认是否正确${NC}"
        fi
        
        if [ -z "${SIP_Id:-}" ] || [ "${SIP_Id}" = "41010500002000000001" ]; then
            log "${YELLOW}警告: SIP_Id 未配置或使用默认值，请确认是否正确${NC}"
        fi
        
        if [ -z "${SIP_Password:-}" ] || [ "${SIP_Password}" = "12345678" ]; then
            log "${YELLOW}警告: SIP_Password 未配置或使用默认值，请确认是否正确${NC}"
        fi
        
        if [ -z "${Stream_IP:-}" ]; then
            log "${RED}错误: Stream_IP 未配置${NC}"
            config_errors=$((config_errors + 1))
        fi
        
        if [ -z "${SDP_IP:-}" ]; then
            log "${RED}错误: SDP_IP 未配置${NC}"
            config_errors=$((config_errors + 1))
        fi
    fi
    
    # 检查application.yml
    if [ ! -f "wvp/wvp/application.yml" ]; then
        log "${RED}错误: wvp/wvp/application.yml 不存在${NC}"
        log "${YELLOW}请从项目复制配置文件到 wvp/wvp/ 目录${NC}"
        config_errors=$((config_errors + 1))
    fi
    
    # 检查config.ini
    if [ ! -f "media/config.ini" ]; then
        log "${YELLOW}警告: media/config.ini 不存在，将创建默认配置${NC}"
    fi
    
    if [ $config_errors -gt 0 ]; then
        log "${RED}配置文件验证失败，发现 ${config_errors} 个错误${NC}"
        return 1
    fi
    
    log "${GREEN}✓ 配置文件验证通过${NC}"
    return 0
}

# 健康检查函数
wait_for_service() {
    local service_name=$1
    local check_command=$2
    local max_attempts=${3:-30}
    local attempt=0
    
    log "${BLUE}等待 ${service_name} 服务就绪...${NC}"
    
    while [ $attempt -lt $max_attempts ]; do
        if eval "$check_command" &>/dev/null; then
            log "${GREEN}✓ ${service_name} 服务已就绪${NC}"
            return 0
        fi
        attempt=$((attempt + 1))
        echo -n "."
        sleep 2
    done
    
    echo ""
    log "${RED}✗ ${service_name} 服务启动超时${NC}"
    return 1
}

# 检查服务健康状态
check_service_health() {
    log "${BLUE}检查服务健康状态...${NC}"
    local health_errors=0
    
    # 检查Redis
    if ! wait_for_service "Redis" "${DOCKER_CMD} exec polaris-redis redis-cli ping" 10; then
        health_errors=$((health_errors + 1))
    fi
    
    # 检查MySQL
    if ! wait_for_service "MySQL" "${DOCKER_CMD} exec polaris-mysql mysqladmin ping -h localhost -uroot -proot" 30; then
        health_errors=$((health_errors + 1))
    fi
    
    # 检查流媒体服务器
    if ! wait_for_service "流媒体服务器" "curl -s http://localhost:8080/index/api/getServerConfig" 20; then
        health_errors=$((health_errors + 1))
    fi
    
    # 检查WVP服务
    if ! wait_for_service "WVP" "curl -s http://localhost:${WVP_HTTP_PORT:-18978}/api/user/login" 30; then
        health_errors=$((health_errors + 1))
    fi
    
    if [ $health_errors -gt 0 ]; then
        log "${RED}有 ${health_errors} 个服务健康检查失败${NC}"
        log "${YELLOW}请查看日志: ${DOCKER_CMD} logs <容器名>${NC}"
        return 1
    fi
    
    log "${GREEN}✓ 所有服务健康检查通过${NC}"
    return 0
}

# 显示服务状态
show_service_status() {
    log "${BLUE}服务状态详情:${NC}"
    ${DOCKER_CMD} ps --filter "name=polaris-" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    
    echo ""
    log "${BLUE}容器健康状态:${NC}"
    
    # 检查每个容器的健康状态
    for container in polaris-redis polaris-mysql polaris-media polaris-wvp; do
        if ${DOCKER_CMD} ps --format "{{.Names}}" | grep -q "^${container}$"; then
            local status=$(${DOCKER_CMD} inspect --format='{{.State.Status}}' ${container} 2>/dev/null || echo "unknown")
            local health=$(${DOCKER_CMD} inspect --format='{{.State.Health.Status}}' ${container} 2>/dev/null || echo "no-healthcheck")
            
            if [ "$health" = "no-healthcheck" ]; then
                log "  ${container}: ${status} (无健康检查)"
            else
                log "  ${container}: ${status} [健康状态: ${health}]"
            fi
        fi
    done
}

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}WVP-Pro 远程服务器启动脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查docker或podman
DOCKER_CMD=""
if command -v docker &> /dev/null; then
    DOCKER_CMD="docker"
elif command -v podman &> /dev/null; then
    DOCKER_CMD="podman"
else
    handle_error "未找到 docker 或 podman 命令，请先安装 Docker 或 Podman"
fi

log "${BLUE}使用命令: ${DOCKER_CMD}${NC}"
echo ""

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

log "${BLUE}工作目录: ${SCRIPT_DIR}${NC}"
log "${BLUE}日志文件: ${LOG_FILE}${NC}"
echo ""

# 创建必要的目录结构
log "${BLUE}创建必要的目录结构...${NC}"
mkdir -p volumes/redis/data
mkdir -p volumes/mysql/data
mkdir -p volumes/video
mkdir -p logs/mysql
mkdir -p volumes/wvp/static/static
mkdir -p logs/media
mkdir -p logs/wvp
mkdir -p wvp/config
mkdir -p wvp/wvp
mkdir -p media

log "${GREEN}✓ 目录创建完成${NC}"
echo ""

# 检查配置文件是否存在
if [ ! -f "media/config.ini" ]; then
    log "${YELLOW}警告: media/config.ini 不存在，将创建默认配置${NC}"
    cat > media/config.ini << 'EOF'
[api]
apiDebug=1
defaultSnap=./www/logo.png
downloadRoot=./www
secret=su6TiedN2rVAmBbIDX0aa0QTiBJLBdcf
snapRoot=./www/snap/

[general]
enableVhost=0
mediaServerId=polaris
flowThreshold=1024
maxStreamWaitMS=15000
streamNoneReaderDelayMS=20000
resetWhenRePlay=1
addMuteAudio=1
resetWhenRePlay=1
publishToRtxp=0
publishToRtxpOnly=0

[hls]
segDur=2
segNum=3
segRetain=5
segDelay=0
fastRegister=0
fileBufSize=65536
filePath=./www/record/
fileSecond=0
segKeep=0

[hook]
enable=1
on_flow_report=
on_http_access=
on_play=
on_publish=
on_record_mp4=
on_rtsp_realm=
on_rtsp_auth=
on_stream_changed=
on_stream_not_found=
on_stream_none_reader=
on_server_started=
timeoutSec=10
alive_interval=10.0
on_stream_changed=1

[http]
port=80
rootPath=./www
notFound=./www/404.html
charSet=utf-8
sendBufSize=65536
maxReqSize=4096
keepAliveSecond=30
dirMenu=1
virtualPath=
forbidCacheSuffix=
forwarded_ip_header=

[multicast]
addrMin=239.0.0.0
addrMax=239.255.255.255
udpTTL=64

[record]
appName=record
sampleMS=500
filePath=./www/record/
fileRepeat=0
fileSecond=0

[rtmp]
port=1935
handshakeSecond=15
keepAliveSecond=15
directProxy=1
modifyStamp=0

[rtp]
audioMtuSize=600
videoMtuSize=1400
rtpMaxSize=10
lowLatency=0
h264_stap_a=0

[rtsp]
port=554
authBasic=0
handshakeSecond=15
keepAliveSecond=15
lowLatency=0

[shell]
port=9000
maxReqSize=1024

[cluster]
origin_url=
retry_count=3
timeout_sec=15
EOF
    log "${GREEN}✓ 已创建默认 media/config.ini${NC}"
fi

# 检查镜像是否存在
log "${BLUE}检查镜像是否存在...${NC}"
MISSING_IMAGES=()

# 定义镜像映射（支持localhost/前缀和polaris-前缀）
declare -A IMAGE_MAP=(
    ["redis:latest"]="localhost/polaris-redis:latest localhost/redis:latest redis:latest docker.io/library/redis:latest"
    ["mysql:8"]="localhost/polaris-mysql:latest localhost/mysql:8 mysql:8 docker.io/library/mysql:8"
    ["zlmediakit/zlmediakit:master"]="localhost/polaris-media:latest localhost/zlmediakit/zlmediakit:master zlmediakit/zlmediakit:master docker.io/zlmediakit/zlmediakit:master"
    ["wvp-pro:latest"]="localhost/wvp-pro:latest localhost/polaris-wvp:latest wvp-pro:latest"
)

# 实际使用的镜像名称
declare -A ACTUAL_IMAGES=()

for img in "redis:latest" "mysql:8" "zlmediakit/zlmediakit:master" "wvp-pro:latest"; do
    FOUND=false
    for possible_img in ${IMAGE_MAP[$img]}; do
        if ${DOCKER_CMD} images --format "{{.Repository}}:{{.Tag}}" 2>/dev/null | grep -q "^${possible_img}$"; then
            log "${GREEN}✓ 找到镜像: ${possible_img}${NC}"
            ACTUAL_IMAGES[$img]=$possible_img
            FOUND=true
            break
        fi
    done
    if [ "$FOUND" = false ]; then
        log "${RED}✗ 未找到镜像: ${img}${NC}"
        MISSING_IMAGES+=("${img}")
    fi
done

if [ ${#MISSING_IMAGES[@]} -gt 0 ]; then
    log "${RED}错误: 以下镜像不存在:${NC}"
    for img in "${MISSING_IMAGES[@]}"; do
        log "  - ${img}"
    done
    log "${YELLOW}请先加载镜像: ${DOCKER_CMD} load -i /home/wvp/wvp-images.tar${NC}"
    handle_error "镜像缺失，请先加载镜像"
fi

echo ""

# 检查环境变量文件
if [ ! -f ".env" ]; then
    log "${YELLOW}创建默认 .env 文件...${NC}"
    cat > .env << 'EOF'
# WVP配置
WVP_HTTP_PORT=18978
SIP_Port=8116
SIP_Domain=4101050000
SIP_Id=41010500002000000001
SIP_Password=12345678
SIP_ShowIP=172.31.127.47
Stream_IP=172.31.127.47
SDP_IP=172.31.127.47

# 流媒体服务器配置
WebHttp=8080
MediaRtmp=10935
MediaRtsp=5540
MediaRtp=10000

# JT1078配置（可选）
JT1078_Port=21078

# 录制配置（可选）
RecordSip=true
RecordPushLive=true
EOF
    log "${GREEN}✓ 已创建默认 .env 文件（使用项目默认SIP参数）${NC}"
    log "${YELLOW}请编辑 .env 文件配置正确的SIP参数${NC}"
    echo ""
fi

# 加载环境变量
source .env 2>/dev/null || true

# 验证配置
if ! validate_config; then
    handle_error "配置文件验证失败，请修复后重试"
fi

echo ""

# 检查端口占用
if ! check_all_ports; then
    handle_error "端口检查失败，请解决端口冲突后重试"
fi

echo ""

# 创建网络
log "${BLUE}创建Docker网络...${NC}"
${DOCKER_CMD} network create media-net 2>/dev/null || log "${YELLOW}网络已存在${NC}"
echo ""

# 停止并删除旧容器（如果存在）
log "${BLUE}停止旧容器...${NC}"
${DOCKER_CMD} stop polaris-redis polaris-mysql polaris-media polaris-wvp 2>/dev/null || true
${DOCKER_CMD} rm polaris-redis polaris-mysql polaris-media polaris-wvp 2>/dev/null || true
echo ""

# 启动Redis
log "${BLUE}启动Redis服务...${NC}"
if ! ${DOCKER_CMD} run -d \
    --name polaris-redis \
    --network media-net \
    --restart unless-stopped \
    -v "${SCRIPT_DIR}/volumes/redis/data:/data" \
    -e TZ=Asia/Shanghai \
    ${ACTUAL_IMAGES["redis:latest"]} \
    redis-server --appendonly yes; then
    handle_error "Redis服务启动失败"
fi

# 启动MySQL
log "${BLUE}启动MySQL服务...${NC}"
if ! ${DOCKER_CMD} run -d \
    --name polaris-mysql \
    --network media-net \
    --restart unless-stopped \
    -p 3306:3306/tcp \
    -e MYSQL_DATABASE=wvp \
    -e MYSQL_ROOT_PASSWORD=root \
    -e MYSQL_USER=wvp_user \
    -e MYSQL_PASSWORD=wvp_password \
    -e TZ=Asia/Shanghai \
    -v "${SCRIPT_DIR}/volumes/mysql/data:/var/lib/mysql" \
    -v "${SCRIPT_DIR}/logs/mysql:/logs" \
    ${ACTUAL_IMAGES["mysql:8"]} \
    --innodb-buffer-pool-size=80M \
    --character-set-server=utf8mb4 \
    --collation-server=utf8mb4_general_ci \
    --default-time-zone=+8:00 \
    --lower-case-table-names=1; then
    handle_error "MySQL服务启动失败"
fi

# 启动流媒体服务器
log "${BLUE}启动流媒体服务器...${NC}"
if ! ${DOCKER_CMD} run -d \
    --name polaris-media \
    --network media-net \
    --restart always \
    -p 8080:80/tcp \
    -p ${MediaRtmp:-10935}:${MediaRtmp:-10935}/tcp \
    -p ${MediaRtmp:-10935}:${MediaRtmp:-10935}/udp \
    -p ${MediaRtsp:-5540}:${MediaRtsp:-5540}/tcp \
    -p ${MediaRtsp:-5540}:${MediaRtsp:-5540}/udp \
    -p ${MediaRtp:-10000}:${MediaRtp:-10000}/tcp \
    -p ${MediaRtp:-10000}:${MediaRtp:-10000}/udp \
    -p 8001:8001/tcp \
    -p 8001:8001/udp \
    -v "${SCRIPT_DIR}/volumes/video:/opt/media/bin/www/record/" \
    -v "${SCRIPT_DIR}/logs/media:/opt/media/log/" \
    -v "${SCRIPT_DIR}/media/config.ini:/conf/config.ini" \
    ${ACTUAL_IMAGES["zlmediakit/zlmediakit:master"]} \
    MediaServer -c /conf/config.ini -l 0; then
    handle_error "流媒体服务器启动失败"
fi

# 启动WVP服务
log "${BLUE}启动WVP服务...${NC}"
if ! ${DOCKER_CMD} run -d \
    --name polaris-wvp \
    --network media-net \
    --restart always \
    -p ${WVP_HTTP_PORT:-18978}:18978/tcp \
    -p ${SIP_Port:-8116}:${SIP_Port:-8116}/udp \
    -p ${SIP_Port:-8116}:${SIP_Port:-8116}/tcp \
    -p ${JT1078_Port:-21078}:21078/tcp \
    -p ${JT1078_Port:-21078}:21078/udp \
    -v "${SCRIPT_DIR}/wvp/config:/opt/wvp/config" \
    -v "${SCRIPT_DIR}/wvp/wvp/:/opt/ylcx/wvp/" \
    -v "${SCRIPT_DIR}/logs/wvp:/opt/wvp/logs/" \
    -v "${SCRIPT_DIR}/volumes/wvp/static:/opt/wvp/static" \
    -e TZ=Asia/Shanghai \
    -e Stream_IP=${Stream_IP:-172.31.127.47} \
    -e SDP_IP=${SDP_IP:-172.31.127.47} \
    -e ZLM_HOOK_HOST=polaris-wvp \
    -e ZLM_HOST=polaris-media \
    -e ZLM_SERCERT=su6TiedN2rVAmBbIDX0aa0QTiBJLBdcf \
    -e MediaHttp=${WebHttp:-8080} \
    -e MediaRtmp=${MediaRtmp:-10935} \
    -e MediaRtsp=${MediaRtsp:-5540} \
    -e MediaRtp=${MediaRtp:-10000} \
    -e REDIS_HOST=polaris-redis \
    -e REDIS_PORT=6379 \
    -e DATABASE_HOST=polaris-mysql \
    -e DATABASE_PORT=3306 \
    -e DATABASE_USER=wvp_user \
    -e DATABASE_PASSWORD=wvp_password \
    -e SIP_ShowIP=${SIP_ShowIP} \
    -e SIP_Port=${SIP_Port:-8116} \
    -e SIP_Domain=${SIP_Domain} \
    -e SIP_Id=${SIP_Id} \
    -e SIP_Password=${SIP_Password} \
    -e RecordSip=${RecordSip} \
    -e RecordPushLive=${RecordPushLive} \
    ${ACTUAL_IMAGES["wvp-pro:latest"]}; then
    handle_error "WVP服务启动失败"
fi

echo ""

# 等待服务启动
log "${BLUE}等待服务启动...${NC}"
sleep 5

# 检查服务健康状态
if ! check_service_health; then
    log "${YELLOW}部分服务健康检查失败，但容器已启动${NC}"
    log "${YELLOW}请查看日志确认服务状态: ${DOCKER_CMD} logs <容器名>${NC}"
    echo ""
fi

# 显示服务状态
echo ""
log "${GREEN}========================================${NC}"
log "${GREEN}服务启动完成！${NC}"
log "${GREEN}========================================${NC}"
echo ""

show_service_status

echo ""
log "${BLUE}访问地址:${NC}"
log "  WVP Web界面: http://${Stream_IP:-172.31.127.47}:${WVP_HTTP_PORT:-18978}"
log "  流媒体服务器: http://${Stream_IP:-172.31.127.47}:${WebHttp:-8080}"
echo ""

# 检查数据库初始化
log "${BLUE}数据库状态检查:${NC}"
if ${DOCKER_CMD} exec polaris-mysql mysql -uroot -proot -e "USE wvp; SHOW TABLES;" 2>/dev/null | grep -q "wvp_device"; then
    log "${GREEN}✓ 数据库已初始化${NC}"
else
    log "${YELLOW}⚠ 数据库未初始化或表不存在${NC}"
    log "${YELLOW}如需初始化数据库，请执行:${NC}"
    log "  ${DOCKER_CMD} exec -i polaris-mysql mysql -uroot -proot wvp < <SQL文件路径>"
fi

echo ""
log "${YELLOW}常用命令:${NC}"
log "  查看WVP日志: ${DOCKER_CMD} logs -f polaris-wvp"
log "  查看流媒体日志: ${DOCKER_CMD} logs -f polaris-media"
log "  查看MySQL日志: ${DOCKER_CMD} logs -f polaris-mysql"
log "  查看Redis日志: ${DOCKER_CMD} logs -f polaris-redis"
log "  停止服务: ${DOCKER_CMD} stop polaris-redis polaris-mysql polaris-media polaris-wvp"
log "  删除容器: ${DOCKER_CMD} rm polaris-redis polaris-mysql polaris-media polaris-wvp"
echo ""
log "${BLUE}启动日志已保存到: ${LOG_FILE}${NC}"
echo ""

