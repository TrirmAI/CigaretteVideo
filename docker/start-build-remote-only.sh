#!/bin/bash
# 使用远程已有文件启动构建（不传输文件）

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
echo -e "${BLUE}使用远程已有文件启动构建${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 创建远程构建脚本
TEMP_SCRIPT=$(mktemp)
cat > "${TEMP_SCRIPT}" << REMOTE_SCRIPT
#!/bin/bash
set -e

BUILD_DIR="/home/wvp/build"
PROJECT_DIR="\${BUILD_DIR}"
PROXY_URL="${PROXY_URL}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "\${GREEN}========================================\${NC}"
echo -e "\${GREEN}开始构建Docker镜像\${NC}"
echo -e "\${GREEN}========================================\${NC}"
echo ""

# 检查Docker
if ! command -v docker &> /dev/null && ! command -v podman &> /dev/null; then
    echo -e "\${RED}错误: 未找到 docker 或 podman\${NC}"
    exit 1
fi

DOCKER_CMD=""
if command -v docker &> /dev/null; then
    DOCKER_CMD="docker"
elif command -v podman &> /dev/null; then
    DOCKER_CMD="podman"
fi

echo -e "\${BLUE}使用命令: \${DOCKER_CMD}\${NC}"
echo ""

# 检查项目文件是否存在
if [ ! -d "\${PROJECT_DIR}/docker" ] || [ ! -f "\${PROJECT_DIR}/pom.xml" ]; then
    echo -e "\${RED}错误: 项目文件不存在，请先传输文件\${NC}"
    exit 1
fi

echo -e "\${GREEN}✓ 使用现有项目文件\${NC}"
echo ""

# 配置代理（如果提供）
PROXY_ARGS=""
if [ -n "\${PROXY_URL}" ]; then
    echo -e "\${BLUE}配置代理: \${PROXY_URL}\${NC}"
    export http_proxy="\${PROXY_URL}"
    export https_proxy="\${PROXY_URL}"
    export HTTP_PROXY="\${PROXY_URL}"
    export HTTPS_PROXY="\${PROXY_URL}"
    PROXY_ARGS="--build-arg http_proxy=\${PROXY_URL}"
    PROXY_ARGS="\${PROXY_ARGS} --build-arg https_proxy=\${PROXY_URL}"
    PROXY_ARGS="\${PROXY_ARGS} --build-arg HTTP_PROXY=\${PROXY_URL}"
    PROXY_ARGS="\${PROXY_ARGS} --build-arg HTTPS_PROXY=\${PROXY_URL}"
    echo -e "\${GREEN}✓ 代理环境变量已设置\${NC}"
fi

# 构建WVP镜像
echo -e "\${BLUE}开始构建WVP镜像...\${NC}"
cd "\${PROJECT_DIR}"

# 构建镜像
\${DOCKER_CMD} build \\
    \${PROXY_ARGS} \\
    --build-arg MAVEN_OPTS="-Dmaven.repo.local=/root/.m2/repository" \\
    -f docker/wvp/Dockerfile \\
    -t wvp-pro:latest \\
    -t wvp-pro:2.7.4 \\
    .

if [ \$? -eq 0 ]; then
    echo -e "\${GREEN}✓ WVP镜像构建成功\${NC}"
else
    echo -e "\${RED}✗ WVP镜像构建失败\${NC}"
    exit 1
fi

echo ""

# 显示构建的镜像
echo -e "\${BLUE}构建的镜像:\${NC}"
\${DOCKER_CMD} images | grep -E "wvp-pro|wvp-nginx" || true

echo ""
echo -e "\${GREEN}========================================\${NC}"
echo -e "\${GREEN}构建完成！\${NC}"
echo -e "\${GREEN}========================================\${NC}"
REMOTE_SCRIPT

chmod +x "${TEMP_SCRIPT}"

# 创建后台构建脚本
cat > "${TEMP_SCRIPT}.bg" << BG_SCRIPT
#!/bin/bash
BUILD_DIR="/home/wvp/build"
cd "\${BUILD_DIR}"

# 保存PID和日志
echo \$\$ > build.pid
exec > build.log 2>&1

# 执行构建
bash remote-build-direct.sh

# 构建完成后删除PID文件
rm -f build.pid
BG_SCRIPT

# 传输构建脚本
echo -e "${BLUE}传输构建脚本到远程服务器...${NC}"
expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no ${TEMP_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/remote-build-direct.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn scp -o StrictHostKeyChecking=no ${TEMP_SCRIPT}.bg ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/start-background-build.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF

# 启动后台构建
echo -e "${BLUE}启动后台构建进程...${NC}"
expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_BUILD_DIR} && chmod +x remote-build-direct.sh start-background-build.sh && PROXY_URL='${PROXY_URL}' nohup bash start-background-build.sh > /dev/null 2>&1 &"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF

rm -f "${TEMP_SCRIPT}" "${TEMP_SCRIPT}.bg"

echo -e "${GREEN}✓ 构建任务已在后台启动${NC}"
echo ""
echo -e "${YELLOW}查看构建进度的方法:${NC}"
echo -e "  1. 使用检查脚本: ./check-build-status.sh"
echo -e "  2. 实时查看日志: ./watch-build-log.sh"
echo -e "  3. 手动查看: ssh ${REMOTE_USER}@${REMOTE_HOST} 'tail -f ${REMOTE_BUILD_DIR}/build.log'"
echo ""

