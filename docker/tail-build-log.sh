#!/bin/bash
# 实时查看远程服务器构建日志（定期刷新）

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
LINES="${1:-50}"  # 默认显示最后50行
INTERVAL="${2:-3}"  # 默认每3秒刷新一次

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}实时查看远程构建日志${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}显示最后 ${LINES} 行，每 ${INTERVAL} 秒刷新一次${NC}"
echo -e "${YELLOW}按 Ctrl+C 退出${NC}"
echo ""

# 创建临时远程脚本
TEMP_SCRIPT=$(mktemp)
cat > "${TEMP_SCRIPT}" << REMOTE_SCRIPT
cd ${REMOTE_BUILD_DIR}
if [ -f build.log ]; then
    tail -n ${LINES} build.log
else
    echo "构建日志文件不存在"
fi
REMOTE_SCRIPT

# 循环显示日志
while true; do
    clear
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}构建日志（最后 ${LINES} 行）${NC}"
    echo -e "${BLUE}时间: $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    
    expect << EOF > /dev/null 2>&1
set timeout 10
spawn scp -o StrictHostKeyChecking=no ${TEMP_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/tail-log-remote.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/tail-log-remote.sh && rm -f /tmp/tail-log-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    
    expect << EOF
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/tail-log-remote.sh && rm -f /tmp/tail-log-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    
    echo ""
    echo -e "${YELLOW}下次刷新: ${INTERVAL} 秒后... (按 Ctrl+C 退出)${NC}"
    sleep ${INTERVAL}
done

rm -f "${TEMP_SCRIPT}"

