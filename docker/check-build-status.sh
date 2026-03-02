#!/bin/bash
# 检查远程服务器构建状态

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

REMOTE_HOST="172.31.127.47"
REMOTE_USER="root"
REMOTE_PASSWORD="Shenzhoulu9#"
REMOTE_BUILD_DIR="/home/wvp/build"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}检查远程构建状态${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查构建状态
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" << 'REMOTE_CHECK'
        cd /home/wvp/build
        
        echo "=== 构建进程状态 ==="
        if [ -f build.pid ]; then
            PID=$(cat build.pid)
            if ps -p $PID > /dev/null 2>&1; then
                echo "✓ 构建进行中，PID: $PID"
                echo ""
                echo "=== 最近构建日志（最后30行）==="
                tail -30 build.log
            else
                echo "✗ 构建进程已结束（PID文件存在但进程不存在）"
                echo ""
                echo "=== 构建日志（最后50行）==="
                tail -50 build.log
            fi
        else
            echo "✗ 未找到构建进程（build.pid 不存在）"
            if [ -f build.log ]; then
                echo ""
                echo "=== 构建日志（最后20行）==="
                tail -20 build.log
            fi
        fi
        
        echo ""
        echo "=== Docker镜像 ==="
        docker images | grep -E "wvp-pro|wvp-nginx" || echo "暂无相关镜像"
REMOTE_CHECK
elif command -v expect &> /dev/null; then
    # 创建临时远程检查脚本
    TEMP_SCRIPT=$(mktemp)
    cat > "${TEMP_SCRIPT}" << 'REMOTE_SCRIPT'
cd /home/wvp/build

echo "=== 构建进程状态 ==="
if [ -f build.pid ]; then
    PID=$(cat build.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✓ 构建进行中，PID: $PID"
        echo ""
        echo "=== 最近构建日志（最后30行）==="
        tail -30 build.log
    else
        echo "✗ 构建进程已结束（PID文件存在但进程不存在）"
        echo ""
        echo "=== 构建日志（最后50行）==="
        tail -50 build.log
    fi
else
    echo "✗ 未找到构建进程（build.pid 不存在）"
    if [ -f build.log ]; then
        echo ""
        echo "=== 构建日志（最后20行）==="
        tail -20 build.log
    fi
fi

echo ""
echo "=== Docker镜像 ==="
docker images | grep -E "wvp-pro|wvp-nginx" || echo "暂无相关镜像"
REMOTE_SCRIPT
    
    # 传输并执行脚本
    expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${TEMP_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/check-build-status-remote.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/check-build-status-remote.sh && rm -f /tmp/check-build-status-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    rm -f "${TEMP_SCRIPT}"
else
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}提示:${NC}"
echo -e "  实时查看日志: ./watch-build-log.sh"
echo -e "  重新检查状态: ./check-build-status.sh"
echo -e "${BLUE}========================================${NC}"

