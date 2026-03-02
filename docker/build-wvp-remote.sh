#!/bin/bash
# 远程服务器构建WVP镜像脚本
# 使用方法: ./build-wvp-remote.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 远程服务器配置
REMOTE_HOST="172.31.127.47"
REMOTE_USER="root"
REMOTE_PASSWORD="Shenzhoulu9#"
REMOTE_DEPLOY_DIR="/home/wvp/docker"
REMOTE_PROJECT_DIR="/home/wvp/wvp-GB28181-pro"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}远程服务器构建WVP镜像${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect 来连接远程服务器${NC}"
    echo "macOS安装: brew install sshpass 或 brew install expect"
    exit 1
fi

# SSH连接函数
ssh_cmd() {
    local cmd="$1"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "$cmd"
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 120
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "$cmd"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
}

# SCP传输函数
scp_cmd() {
    local src="$1"
    local dst="$2"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no -r "$src" "${REMOTE_USER}@${REMOTE_HOST}:${dst}"
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 300
spawn scp -o StrictHostKeyChecking=no -r "$src" ${REMOTE_USER}@${REMOTE_HOST}:${dst}
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
}

echo -e "${BLUE}1. 检查远程服务器连接...${NC}"
if ssh_cmd "echo '连接成功'"; then
    echo -e "${GREEN}✓ 远程服务器连接正常${NC}"
else
    echo -e "${RED}✗ 无法连接到远程服务器${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}2. 在远程服务器上创建项目目录...${NC}"
ssh_cmd "mkdir -p ${REMOTE_PROJECT_DIR}"
echo -e "${GREEN}✓ 目录创建完成${NC}"
echo ""

echo -e "${BLUE}3. 打包项目文件...${NC}"
TEMP_TAR="/tmp/wvp-build-$(date +%Y%m%d_%H%M%S).tar.gz"
cd "${PROJECT_ROOT}"
# 排除不需要的文件
tar czf "${TEMP_TAR}" \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='target' \
    --exclude='.idea' \
    --exclude='*.iml' \
    --exclude='.DS_Store' \
    --exclude='logs' \
    --exclude='snap' \
    --exclude='.cursor' \
    .
echo -e "${GREEN}✓ 打包完成: ${TEMP_TAR}${NC}"
echo ""

echo -e "${BLUE}4. 传输项目文件到远程服务器...${NC}"
scp_cmd "${TEMP_TAR}" "/tmp/"
REMOTE_TAR="/tmp/$(basename ${TEMP_TAR})"
echo -e "${GREEN}✓ 文件传输完成${NC}"
echo ""

echo -e "${BLUE}5. 在远程服务器上解压文件...${NC}"
ssh_cmd "cd ${REMOTE_PROJECT_DIR} && tar xzf ${REMOTE_TAR} && rm -f ${REMOTE_TAR}"
echo -e "${GREEN}✓ 文件解压完成${NC}"
echo ""

echo -e "${BLUE}6. 在远程服务器上构建Docker镜像...${NC}"
echo -e "${YELLOW}这可能需要几分钟时间，请耐心等待...${NC}"
ssh_cmd "cd ${REMOTE_PROJECT_DIR} && docker build -f docker/wvp/Dockerfile -t polaris-wvp:latest ." || {
    echo -e "${RED}✗ Docker镜像构建失败${NC}"
    echo -e "${YELLOW}请检查远程服务器上的构建日志${NC}"
    exit 1
}
echo -e "${GREEN}✓ Docker镜像构建成功${NC}"
echo ""

echo -e "${BLUE}7. 清理临时文件...${NC}"
rm -f "${TEMP_TAR}"
ssh_cmd "rm -f ${REMOTE_TAR}"
echo -e "${GREEN}✓ 清理完成${NC}"
echo ""

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}下一步操作：${NC}"
echo "1. 在远程服务器上重启WVP容器："
echo "   docker restart polaris-wvp"
echo ""
echo "2. 或者使用docker-compose重新部署："
echo "   cd ${REMOTE_DEPLOY_DIR}"
echo "   docker-compose up -d polaris-wvp"
echo ""

