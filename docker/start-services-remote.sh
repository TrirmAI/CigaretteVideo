#!/bin/bash
# 远程启动服务脚本
# 使用方法: ./start-services-remote.sh [start-remote.sh|start-remote-docker.sh]

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

# 确定使用哪个启动脚本
START_SCRIPT="${1:-start-remote-docker.sh}"

if [ "$START_SCRIPT" != "start-remote.sh" ] && [ "$START_SCRIPT" != "start-remote-docker.sh" ]; then
    echo -e "${RED}错误: 无效的启动脚本${NC}"
    echo -e "${YELLOW}使用方法: $0 [start-remote.sh|start-remote-docker.sh]${NC}"
    echo -e "${YELLOW}默认使用: start-remote-docker.sh${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}远程启动 WVP-Pro 服务${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}远程服务器: ${REMOTE_USER}@${REMOTE_HOST}${NC}"
echo -e "${BLUE}部署目录: ${REMOTE_DEPLOY_DIR}${NC}"
echo -e "${BLUE}启动脚本: ${START_SCRIPT}${NC}"
echo ""

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    echo -e "${YELLOW}安装方法:${NC}"
    echo -e "  macOS: brew install sshpass 或 brew install expect"
    echo -e "  Ubuntu: sudo apt-get install sshpass 或 sudo apt-get install expect"
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
elif command -v expect &> /dev/null; then
    if ! expect << EOF
set timeout 5
spawn ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ${REMOTE_USER}@${REMOTE_HOST} "echo '连接成功'"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    "连接成功" {
        exit 0
    }
    timeout {
        exit 1
    }
    eof
}
EOF
    then
        echo -e "${RED}错误: 无法连接到远程服务器${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ 远程服务器连接正常${NC}"
echo ""

# 检查启动脚本是否存在
echo -e "${BLUE}检查远程启动脚本是否存在...${NC}"
if command -v sshpass &> /dev/null; then
    if ! sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "test -f ${REMOTE_DEPLOY_DIR}/${START_SCRIPT}"; then
        echo -e "${RED}错误: 远程启动脚本不存在: ${REMOTE_DEPLOY_DIR}/${START_SCRIPT}${NC}"
        echo -e "${YELLOW}请先运行部署脚本: ./deploy-to-remote.sh${NC}"
        exit 1
    fi
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "test -f ${REMOTE_DEPLOY_DIR}/${START_SCRIPT} && echo 'exists' || echo 'not exists'"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    "not exists" {
        exit 1
    }
    "exists" {
        exit 0
    }
    eof
}
EOF
    if [ $? -ne 0 ]; then
        echo -e "${RED}错误: 远程启动脚本不存在: ${REMOTE_DEPLOY_DIR}/${START_SCRIPT}${NC}"
        echo -e "${YELLOW}请先运行部署脚本: ./deploy-to-remote.sh${NC}"
        exit 1
    fi
fi
echo -e "${GREEN}✓ 启动脚本存在${NC}"
echo ""

# 执行远程启动
echo -e "${BLUE}开始在远程服务器上启动服务...${NC}"
echo -e "${YELLOW}注意: 启动过程可能需要几分钟时间${NC}"
echo ""

if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no -t \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "cd ${REMOTE_DEPLOY_DIR} && chmod +x ${START_SCRIPT} && ./${START_SCRIPT}"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 600
spawn ssh -o StrictHostKeyChecking=no -t ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && chmod +x ${START_SCRIPT} && ./${START_SCRIPT}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}服务启动完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}查看服务状态:${NC}"
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
            "${REMOTE_USER}@${REMOTE_HOST}" \
            "cd ${REMOTE_DEPLOY_DIR} && docker ps --filter 'name=polaris-' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
    elif command -v expect &> /dev/null; then
        expect << EOF
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DEPLOY_DIR} && docker ps --filter 'name=polaris-' --format 'table {{.Names}}\t{{.Status}}\t{{.Ports}}'"
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
    echo -e "${BLUE}访问地址:${NC}"
    echo -e "  WVP Web界面: http://${REMOTE_HOST}:18978"
    echo -e "  流媒体服务器: http://${REMOTE_HOST}:8080"
    echo ""
    echo -e "${YELLOW}查看日志:${NC}"
    echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo -e "  cd ${REMOTE_DEPLOY_DIR}"
    echo -e "  docker logs -f polaris-wvp"
else
    echo -e "${RED}服务启动失败，退出码: ${EXIT_CODE}${NC}"
    echo -e "${YELLOW}请检查远程服务器日志:${NC}"
    echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo -e "  cd ${REMOTE_DEPLOY_DIR}"
    echo -e "  cat logs/startup.log"
    exit $EXIT_CODE
fi

