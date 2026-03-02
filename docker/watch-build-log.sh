#!/bin/bash
# 实时查看远程服务器构建日志

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
echo -e "${BLUE}实时查看远程构建日志${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}按 Ctrl+C 退出${NC}"
echo ""

# 检查构建进程是否存在
if command -v sshpass &> /dev/null; then
    BUILD_RUNNING=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "cd ${REMOTE_BUILD_DIR} && if [ -f build.pid ]; then PID=\$(cat build.pid); ps -p \$PID > /dev/null 2>&1 && echo 'yes' || echo 'no'; else echo 'no'; fi")
elif command -v expect &> /dev/null; then
    TEMP_CHECK=$(mktemp)
    expect << EOF > "${TEMP_CHECK}" 2>&1
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_BUILD_DIR} && if [ -f build.pid ]; then PID=\\\$(cat build.pid); ps -p \\\$PID > /dev/null 2>&1 && echo 'yes' || echo 'no'; else echo 'no'; fi"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    BUILD_RUNNING=$(grep -E "^yes$|^no$" "${TEMP_CHECK}" | tail -1)
    rm -f "${TEMP_CHECK}"
else
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

if [ "$BUILD_RUNNING" = "yes" ]; then
    echo -e "${GREEN}✓ 构建正在进行中，开始实时显示日志...${NC}"
    echo ""
else
    echo -e "${YELLOW}⚠ 构建进程未运行，显示现有日志...${NC}"
    echo ""
fi

# 实时查看日志
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "tail -f ${REMOTE_BUILD_DIR}/build.log"
elif command -v expect &> /dev/null; then
    # 创建远程 tail 脚本
    TEMP_TAIL_SCRIPT=$(mktemp)
    cat > "${TEMP_TAIL_SCRIPT}" << 'TAIL_SCRIPT'
#!/bin/bash
tail -f /home/wvp/build/build.log
TAIL_SCRIPT
    
    # 传输并执行
    expect << EXPECT_EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${TEMP_TAIL_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/tail-build-log.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "chmod +x /tmp/tail-build-log.sh && /tmp/tail-build-log.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    -re ".*" {
        exp_continue
    }
    eof
}
EXPECT_EOF
    rm -f "${TEMP_TAIL_SCRIPT}"
else
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    echo -e "${YELLOW}或者手动执行: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ${REMOTE_BUILD_DIR}/build.log'${NC}"
    exit 1
fi

