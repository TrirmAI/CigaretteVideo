#!/bin/bash
# 快速更新前端代码脚本（仅更新静态文件）
# 使用方法: ./update-frontend-simple.sh

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
WVP_CONTAINER="polaris-wvp"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WEB_DIR="${PROJECT_ROOT}/web"
STATIC_DIR="${PROJECT_ROOT}/src/main/resources/static"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}快速更新前端代码${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查Node.js和npm
if ! command -v node &> /dev/null; then
    echo -e "${RED}错误: 未找到 node 命令，请先安装 Node.js${NC}"
    exit 1
fi

if ! command -v npm &> /dev/null; then
    echo -e "${RED}错误: 未找到 npm 命令，请先安装 npm${NC}"
    exit 1
fi

echo -e "${BLUE}Node.js 版本: $(node -v)${NC}"
echo -e "${BLUE}npm 版本: $(npm -v)${NC}"
echo ""

# 检查web目录
if [ ! -d "${WEB_DIR}" ]; then
    echo -e "${RED}错误: 未找到 web 目录: ${WEB_DIR}${NC}"
    exit 1
fi

echo -e "${BLUE}工作目录: ${PROJECT_ROOT}${NC}"
echo -e "${BLUE}前端目录: ${WEB_DIR}${NC}"
echo ""

# 构建前端
echo -e "${BLUE}开始构建前端代码...${NC}"
cd "${WEB_DIR}"

# 安装依赖（如果需要）
if [ ! -d "node_modules" ]; then
    echo -e "${YELLOW}未找到 node_modules，开始安装依赖...${NC}"
    npm install --registry=https://registry.npmmirror.com
fi

# 构建生产版本
echo -e "${BLUE}执行构建命令: npm run build:prod${NC}"
npm run build:prod

if [ $? -ne 0 ]; then
    echo -e "${RED}前端构建失败！${NC}"
    exit 1
fi

echo -e "${GREEN}✓ 前端构建完成${NC}"
echo ""

# 检查构建产物
if [ ! -d "${STATIC_DIR}" ]; then
    echo -e "${RED}错误: 未找到构建产物目录: ${STATIC_DIR}${NC}"
    exit 1
fi

echo -e "${BLUE}构建产物目录: ${STATIC_DIR}${NC}"
echo -e "${BLUE}文件列表:${NC}"
ls -lh "${STATIC_DIR}" | head -10
echo ""

# 打包静态文件
TEMP_TAR="/tmp/wvp-static-$(date +%Y%m%d_%H%M%S).tar.gz"
echo -e "${BLUE}打包静态文件...${NC}"
cd "${PROJECT_ROOT}/src/main/resources"
tar czf "${TEMP_TAR}" static/
echo -e "${GREEN}✓ 打包完成: ${TEMP_TAR}${NC}"
echo ""

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect 来传输文件${NC}"
    exit 1
fi

# 传输到远程服务器
echo -e "${BLUE}传输文件到远程服务器...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no "${TEMP_TAR}" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/" &>/dev/null
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 120
spawn scp -o StrictHostKeyChecking=no "${TEMP_TAR}" ${REMOTE_USER}@${REMOTE_HOST}:/tmp/
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

REMOTE_TAR="/tmp/$(basename ${TEMP_TAR})"
echo -e "${GREEN}✓ 文件已传输到远程服务器${NC}"
echo ""

# 提示用户
echo -e "${YELLOW}注意: 由于前端文件打包在JAR中，有以下两种更新方式：${NC}"
echo ""
echo "方式1: 重新构建WVP镜像（推荐，永久生效）"
echo "  1. 在远程服务器上重新构建WVP项目"
echo "  2. 重新构建Docker镜像"
echo "  3. 重启容器"
echo ""
echo "方式2: 临时替换（快速，容器重启后失效）"
echo "  需要解压jar包、替换文件、重新打包，操作较复杂"
echo ""
read -p "是否继续使用方式1重新构建? (y/n, 默认y): " rebuild
rebuild=${rebuild:-y}

if [ "$rebuild" = "y" ] || [ "$rebuild" = "Y" ]; then
    echo -e "${BLUE}开始重新构建WVP服务...${NC}"
    
    # 在远程服务器上执行构建
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
            "cd ${REMOTE_DEPLOY_DIR} && \
             echo '传输web目录...' && \
             mkdir -p /tmp/wvp-update && \
             tar xzf ${REMOTE_TAR} -C /tmp/wvp-update && \
             echo '静态文件已解压到 /tmp/wvp-update/static' && \
             echo '请手动执行以下步骤完成更新：' && \
             echo '1. 将静态文件复制到项目目录' && \
             echo '2. 重新构建项目: mvn clean package -Dmaven.test.skip=true' && \
             echo '3. 重新构建Docker镜像' && \
             echo '4. 重启WVP容器'" 2>&1
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 300
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && mkdir -p /tmp/wvp-update && tar xzf ${REMOTE_TAR} -C /tmp/wvp-update && echo '静态文件已解压到 /tmp/wvp-update/static'"
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
    echo -e "${YELLOW}由于需要重新构建Java项目，请手动完成以下步骤：${NC}"
    echo ""
    echo "1. SSH到远程服务器:"
    echo "   ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo ""
    echo "2. 将静态文件复制到项目目录:"
    echo "   cp -r /tmp/wvp-update/static /path/to/wvp-GB28181-pro/src/main/resources/"
    echo ""
    echo "3. 重新构建项目:"
    echo "   cd /path/to/wvp-GB28181-pro"
    echo "   mvn clean package -Dmaven.test.skip=true"
    echo ""
    echo "4. 重新构建Docker镜像:"
    echo "   cd docker"
    echo "   docker build -t localhost/wvp-pro:latest -f wvp/Dockerfile .."
    echo ""
    echo "5. 重启WVP容器:"
    echo "   docker restart ${WVP_CONTAINER}"
    echo ""
else
    echo -e "${YELLOW}已取消，静态文件已传输到: ${REMOTE_TAR}${NC}"
fi

# 清理本地临时文件
rm -f "${TEMP_TAR}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}前端文件已准备完成！${NC}"
echo -e "${GREEN}========================================${NC}"

