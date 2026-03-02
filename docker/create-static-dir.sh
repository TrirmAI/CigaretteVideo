#!/bin/bash
# 创建前端静态文件目录结构
# 使用方法: ./create-static-dir.sh

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
REMOTE_STATIC_DIR="${REMOTE_DEPLOY_DIR}/volumes/wvp/static"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}创建前端静态文件目录结构${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect 来执行远程命令${NC}"
    exit 1
fi

# 创建完整的目录结构
echo -e "${BLUE}创建目录结构...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
        "cd ${REMOTE_DEPLOY_DIR} && \
         echo '创建目录: ${REMOTE_STATIC_DIR}/static' && \
         mkdir -p ${REMOTE_STATIC_DIR}/static && \
         echo '设置权限...' && \
         chmod -R 755 ${REMOTE_STATIC_DIR} && \
         echo '验证目录结构...' && \
         echo '' && \
         echo '目录结构:' && \
         tree -L 3 ${REMOTE_DEPLOY_DIR}/volumes/wvp/ 2>/dev/null || find ${REMOTE_DEPLOY_DIR}/volumes/wvp/ -type d | sort && \
         echo '' && \
         echo '目录权限:' && \
         ls -ld ${REMOTE_STATIC_DIR} && \
         ls -ld ${REMOTE_STATIC_DIR}/static && \
         echo '' && \
         echo '目录创建完成！'" 2>&1
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 60
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && mkdir -p ${REMOTE_STATIC_DIR}/static && chmod -R 755 ${REMOTE_STATIC_DIR} && echo '目录结构:' && find volumes/wvp/ -type d | sort && echo '' && echo '目录权限:' && ls -ld ${REMOTE_STATIC_DIR} && ls -ld ${REMOTE_STATIC_DIR}/static && echo '目录创建完成！'"
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
echo -e "${GREEN}✓ 目录结构已创建${NC}"
echo ""
echo -e "${BLUE}目录路径:${NC}"
echo -e "  宿主机: ${REMOTE_STATIC_DIR}/static/"
echo -e "  容器内: /opt/wvp/static/static/"
echo ""
echo -e "${YELLOW}下一步: 运行 ./deploy-frontend.sh 部署前端文件${NC}"

