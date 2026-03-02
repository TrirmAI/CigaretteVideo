#!/bin/bash
# 显示远程服务器构建日志

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
LOG_LINES="${1:-100}"  # 默认显示最后100行

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}显示远程构建日志（最后 ${LOG_LINES} 行）${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 创建临时远程脚本
TEMP_SCRIPT=$(mktemp)
cat > "${TEMP_SCRIPT}" << 'REMOTE_SCRIPT'
cd /home/wvp/build
if [ -f build.log ]; then
    tail -n ${LOG_LINES} build.log
else
    echo "构建日志文件不存在"
fi
REMOTE_SCRIPT

# 替换 LOG_LINES 变量
sed -i.bak "s/\${LOG_LINES}/${LOG_LINES}/" "${TEMP_SCRIPT}"
rm -f "${TEMP_SCRIPT}.bak"

# 传输并执行脚本
expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${TEMP_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/show-build-log-remote.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/show-build-log-remote.sh && rm -f /tmp/show-build-log-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF

rm -f "${TEMP_SCRIPT}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}提示:${NC}"
echo -e "  显示更多行: ./show-build-log.sh 200"
echo -e "  实时查看: ./watch-build-log.sh"
echo -e "  查看状态: ./check-build-status.sh"
echo -e "${BLUE}========================================${NC}"

