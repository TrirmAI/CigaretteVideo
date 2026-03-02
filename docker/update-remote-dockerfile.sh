#!/bin/bash
# 更新远程 Dockerfile

REMOTE_HOST="172.31.127.47"
REMOTE_USER="root"
REMOTE_PASSWORD="Shenzhoulu9#"
REMOTE_BUILD_DIR="/home/wvp/build"

echo "更新远程 Dockerfile..."

expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${REMOTE_BUILD_DIR}/wvp/Dockerfile ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/docker/wvp/Dockerfile
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF

echo "✓ Dockerfile 已更新"

