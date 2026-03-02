#!/bin/bash
# 部署配置文件到远程服务器
# 使用方法: ./deploy-to-remote.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 远端服务器配置
REMOTE_HOST="172.31.127.47"
REMOTE_USER="root"
REMOTE_PASSWORD="Shenzhoulu9#"
REMOTE_DEPLOY_DIR="/home/wvp/docker"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署配置文件到远程服务器${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查必要的文件
REQUIRED_FILES=(
    "docker-compose-remote.yml"
    "start-remote.sh"
)

MISSING_FILES=()
for file in "${REQUIRED_FILES[@]}"; do
    if [ ! -f "${file}" ]; then
        MISSING_FILES+=("${file}")
    fi
done

if [ ${#MISSING_FILES[@]} -gt 0 ]; then
    echo -e "${RED}错误: 以下文件不存在:${NC}"
    for file in "${MISSING_FILES[@]}"; do
        echo -e "  - ${file}"
    done
    exit 1
fi

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}创建临时目录: ${TEMP_DIR}${NC}"

# 复制文件到临时目录
echo -e "${BLUE}准备文件...${NC}"
cp docker-compose-remote.yml "${TEMP_DIR}/"
cp start-remote.sh "${TEMP_DIR}/"

# 复制media配置（如果存在）
if [ -d "media" ]; then
    mkdir -p "${TEMP_DIR}/media"
    cp media/config.ini "${TEMP_DIR}/media/" 2>/dev/null || true
fi

# 复制wvp配置（如果存在）
if [ -d "wvp/wvp" ]; then
    mkdir -p "${TEMP_DIR}/wvp/wvp"
    cp wvp/wvp/application.yml "${TEMP_DIR}/wvp/wvp/" 2>/dev/null || true
    cp wvp/wvp/application-docker.yml "${TEMP_DIR}/wvp/wvp/" 2>/dev/null || true
    cp wvp/wvp/application-base.yml "${TEMP_DIR}/wvp/wvp/" 2>/dev/null || true
fi

# 复制README
if [ -f "REMOTE_DEPLOY.md" ]; then
    cp REMOTE_DEPLOY.md "${TEMP_DIR}/"
fi

echo -e "${GREEN}✓ 文件准备完成${NC}"
echo ""

# 传输文件到远程服务器
echo -e "${BLUE}传输文件到远程服务器...${NC}"

if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_DEPLOY_DIR}"
    
    sshpass -p "${REMOTE_PASSWORD}" scp -r -o StrictHostKeyChecking=no \
        "${TEMP_DIR}"/* "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DEPLOY_DIR}/"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 300
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_DEPLOY_DIR}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn bash -c "scp -r -o StrictHostKeyChecking=no ${TEMP_DIR}/* ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DEPLOY_DIR}/"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 文件传输成功${NC}"
else
    echo -e "${RED}✗ 文件传输失败${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# 清理临时目录
rm -rf "${TEMP_DIR}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}下一步操作:${NC}"
echo -e "1. SSH连接到远程服务器:"
echo -e "   ssh ${REMOTE_USER}@${REMOTE_HOST}"
echo ""
echo -e "2. 进入部署目录:"
echo -e "   cd ${REMOTE_DEPLOY_DIR}"
echo ""
echo -e "3. 编辑配置文件（如需要）:"
echo -e "   vi .env  # 配置SIP参数"
echo ""
echo -e "4. 运行启动脚本:"
echo -e "   ./start-remote.sh"
echo ""

