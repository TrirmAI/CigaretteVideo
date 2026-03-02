#!/bin/bash

# WVP-Pro 本地开发启动脚本
# 启动Docker中的数据库和流媒体服务器，然后启动本地的前端和后端服务

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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
║          WVP-Pro 本地开发环境启动脚本                       ║
║          WVP-Pro Local Development Startup Script        ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo ""

# 检查必要的工具
check_requirements() {
    log "检查环境依赖..."
    
    # 检查 Docker
    if ! command -v docker &> /dev/null; then
        log "错误: 未找到 Docker，请先安装 Docker"
        exit 1
    fi
    
    # 检查 Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log "错误: 未找到 docker-compose，请先安装 docker-compose"
        exit 1
    fi
    
    # 检查 Java
    if ! command -v java &> /dev/null; then
        log "错误: 未找到 Java，请先安装 Java 21 或更高版本"
        exit 1
    fi
    
    JAVA_VERSION=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
    log "Java 版本: $JAVA_VERSION"
    
    # 检查 Node.js
    if ! command -v node &> /dev/null; then
        log "错误: 未找到 Node.js，请先安装 Node.js"
        exit 1
    fi
    
    NODE_VERSION=$(node -v)
    log "Node.js 版本: $NODE_VERSION"
    
    # 检查 npm
    if ! command -v npm &> /dev/null; then
        log "错误: 未找到 npm，请先安装 npm"
        exit 1
    fi
    
    log "环境检查完成"
}

# 启动 Docker 服务
start_docker_services() {
    log "启动 Docker 服务（Redis、MySQL、流媒体服务器）..."
    
    cd docker
    
    # 使用本地开发配置启动服务
    if command -v docker-compose &> /dev/null; then
        docker-compose -f docker-compose-local.yml up -d
    else
        docker compose -f docker-compose-local.yml up -d
    fi
    
    if [ $? -ne 0 ]; then
        log "错误: Docker 服务启动失败"
        exit 1
    fi
    
    log "等待 Docker 服务启动..."
    sleep 10
    
    # 检查服务状态
    log "检查 Docker 服务状态..."
    if command -v docker-compose &> /dev/null; then
        docker-compose -f docker-compose-local.yml ps
    else
        docker compose -f docker-compose-local.yml ps
    fi
    
    cd ..
    log "Docker 服务启动成功"
}

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

# 编译后端（如果需要）
build_backend() {
    log "检查后端 jar 文件..."
    
    JAR_FILE=$(find target -name "wvp-pro-*.jar" -type f 2>/dev/null | head -1)
    
    if [ -z "$JAR_FILE" ]; then
        log "未找到 jar 文件，开始编译..."
        
        if ! command -v mvn &> /dev/null; then
            log "错误: 未找到 Maven，请先安装 Maven"
            exit 1
        fi
        
        log "编译项目（这可能需要几分钟）..."
        mvn clean package -DskipTests
        
        if [ $? -ne 0 ]; then
            log "错误: 编译失败"
            exit 1
        fi
        
        JAR_FILE=$(find target -name "wvp-pro-*.jar" -type f 2>/dev/null | head -1)
        log "编译完成: $JAR_FILE"
    else
        log "找到 jar 文件: $JAR_FILE"
    fi
}

# 启动后端服务
start_backend() {
    log "启动后端服务..."
    
    JAR_FILE=$(find target -name "wvp-pro-*.jar" -type f 2>/dev/null | head -1)
    
    if [ -z "$JAR_FILE" ]; then
        log "错误: 未找到 jar 文件，请先编译项目"
        exit 1
    fi
    
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
    
    log "启动 WVP-Pro 后端服务..."
    log "配置文件: application-dev.yml"
    log "服务端口: $WVP_PORT"
    
    nohup java -jar \
        -Dspring.profiles.active=dev \
        -Dfile.encoding=UTF-8 \
        -Xms512m -Xmx2048m \
        "$JAR_FILE" > logs/wvp-startup.log 2>&1 &
    
    WVP_PID=$!
    log "WVP-Pro 后端启动中，PID: $WVP_PID"
    log "日志文件: logs/wvp-startup.log"
    
    # 等待服务启动
    log "等待后端服务启动..."
    sleep 10
    
    if check_port $WVP_PORT; then
        log "警告: 后端服务可能未成功启动，请查看日志: logs/wvp-startup.log"
    else
        log "成功: WVP-Pro 后端服务已启动"
        log "访问地址: http://localhost:$WVP_PORT"
        log "API 文档: http://localhost:$WVP_PORT/doc.html"
    fi
}

# 启动前端服务
start_frontend() {
    log "启动前端服务..."
    
    cd web
    
    # 检查 node_modules
    if [ ! -d "node_modules" ]; then
        log "未找到 node_modules，开始安装依赖..."
        npm install
        
        if [ $? -ne 0 ]; then
            log "错误: npm 依赖安装失败"
            cd ..
            exit 1
        fi
    fi
    
    # 检查端口
    FRONTEND_PORT=9528
    if ! check_port $FRONTEND_PORT; then
        log "警告: 端口 $FRONTEND_PORT 已被占用"
        read -p "是否继续启动? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            cd ..
            exit 1
        fi
    fi
    
    log "启动前端开发服务器..."
    log "前端端口: $FRONTEND_PORT"
    log "后端代理: http://127.0.0.1:18080"
    
    # 在后台启动前端服务
    npm run dev > ../logs/frontend.log 2>&1 &
    FRONTEND_PID=$!
    
    log "前端服务启动中，PID: $FRONTEND_PID"
    log "日志文件: logs/frontend.log"
    
    sleep 5
    
    log "成功: 前端服务已启动"
    log "访问地址: http://localhost:$FRONTEND_PORT"
    
    cd ..
}

# 主函数
main() {
    # 检查环境
    check_requirements
    
    # 启动 Docker 服务
    start_docker_services
    
    # 编译后端（如果需要）
    build_backend
    
    # 启动后端
    start_backend
    
    # 启动前端
    start_frontend
    
    echo ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "所有服务启动完成！"
    log ""
    log "前端地址: http://localhost:9528"
    log "后端地址: http://localhost:18080"
    log "API 文档: http://localhost:18080/doc.html"
    log ""
    log "查看日志:"
    log "  后端: tail -f logs/wvp-startup.log"
    log "  前端: tail -f logs/frontend.log"
    log "  Docker: cd docker && docker-compose -f docker-compose-local.yml logs -f"
    log ""
    log "停止服务:"
    log "  停止 Docker: cd docker && docker-compose -f docker-compose-local.yml down"
    log "  停止后端: kill $WVP_PID"
    log "  停止前端: kill $FRONTEND_PID"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

# 执行主函数
main

