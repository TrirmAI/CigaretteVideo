#!/bin/bash
# 在远程服务器上构建Docker镜像脚本
# 使用方法: ./build-on-remote.sh [代理服务器地址]

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

# 代理配置（从参数或环境变量获取）
# 使用方法: ./build-on-remote.sh [代理服务器IP] [代理端口]
# 例如: ./build-on-remote.sh 192.168.1.100 7890
PROXY_HOST="${1:-${PROXY_HOST}}"
PROXY_PORT="${2:-${PROXY_PORT:-7890}}"
PROXY_URL=""
if [ -n "$PROXY_HOST" ]; then
    PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
    echo -e "${BLUE}使用代理: ${PROXY_URL}${NC}"
else
    echo -e "${YELLOW}未配置代理，将直接使用国内镜像源${NC}"
fi

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}在远程服务器上构建Docker镜像${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查必要的工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

# 创建临时目录
TEMP_DIR=$(mktemp -d)
echo -e "${BLUE}创建临时目录: ${TEMP_DIR}${NC}"

# 检查远程是否已有项目文件
SKIP_UPLOAD=false
if command -v sshpass &> /dev/null; then
    REMOTE_HAS_FILES=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "test -d ${REMOTE_BUILD_DIR}/docker && test -f ${REMOTE_BUILD_DIR}/pom.xml && echo 'yes' || echo 'no'" 2>/dev/null || echo "no")
elif command -v expect &> /dev/null; then
    REMOTE_HAS_FILES=$(expect << EOF 2>/dev/null | grep -E "^yes$|^no$" | tail -1 || echo "no"
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "test -d ${REMOTE_BUILD_DIR}/docker && test -f ${REMOTE_BUILD_DIR}/pom.xml && echo 'yes' || echo 'no'"
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
    cd "${PROJECT_ROOT}"

    # 创建构建包（排除不必要的文件）
    tar --exclude='.git' \
        --exclude='node_modules' \
        --exclude='target' \
        --exclude='logs' \
        --exclude='*.log' \
        --exclude='.idea' \
        --exclude='.vscode' \
        -czf "${TEMP_DIR}/wvp-project.tar.gz" \
        -C "${PROJECT_ROOT}" .

    echo -e "${GREEN}✓ 项目文件打包完成${NC}"
fi
echo ""

# 创建远程构建脚本
cat > "${TEMP_DIR}/remote-build.sh" << 'REMOTE_SCRIPT'
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
echo -e "${GREEN}开始构建Docker镜像${NC}"
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
if [ -f wvp-project.tar.gz ]; then
    echo -e "${BLUE}解压项目文件...${NC}"
    mkdir -p "${BUILD_DIR}"
    cd "${BUILD_DIR}"
    tar -xzf wvp-project.tar.gz
    echo -e "${GREEN}✓ 解压完成${NC}"
    echo ""
else
    echo -e "${BLUE}使用现有项目文件...${NC}"
    cd "${BUILD_DIR}"
    echo -e "${GREEN}✓ 项目文件已就绪${NC}"
    echo ""
fi

# 配置Docker/Podman镜像源和代理
echo -e "${BLUE}配置Docker/Podman镜像源和代理...${NC}"

# 配置Docker镜像源
mkdir -p /etc/docker
cat > /etc/docker/daemon.json << 'DOCKER_CONFIG'
{
  "registry-mirrors": [
    "https://docker.mirrors.ustc.edu.cn",
    "https://hub-mirror.c.163.com",
    "https://mirror.baidubce.com"
  ]
}
DOCKER_CONFIG

# 配置Podman代理（如果使用podman）
if command -v podman &> /dev/null; then
    mkdir -p /etc/containers
    if [ -n "${PROXY_URL}" ]; then
        PROXY_HOST=$(echo ${PROXY_URL} | sed 's|http://||' | sed 's|https://||' | cut -d: -f1)
        PROXY_PORT=$(echo ${PROXY_URL} | sed 's|http://||' | sed 's|https://||' | cut -d: -f2 | cut -d/ -f1)
        cat > /etc/containers/systemd.conf << PODMAN_PROXY
[containers]
http_proxy="${PROXY_URL}"
https_proxy="${PROXY_URL}"
no_proxy="localhost,127.0.0.1"
PODMAN_PROXY
        export http_proxy="${PROXY_URL}"
        export https_proxy="${PROXY_URL}"
        export HTTP_PROXY="${PROXY_URL}"
        export HTTPS_PROXY="${PROXY_URL}"
        echo -e "${GREEN}✓ Podman代理配置完成: ${PROXY_URL}${NC}"
    fi
fi

echo -e "${GREEN}✓ Docker/Podman配置完成${NC}"
echo ""

# 配置代理（如果提供）
PROXY_ARGS=""
if [ -n "${PROXY_URL}" ]; then
    echo -e "${BLUE}配置代理: ${PROXY_URL}${NC}"
    # 设置环境变量（podman需要）
    export http_proxy="${PROXY_URL}"
    export https_proxy="${PROXY_URL}"
    export HTTP_PROXY="${PROXY_URL}"
    export HTTPS_PROXY="${PROXY_URL}"
    # Docker构建参数
    PROXY_ARGS="--build-arg http_proxy=${PROXY_URL}"
    PROXY_ARGS="${PROXY_ARGS} --build-arg https_proxy=${PROXY_URL}"
    PROXY_ARGS="${PROXY_ARGS} --build-arg HTTP_PROXY=${PROXY_URL}"
    PROXY_ARGS="${PROXY_ARGS} --build-arg HTTPS_PROXY=${PROXY_URL}"
    echo -e "${GREEN}✓ 代理环境变量已设置${NC}"
fi

# 构建WVP镜像
echo -e "${BLUE}开始构建WVP镜像...${NC}"
cd "${PROJECT_DIR}"

# 构建镜像（使用国内镜像源和代理）
${DOCKER_CMD} build \
    ${PROXY_ARGS} \
    --build-arg MAVEN_OPTS="-Dmaven.repo.local=/root/.m2/repository" \
    -f docker/wvp/Dockerfile \
    -t wvp-pro:latest \
    -t wvp-pro:2.7.4 \
    .

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ WVP镜像构建成功${NC}"
else
    echo -e "${RED}✗ WVP镜像构建失败${NC}"
    exit 1
fi

echo ""

# 构建Nginx镜像（如果需要）
if [ -f "docker/nginx/Dockerfile" ]; then
    echo -e "${BLUE}开始构建Nginx镜像...${NC}"
    ${DOCKER_CMD} build \
        ${PROXY_ARGS} \
        -f docker/nginx/Dockerfile \
        -t wvp-nginx:latest \
        .
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Nginx镜像构建成功${NC}"
    else
        echo -e "${YELLOW}⚠ Nginx镜像构建失败（可选）${NC}"
    fi
    echo ""
fi

# 显示构建的镜像
echo -e "${BLUE}构建的镜像:${NC}"
${DOCKER_CMD} images | grep -E "wvp-pro|wvp-nginx" || true

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}构建完成！${NC}"
echo -e "${GREEN}========================================${NC}"
REMOTE_SCRIPT

