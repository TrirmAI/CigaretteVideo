#!/bin/bash
# 在远程服务器上重新构建AMD64架构的镜像
# 使用方法: ./rebuild-images-remote.sh

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
REMOTE_BUILD_DIR="/home/wvp/build"
REMOTE_DOCKER_DIR="/home/wvp/docker"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}在远程服务器上重新构建AMD64镜像${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}远程服务器: ${REMOTE_USER}@${REMOTE_HOST}${NC}"
echo -e "${BLUE}构建目录: ${REMOTE_BUILD_DIR}${NC}"
echo ""

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

# 检查远程服务器连接
echo -e "${BLUE}检查远程服务器连接...${NC}"
if command -v sshpass &> /dev/null; then
    if ! sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 \
        "${REMOTE_USER}@${REMOTE_HOST}" "echo '连接成功'" &>/dev/null; then
        echo -e "${RED}错误: 无法连接到远程服务器${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ 远程服务器连接正常${NC}"
echo ""

# 检查远程服务器架构
echo -e "${BLUE}检查远程服务器架构...${NC}"
if command -v sshpass &> /dev/null; then
    ARCH=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "uname -m")
elif command -v expect &> /dev/null; then
    ARCH=$(expect << EOF
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "uname -m"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    )
fi

echo -e "${BLUE}远程服务器架构: ${ARCH}${NC}"

if [ "$ARCH" != "x86_64" ] && [ "$ARCH" != "amd64" ]; then
    echo -e "${YELLOW}警告: 远程服务器架构为 ${ARCH}，可能需要特殊处理${NC}"
fi
echo ""

# 停止现有容器
echo -e "${BLUE}停止现有容器...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "cd ${REMOTE_DOCKER_DIR} && docker stop polaris-redis polaris-mysql polaris-media polaris-wvp 2>/dev/null || true"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DOCKER_DIR} && docker stop polaris-redis polaris-mysql polaris-media polaris-wvp 2>/dev/null || true"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi
echo -e "${GREEN}✓ 容器已停止${NC}"
echo ""

# 使用官方镜像（快速方案）
echo -e "${BLUE}方案1: 使用官方镜像（推荐，快速）${NC}"
echo -e "${YELLOW}这将使用Docker Hub上的官方镜像，确保架构匹配${NC}"
echo ""

read -p "是否使用官方镜像？(y/n，默认y): " USE_OFFICIAL
USE_OFFICIAL=${USE_OFFICIAL:-y}

if [ "$USE_OFFICIAL" = "y" ] || [ "$USE_OFFICIAL" = "Y" ]; then
    echo -e "${BLUE}拉取官方镜像...${NC}"
    
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no -t \
            "${REMOTE_USER}@${REMOTE_HOST}" << 'REMOTE_SCRIPT'
cd /home/wvp/docker
echo "拉取Redis镜像..."
docker pull redis:latest
echo "拉取MySQL镜像..."
docker pull mysql:8
echo "拉取ZLMediaKit镜像..."
docker pull zlmediakit/zlmediakit:master
echo "镜像拉取完成"
docker images | grep -E "redis|mysql|zlmediakit"
REMOTE_SCRIPT
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 300
spawn ssh -o StrictHostKeyChecking=no -t ${REMOTE_USER}@${REMOTE_HOST} "cd /home/wvp/docker && docker pull redis:latest && docker pull mysql:8 && docker pull zlmediakit/zlmediakit:master && docker images | grep -E 'redis|mysql|zlmediakit'"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
    
    echo ""
    echo -e "${YELLOW}注意: WVP镜像需要从源代码构建，请使用构建脚本${NC}"
    echo -e "${BLUE}WVP镜像构建命令:${NC}"
    echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo -e "  cd ${REMOTE_BUILD_DIR}/docker"
    echo -e "  ./build-on-remote.sh"
    echo ""
    
    echo -e "${GREEN}✓ 官方基础镜像已拉取${NC}"
    echo ""
    echo -e "${BLUE}现在可以重新启动服务:${NC}"
    echo -e "  ./start-services-remote.sh start-remote-docker.sh"
else
    echo -e "${BLUE}方案2: 在远程服务器上构建镜像${NC}"
    echo -e "${YELLOW}这需要较长时间，但可以确保所有镜像都是AMD64架构${NC}"
    echo ""
    echo -e "${BLUE}构建命令:${NC}"
    echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo -e "  cd ${REMOTE_BUILD_DIR}/docker"
    echo -e "  ./build-on-remote.sh"
    echo ""
fi

