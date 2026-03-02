#!/bin/bash

# WVP-Pro 和流媒体服务启动脚本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

function log() {
    case "$1" in
    *"失败"* | *"错误"* | *"Error"*)
        echo -e "${RED}[ERROR] $1${NC}"
        ;;
    *"成功"* | *"Success"*)
        echo -e "${GREEN}[SUCCESS] $1${NC}"
        ;;
    *"警告"* | *"Warning"*)
        echo -e "${YELLOW}[WARNING] $1${NC}"
        ;;
    *)
        echo -e "${BLUE}[INFO] $1${NC}"
        ;;
    esac
}

echo ""
cat <<EOF
╔═══════════════════════════════════════════════════════════╗
║          WVP-Pro 服务启动脚本                              ║
║          WVP-Pro Service Startup Script                   ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo ""

# 检查端口是否被占用
check_port() {
    local port=$1
    if command -v lsof &> /dev/null; then
        if lsof -Pi :$port -sTCP:LISTEN -t >/dev/null 2>&1 ; then
            return 1
        fi
    elif command -v netstat &> /dev/null; then
        if netstat -an | grep -q ":$port.*LISTEN"; then
            return 1
        fi
    fi
    return 0
}

# 选择启动方式
echo ""
log "请选择启动方式:"
echo "1) 使用 Docker Compose 启动所有服务（推荐）"
echo "   - WVP-Pro + ZLMediaKit + Redis + MySQL"
echo ""
echo "2) 仅启动 WVP-Pro 服务（需要先启动流媒体、Redis、MySQL）"
echo ""
echo "3) 仅启动流媒体服务 ZLMediaKit（Docker）"
echo ""
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        log "使用 Docker Compose 启动所有服务..."
        
        if ! command -v docker &> /dev/null; then
            log "错误: 未找到 Docker，请先安装 Docker"
            exit 1
        fi
        
        if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
            log "错误: 未找到 docker-compose，请先安装 docker-compose"
            exit 1
        fi
        
        cd docker
        
        log "检查 Docker Compose 配置..."
        if [ ! -f "docker-compose.yml" ]; then
            log "错误: 未找到 docker-compose.yml 文件"
            exit 1
        fi
        
        log "启动 Docker Compose 服务..."
        if command -v docker-compose &> /dev/null; then
            docker-compose up -d
        else
            docker compose up -d
        fi
        
        log "等待服务启动..."
        sleep 10
        
        log "检查服务状态..."
        if command -v docker-compose &> /dev/null; then
            docker-compose ps
        else
            docker compose ps
        fi
        
        log "成功: 所有服务已启动"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log "WVP-Pro 访问地址: http://localhost:18080"
        log "API 文档: http://localhost:18080/doc.html"
        log "流媒体服务端口:"
        log "  - RTMP: 10935"
        log "  - RTSP: 5540"
        log "  - RTP: 10000"
        log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log ""
        log "查看日志: cd docker && docker-compose logs -f"
        log "停止服务: cd docker && docker-compose down"
        ;;
        
    2)
        log "启动 WVP-Pro 服务..."
        
        # 检查 Java 环境
        if ! command -v java &> /dev/null; then
            log "错误: 未找到 Java，请先安装 Java 21 或更高版本"
            exit 1
        fi
        
        JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        log "Java 版本: $JAVA_VERSION"
        
        # 查找 jar 文件
        JAR_FILE=$(find . -name "wvp-pro-*.jar" -type f 2>/dev/null | head -1)
        
        if [ -z "$JAR_FILE" ]; then
            log "错误: 未找到 wvp-pro jar 文件"
            log "请先编译项目: mvn clean package"
            exit 1
        fi
        
        log "找到 jar 文件: $JAR_FILE"
        
        # 检查端口
        WVP_PORT=18080
        if ! check_port $WVP_PORT; then
            log "警告: 端口 $WVP_PORT 已被占用"
            read -p "是否继续启动? (y/n): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                exit 1
            fi
        fi
        
        # 创建日志目录
        mkdir -p logs
        
        log "启动 WVP-Pro..."
        log "配置文件: application-dev.yml"
        log "服务端口: $WVP_PORT"
        
        nohup java -jar \
            -Dspring.profiles.active=dev \
            -Dfile.encoding=UTF-8 \
            -Xms512m -Xmx2048m \
            "$JAR_FILE" > logs/wvp-startup.log 2>&1 &
        
        WVP_PID=$!
        log "WVP-Pro 启动中，PID: $WVP_PID"
        log "日志文件: logs/wvp-startup.log"
        
        # 等待服务启动
        sleep 8
        
        if check_port $WVP_PORT; then
            log "成功: WVP-Pro 服务已启动"
            log "访问地址: http://localhost:$WVP_PORT"
            log "API 文档: http://localhost:$WVP_PORT/doc.html"
        else
            log "错误: WVP-Pro 服务启动失败，请查看日志: logs/wvp-startup.log"
        fi
        ;;
        
    3)
        log "启动流媒体服务 ZLMediaKit..."
        
        if ! command -v docker &> /dev/null; then
            log "错误: 未找到 Docker，请先安装 Docker"
            exit 1
        fi
        
        log "使用 Docker 启动 ZLMediaKit..."
        
        # 检查配置文件
        CONFIG_FILE="zlmediakit-config.ini"
        if [ ! -f "$CONFIG_FILE" ]; then
            log "警告: 未找到配置文件 $CONFIG_FILE，使用默认配置"
            CONFIG_FILE=""
        fi
        
        # 停止已存在的容器
        docker stop zlmediakit 2>/dev/null
        docker rm zlmediakit 2>/dev/null
        
        # 启动容器
        if [ -n "$CONFIG_FILE" ]; then
            docker run -d --name zlmediakit \
                -p 10935:10935 \
                -p 5540:5540 \
                -p 10000:10000 \
                -v "$(pwd)/$CONFIG_FILE:/conf/config.ini" \
                zlmediakit/zlmediakit:master \
                MediaServer -c /conf/config.ini
        else
            docker run -d --name zlmediakit \
                -p 10935:10935 \
                -p 5540:5540 \
                -p 10000:10000 \
                zlmediakit/zlmediakit:master
        fi
        
        sleep 3
        
        if docker ps | grep -q zlmediakit; then
            log "成功: ZLMediaKit 已启动"
            log "端口:"
            log "  - RTMP: 10935"
            log "  - RTSP: 5540"
            log "  - RTP: 10000"
            log ""
            log "查看日志: docker logs -f zlmediakit"
            log "停止服务: docker stop zlmediakit"
        else
            log "错误: ZLMediaKit 启动失败"
            docker logs zlmediakit
        fi
        ;;
        
    *)
        log "错误: 无效的选项"
        exit 1
        ;;
esac

echo ""
log "启动完成！"
