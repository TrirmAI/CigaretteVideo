#!/bin/bash
# 检查远程 MySQL 8.0 构建状态

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
echo -e "${BLUE}检查远程 MySQL 8.0 构建状态${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 创建临时远程脚本
TEMP_REMOTE_SCRIPT=$(mktemp)
cat > "${TEMP_REMOTE_SCRIPT}" << 'REMOTE_CHECK_SCRIPT'
#!/bin/bash
BUILD_DIR="/home/wvp/build"
cd "${BUILD_DIR}" || exit 1

echo "=== 构建进程状态 ==="
if [ -f build-mysql.pid ]; then
    PID=$(cat build-mysql.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "✓ 构建进行中，PID: $PID"
        echo ""
        echo "=== 最近构建日志（最后30行）==="
        tail -30 build-mysql.log
    else
        echo "✗ 构建进程已结束（PID文件存在但进程不存在）"
        echo ""
        echo "=== 构建日志（最后50行）==="
        tail -50 build-mysql.log
    fi
else
    echo "✗ 未找到构建进程（build-mysql.pid 不存在）"
    if [ -f build-mysql.log ]; then
        echo ""
        echo "=== 构建日志（最后20行）==="
        tail -20 build-mysql.log
    fi
fi

echo ""
echo "=== Docker镜像 ==="
# 检查 docker 或 podman 命令
DOCKER_CMD=""
if command -v docker &> /dev/null; then
    DOCKER_CMD="docker"
elif command -v podman &> /dev/null; then
    DOCKER_CMD="podman"
fi

if [ -n "$DOCKER_CMD" ]; then
    ${DOCKER_CMD} images | grep -E "polaris-mysql|mysql" || echo "暂无相关镜像"
else
    echo "错误: 未找到 docker 或 podman 命令"
fi
REMOTE_CHECK_SCRIPT

chmod +x "${TEMP_REMOTE_SCRIPT}"

# 传输并执行远程脚本
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        "${TEMP_REMOTE_SCRIPT}" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/check-mysql-build-status-remote.sh"
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "bash /tmp/check-mysql-build-status-remote.sh && rm -f /tmp/check-mysql-build-status-remote.sh"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${TEMP_REMOTE_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/check-mysql-build-status-remote.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/check-mysql-build-status-remote.sh && rm -f /tmp/check-mysql-build-status-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
else
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

rm -f "${TEMP_REMOTE_SCRIPT}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}提示:${NC}"
echo -e "  查看详细日志: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ${REMOTE_BUILD_DIR}/build-mysql.log'"
echo -e "  重新检查状态: ./check-mysql-build-status.sh"
echo -e "${BLUE}========================================${NC}"

