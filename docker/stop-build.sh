#!/bin/bash
# 停止远程构建进程

REMOTE_HOST="172.31.127.47"
REMOTE_USER="root"
REMOTE_PASSWORD="Shenzhoulu9#"
REMOTE_BUILD_DIR="/home/wvp/build"

TEMP_SCRIPT=$(mktemp)
cat > "${TEMP_SCRIPT}" << 'REMOTE_SCRIPT'
cd /home/wvp/build
if [ -f build.pid ]; then
    PID=$(cat build.pid)
    if ps -p $PID > /dev/null 2>&1; then
        echo "停止构建进程 PID: $PID"
        kill $PID
        sleep 2
        rm -f build.pid
        echo "已停止"
    else
        echo "进程不存在，清理PID文件"
        rm -f build.pid
    fi
else
    echo "未找到build.pid文件"
fi
REMOTE_SCRIPT

expect << EOF
set timeout 10
spawn scp -o StrictHostKeyChecking=no ${TEMP_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/stop-build-remote.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/stop-build-remote.sh && rm -f /tmp/stop-build-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF

rm -f "${TEMP_SCRIPT}"

