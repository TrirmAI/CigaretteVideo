#!/bin/bash
# 手动更新前端代码脚本
# 使用方法: ./update-frontend.sh

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
NGINX_CONTAINER="polaris-nginx"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
WEB_DIR="${PROJECT_ROOT}/web"
DIST_DIR="${WEB_DIR}/dist"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}手动更新前端代码${NC}"
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
if [ ! -d "${DIST_DIR}" ]; then
    echo -e "${RED}错误: 未找到构建产物目录: ${DIST_DIR}${NC}"
    echo -e "${YELLOW}请先执行构建: cd web && npm run build:prod${NC}"
    exit 1
fi

echo -e "${BLUE}构建产物目录: ${DIST_DIR}${NC}"
echo -e "${BLUE}文件列表:${NC}"
ls -lh "${DIST_DIR}" | head -10
echo ""

# 询问部署方式
echo -e "${YELLOW}请选择部署方式:${NC}"
echo "1) 直接替换nginx容器中的文件（推荐，快速）"
echo "2) 重新构建nginx镜像并重启容器（完整更新）"
read -p "请选择 (1/2, 默认1): " deploy_method
deploy_method=${deploy_method:-1}

if [ "$deploy_method" = "1" ]; then
    echo -e "${BLUE}方式1: 直接替换nginx容器中的文件${NC}"
    
    # 检查工具
    if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
        echo -e "${RED}错误: 需要安装 sshpass 或 expect 来传输文件${NC}"
        exit 1
    fi
    
    # 创建临时tar包
    TEMP_TAR="/tmp/wvp-frontend-$(date +%Y%m%d_%H%M%S).tar.gz"
    echo -e "${BLUE}打包前端文件...${NC}"
    cd "${DIST_DIR}"
    tar czf "${TEMP_TAR}" .
    echo -e "${GREEN}✓ 打包完成: ${TEMP_TAR}${NC}"
    echo ""
    
    # 传输到远程服务器
    echo -e "${BLUE}传输文件到远程服务器...${NC}"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no "${TEMP_TAR}" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/" &>/dev/null
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 60
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
    
    # 解压并替换文件
    echo -e "${BLUE}替换nginx容器中的文件...${NC}"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
            "cd ${REMOTE_DEPLOY_DIR} && docker exec ${NGINX_CONTAINER} sh -c 'rm -rf /opt/dist/*' && \
             docker cp ${REMOTE_TAR} ${NGINX_CONTAINER}:/tmp/ && \
             docker exec ${NGINX_CONTAINER} sh -c 'cd /opt/dist && tar xzf /tmp/$(basename ${REMOTE_TAR}) && rm /tmp/$(basename ${REMOTE_TAR})' && \
             rm -f ${REMOTE_TAR}" 2>&1
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 120
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && docker exec ${NGINX_CONTAINER} sh -c 'rm -rf /opt/dist/*' && docker cp ${REMOTE_TAR} ${NGINX_CONTAINER}:/tmp/ && docker exec ${NGINX_CONTAINER} sh -c 'cd /opt/dist && tar xzf /tmp/$(basename ${REMOTE_TAR}) && rm /tmp/$(basename ${REMOTE_TAR})' && rm -f ${REMOTE_TAR}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
    
    echo -e "${GREEN}✓ 文件替换完成${NC}"
    
    # 清理本地临时文件
    rm -f "${TEMP_TAR}"
    
elif [ "$deploy_method" = "2" ]; then
    echo -e "${BLUE}方式2: 重新构建nginx镜像${NC}"
    echo -e "${YELLOW}注意: 此方式需要重新构建Docker镜像，耗时较长${NC}"
    echo ""
    
    read -p "确认继续? (y/n): " confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${YELLOW}已取消${NC}"
        exit 0
    fi
    
    # 检查工具
    if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
        echo -e "${RED}错误: 需要安装 sshpass 或 expect 来执行远程命令${NC}"
        exit 1
    fi
    
    # 传输整个web目录到远程服务器
    echo -e "${BLUE}传输web目录到远程服务器...${NC}"
    TEMP_WEB_TAR="/tmp/wvp-web-$(date +%Y%m%d_%H%M%S).tar.gz"
    cd "${PROJECT_ROOT}"
    tar czf "${TEMP_WEB_TAR}" web/
    
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no "${TEMP_WEB_TAR}" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/" &>/dev/null
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 300
spawn scp -o StrictHostKeyChecking=no "${TEMP_WEB_TAR}" ${REMOTE_USER}@${REMOTE_HOST}:/tmp/
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
    
    REMOTE_WEB_TAR="/tmp/$(basename ${TEMP_WEB_TAR})"
    echo -e "${GREEN}✓ 文件已传输${NC}"
    echo ""
    
    # 在远程服务器上解压、构建并重启
    echo -e "${BLUE}在远程服务器上构建nginx镜像...${NC}"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
            "cd ${REMOTE_DEPLOY_DIR} && \
             mkdir -p /tmp/wvp-web-temp && \
             tar xzf ${REMOTE_WEB_TAR} -C /tmp/wvp-web-temp && \
             cd docker/nginx && \
             docker build -t polaris-nginx:latest -f Dockerfile ../../ && \
             docker stop ${NGINX_CONTAINER} && \
             docker rm ${NGINX_CONTAINER} && \
             docker run -d --name ${NGINX_CONTAINER} --network media-net -p 8080:8080 -v ${REMOTE_DEPLOY_DIR}/nginx/templates:/etc/nginx/templates polaris-nginx:latest && \
             rm -rf /tmp/wvp-web-temp && \
             rm -f ${REMOTE_WEB_TAR}" 2>&1
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 600
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && mkdir -p /tmp/wvp-web-temp && tar xzf ${REMOTE_WEB_TAR} -C /tmp/wvp-web-temp && cd docker/nginx && docker build -t polaris-nginx:latest -f Dockerfile ../../ && docker stop ${NGINX_CONTAINER} && docker rm ${NGINX_CONTAINER} && docker run -d --name ${NGINX_CONTAINER} --network media-net -p 8080:8080 -v ${REMOTE_DEPLOY_DIR}/nginx/templates:/etc/nginx/templates polaris-nginx:latest && rm -rf /tmp/wvp-web-temp && rm -f ${REMOTE_WEB_TAR}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    fi
    
    echo -e "${GREEN}✓ nginx镜像构建并重启完成${NC}"
    
    # 清理本地临时文件
    rm -f "${TEMP_WEB_TAR}"
fi

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}前端更新完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}访问地址: http://${REMOTE_HOST}:8080${NC}"

