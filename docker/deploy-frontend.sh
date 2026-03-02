#!/bin/bash
# 部署前端文件到宿主机目录
# 使用方法: ./deploy-frontend.sh

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

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WEB_DIR="${PROJECT_ROOT}/web"
STATIC_DIR="${PROJECT_ROOT}/src/main/resources/static"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署前端文件到宿主机目录${NC}"
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

# 询问是否重新构建
read -p "是否重新构建前端代码? (y/n, 默认y): " rebuild
rebuild=${rebuild:-y}

if [ "$rebuild" = "y" ] || [ "$rebuild" = "Y" ]; then
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
else
    echo -e "${YELLOW}跳过构建步骤${NC}"
    echo ""
fi

# 检查构建产物
if [ ! -d "${STATIC_DIR}" ]; then
    echo -e "${RED}错误: 未找到构建产物目录: ${STATIC_DIR}${NC}"
    echo -e "${YELLOW}请先执行构建: cd web && npm run build:prod${NC}"
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

# 解压并部署到静态文件目录
echo -e "${BLUE}部署静态文件到宿主机目录...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
        "cd ${REMOTE_DEPLOY_DIR} && \
         echo '创建目录结构...' && \
         mkdir -p ${REMOTE_STATIC_DIR}/static && \
         echo '备份现有文件...' && \
         [ -d ${REMOTE_STATIC_DIR}/static ] && [ \"\$(ls -A ${REMOTE_STATIC_DIR}/static 2>/dev/null)\" ] && mv ${REMOTE_STATIC_DIR}/static ${REMOTE_STATIC_DIR}/static.backup.\$(date +%Y%m%d_%H%M%S) && mkdir -p ${REMOTE_STATIC_DIR}/static || true && \
         echo '解压新文件...' && \
         tar xzf ${REMOTE_TAR} -C ${REMOTE_STATIC_DIR} && \
         echo '设置权限...' && \
         chmod -R 755 ${REMOTE_STATIC_DIR}/static && \
         rm -f ${REMOTE_TAR} && \
         echo '部署完成！' && \
         echo '验证文件...' && \
         ls -la ${REMOTE_STATIC_DIR}/static/ | head -5" 2>&1
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 300
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && mkdir -p ${REMOTE_STATIC_DIR}/static && ([ -d ${REMOTE_STATIC_DIR}/static ] && [ \"\$(ls -A ${REMOTE_STATIC_DIR}/static 2>/dev/null)\" ] && mv ${REMOTE_STATIC_DIR}/static ${REMOTE_STATIC_DIR}/static.backup.\$(date +%Y%m%d_%H%M%S) && mkdir -p ${REMOTE_STATIC_DIR}/static || true) && tar xzf ${REMOTE_TAR} -C ${REMOTE_STATIC_DIR} && chmod -R 755 ${REMOTE_STATIC_DIR}/static && rm -f ${REMOTE_TAR} && echo '部署完成！' && ls -la ${REMOTE_STATIC_DIR}/static/ | head -5"
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
echo -e "${GREEN}✓ 前端文件已部署到: ${REMOTE_STATIC_DIR}/static${NC}"
echo ""

# 提示重启服务
echo -e "${YELLOW}注意: 如果WVP服务正在运行，需要重启容器以加载新的前端文件${NC}"
read -p "是否现在重启WVP服务? (y/n, 默认y): " restart
restart=${restart:-y}

if [ "$restart" = "y" ] || [ "$restart" = "Y" ]; then
    echo -e "${BLUE}重启WVP服务...${NC}"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
            "docker restart polaris-wvp && echo 'WVP服务已重启'" 2>&1
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 60
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "docker restart polaris-wvp && echo 'WVP服务已重启'"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
    echo -e "${GREEN}✓ WVP服务已重启${NC}"
fi

# 清理本地临时文件
rm -f "${TEMP_TAR}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}前端部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}前端文件位置: ${REMOTE_STATIC_DIR}/static${NC}"
echo -e "${BLUE}访问地址: http://${REMOTE_HOST}:18978${NC}"
echo ""
echo -e "${YELLOW}提示: 以后更新前端只需运行此脚本，无需重新构建JAR包${NC}"

