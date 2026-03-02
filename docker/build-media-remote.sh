#!/bin/bash
# 在远程服务器构建流媒体服务器镜像

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
PROXY_HOST="${1:-172.31.127.42}"
PROXY_PORT="${2:-7890}"
PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}在远程服务器构建流媒体服务器镜像${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}创建临时目录: ${TEMP_DIR}${NC}"

# 检查远程是否已有项目文件
SKIP_UPLOAD=false
if command -v sshpass &> /dev/null; then
    REMOTE_HAS_FILES=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "test -d ${REMOTE_BUILD_DIR}/docker/media && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")
elif command -v expect &> /dev/null; then
    REMOTE_HAS_FILES=$(expect << EOF 2>/dev/null | grep -E "^yes$|^no$" | tail -1 || echo "no"
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "test -d ${REMOTE_BUILD_DIR}/docker/media && echo 'yes' || echo 'no'"
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

if [ "$REMOTE_HAS_FILES" = "yes" ]; then
    echo -e "${YELLOW}检测到远程服务器已有项目文件，跳过文件传输${NC}"
    SKIP_UPLOAD=true
else
    echo -e "${BLUE}准备项目文件...${NC}"
    PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    cd "${PROJECT_ROOT}"

    # 创建构建包（只包含 media 目录）
    tar --exclude='.git' \
        --exclude='node_modules' \
        --exclude='target' \
        --exclude='logs' \
        --exclude='*.log' \
        --exclude='.idea' \
        --exclude='.vscode' \
        -czf "${TEMP_DIR}/media-project.tar.gz" \
        -C "${PROJECT_ROOT}" docker/media

    echo -e "${GREEN}✓ 项目文件打包完成${NC}"
fi
echo ""

# 创建远程构建脚本
cat > "${TEMP_DIR}/remote-build-media.sh" << 'REMOTE_SCRIPT'
#!/bin/bash
set -e

BUILD_DIR="/home/wvp/build"
PROJECT_DIR="${BUILD_DIR}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}开始构建流媒体服务器镜像${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查Docker
if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    echo -e "${RED}错误: 未找到 docker 或 podman${NC}"
    exit 1
fi

DOCKER_CMD=""
if command -v docker &> /dev/null; then
    DOCKER_CMD="docker"
elif command -v podman &> /dev/null; then
    DOCKER_CMD="podman"
fi

echo -e "${BLUE}使用命令: ${DOCKER_CMD}${NC}"
echo ""

# 解压项目文件（如果需要）
if [ -f docker/media-project.tar.gz ]; then
    echo -e "${BLUE}解压项目文件...${NC}"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    tar -xzf docker/media-project.tar.gz -C docker/
    echo -e "${GREEN}✓ 解压完成${NC}"
    echo ""
else
    echo -e "${BLUE}使用现有项目文件...${NC}"
    cd "${BUILD_DIR}"
    echo -e "${GREEN}✓ 项目文件已就绪${NC}"
    echo ""
fi

# 配置代理（如果提供）
PROXY_ARGS=""
if [ -n "${PROXY_URL}" ]; then
    echo -e "${BLUE}配置代理: ${PROXY_URL}${NC}"
    export http_proxy="${PROXY_URL}"
    export https_proxy="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    PROXY_ARGS="--build-arg http_proxy=${PROXY_URL}"
    PROXY_ARGS="${PROXY_ARGS} --build-arg https_proxy=${PROXY_URL}"
    PROXY_ARGS="${PROXY_ARGS} --build-arg HTTP_PROXY=${PROXY_URL}"
    PROXY_ARGS="${PROXY_ARGS} --build-arg HTTPS_PROXY=${PROXY_URL}"
    echo -e "${GREEN}✓ 代理环境变量已设置${NC}"
fi

# 构建流媒体服务器镜像
echo -e "${BLUE}开始构建流媒体服务器镜像...${NC}"
cd "${PROJECT_DIR}/docker/media"

# 构建镜像（使用代理）
${DOCKER_CMD} build \
    ${PROXY_ARGS} \
    -f Dockerfile \
    -t polaris-media:latest \
    -t polaris-media:2.7.4 \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 流媒体服务器镜像构建成功${NC}"
else
    echo -e "${RED}✗ 流媒体服务器镜像构建失败${NC}"
    exit 1
fi

echo ""

# 显示构建的镜像
echo -e "${BLUE}构建的镜像:${NC}"
${DOCKER_CMD} images | grep -E "polaris-media" || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
REMOTE_SCRIPT

# 添加代理配置到远程脚本
if [ -n "$PROXY_URL" ]; then
    sed -i.bak "s|PROXY_URL=|PROXY_URL=${PROXY_URL}|" "${TEMP_DIR}/remote-build-media.sh"
    rm -f "${TEMP_DIR}/remote-build-media.sh.bak"
fi

chmod +x "${TEMP_DIR}/remote-build-media.sh"

# 传输文件到远程服务器
if [ "$SKIP_UPLOAD" = "true" ]; then
    echo -e "${BLUE}只传输构建脚本...${NC}"
    FILES_TO_UPLOAD="${TEMP_DIR}/remote-build-media.sh"
else
    echo -e "${BLUE}传输文件到远程服务器...${NC}"
    FILES_TO_UPLOAD="${TEMP_DIR}/media-project.tar.gz ${TEMP_DIR}/remote-build-media.sh"
fi

if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BUILD_DIR}/docker/media"
    
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        ${FILES_TO_UPLOAD} \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/docker/"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 600
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_BUILD_DIR}/docker/media"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn bash -c "scp -o StrictHostKeyChecking=no ${FILES_TO_UPLOAD} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/docker/"
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
    if [ "$SKIP_UPLOAD" = "true" ]; then
        echo -e "${GREEN}✓ 构建脚本传输成功${NC}"
    else
        echo -e "${GREEN}✓ 文件传输成功${NC}"
    fi
else
    echo -e "${RED}✗ 文件传输失败${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

echo ""

# 创建后台构建脚本
cat > "${TEMP_DIR}/start-background-build-media.sh" << 'BG_SCRIPT'
#!/bin/bash
BUILD_DIR="/home/wvp/build"
cd "${BUILD_DIR}"

# 保存PID和日志
echo $$ > build-media.pid
exec > build-media.log 2>&1

# 执行构建
PROXY_URL="${PROXY_URL}" bash docker/remote-build-media.sh

# 构建完成后删除PID文件
rm -f build-media.pid
BG_SCRIPT

chmod +x "${TEMP_DIR}/start-background-build-media.sh"

# 传输后台构建脚本
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        "${TEMP_DIR}/start-background-build-media.sh" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${TEMP_DIR}/start-background-build-media.sh ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

# 启动后台构建
echo -e "${BLUE}启动后台构建进程...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "cd ${REMOTE_BUILD_DIR} && PROXY_URL='${PROXY_URL}' nohup bash start-background-build-media.sh > /dev/null 2>&1 &"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_BUILD_DIR} && PROXY_URL='${PROXY_URL}' nohup bash start-background-build-media.sh > /dev/null 2>&1 &"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

rm -rf "${TEMP_DIR}"

echo -e "${GREEN}✓ 构建任务已在后台启动${NC}"
echo ""
echo -e "${YELLOW}查看构建进度的方法:${NC}"
echo -e "  1. 查看日志: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ${REMOTE_BUILD_DIR}/build-media.log'"
echo -e "  2. 检查状态: ssh ${REMOTE_USER}@${REMOTE_HOST} 'ps aux | grep build-media'"
echo ""