# 添加代理配置到远程脚本
if [ -n "$PROXY_URL" ]; then
    sed -i.bak "s|PROXY_URL=|PROXY_URL=${PROXY_URL}|" "${TEMP_DIR}/remote-build.sh"
    rm -f "${TEMP_DIR}/remote-build.sh.bak"
fi

chmod +x "${TEMP_DIR}/remote-build.sh"

# 传输文件到远程服务器
if [ "$SKIP_UPLOAD" = "true" ]; then
    echo -e "${BLUE}只传输构建脚本...${NC}"
    FILES_TO_UPLOAD="${TEMP_DIR}/remote-build.sh"
else
    echo -e "${BLUE}传输文件到远程服务器...${NC}"
    FILES_TO_UPLOAD="${TEMP_DIR}/wvp-project.tar.gz ${TEMP_DIR}/remote-build.sh"
fi

if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "mkdir -p ${REMOTE_BUILD_DIR}"
    
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        ${FILES_TO_UPLOAD} \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 600
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_BUILD_DIR}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn bash -c "scp -o StrictHostKeyChecking=no ${FILES_TO_UPLOAD} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
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

# 在远程服务器上执行构建（后台运行）
echo -e "${BLUE}在远程服务器上启动构建任务...${NC}"
echo -e "${YELLOW}这可能需要较长时间，构建将在后台运行${NC}"
echo ""

# 创建后台构建脚本
cat > "${TEMP_DIR}/start-background-build.sh" << BG_SCRIPT
#!/bin/bash
BUILD_DIR="/home/wvp/build"
cd "\${BUILD_DIR}"

# 保存PID和日志
echo \$\$ > build.pid
exec > build.log 2>&1

# 执行构建
export PROXY_URL="${PROXY_URL}"
bash remote-build.sh

# 构建完成后删除PID文件
rm -f build.pid
BG_SCRIPT

chmod +x "${TEMP_DIR}/start-background-build.sh"

# 传输后台构建脚本
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        "${TEMP_DIR}/start-background-build.sh" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 600
spawn scp -o StrictHostKeyChecking=no ${TEMP_DIR}/start-background-build.sh ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/
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
        "cd ${REMOTE_BUILD_DIR} && PROXY_URL='${PROXY_URL}' nohup bash start-background-build.sh > /dev/null 2>&1 &"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_BUILD_DIR} && PROXY_URL='${PROXY_URL}' nohup bash start-background-build.sh > /dev/null 2>&1 &"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

echo -e "${GREEN}✓ 构建任务已在后台启动${NC}"
echo ""
echo -e "${YELLOW}查看构建进度的方法:${NC}"
echo -e "  1. 使用检查脚本: ./check-build-status.sh"
echo -e "  2. 实时查看日志: ./watch-build-log.sh"
echo -e "  3. 手动查看: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ${REMOTE_BUILD_DIR}/build.log'"
echo ""

# 询问是否立即查看日志
read -p "是否立即查看构建日志? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}显示构建日志（按 Ctrl+C 退出）...${NC}"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
            "${REMOTE_USER}@${REMOTE_HOST}" \
            "tail -f ${REMOTE_BUILD_DIR}/build.log"
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "tail -f ${REMOTE_BUILD_DIR}/build.log"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
fi

BUILD_RESULT=0

# 清理临时目录
rm -rf "${TEMP_DIR}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}构建任务已提交！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}下一步:${NC}"
echo -e "1. 查看构建进度: ./check-build-status.sh"
echo -e "2. 实时查看日志: ./watch-build-log.sh"
echo -e "3. 检查镜像: ssh ${REMOTE_USER}@${REMOTE_HOST} 'docker images | grep wvp'"
echo -e "4. 启动服务: ssh ${REMOTE_USER}@${REMOTE_HOST} 'cd /home/wvp/docker && ./start-remote-docker.sh'"

