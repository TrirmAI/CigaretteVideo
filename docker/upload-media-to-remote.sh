#!/bin/bash
# 上传流媒体组件到远程服务器
# 使用方法: ./upload-media-to-remote.sh

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
REMOTE_MEDIA_DIR="/docker/media"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_MEDIA_DIR="${SCRIPT_DIR}/media"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}上传流媒体组件到远程服务器${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查本地media目录
if [ ! -d "${LOCAL_MEDIA_DIR}" ]; then
    echo -e "${RED}错误: 本地media目录不存在: ${LOCAL_MEDIA_DIR}${NC}"
    exit 1
fi

# 检查必要的工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

# 检查远程目录已存在的文件
echo -e "${BLUE}检查远程目录已存在的文件...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "mkdir -p ${REMOTE_MEDIA_DIR} && ls -la ${REMOTE_MEDIA_DIR} 2>/dev/null | head -10" || echo ""
elif command -v expect &> /dev/null; then
    expect << 'EXPECT_EOF'
set timeout 30
spawn ssh -o StrictHostKeyChecking=no root@172.31.127.47 "mkdir -p /docker/media && ls -la /docker/media 2>/dev/null | head -10"
expect {
    "password:" {
        send "Shenzhoulu9#\r"
        exp_continue
    }
    eof
}
EXPECT_EOF
fi

echo -e "${GREEN}✓ 远程目录检查完成${NC}"
echo ""

# 传输文件到远程服务器（使用rsync或scp）
echo -e "${BLUE}传输流媒体组件文件到远程服务器...${NC}"

# 列出要传输的文件
FILES_TO_UPLOAD=(
    "config.ini"
    "Dockerfile"
    "build.sh"
    "config.ini.bak"
)

UPLOADED_COUNT=0
SKIPPED_COUNT=0

for file in "${FILES_TO_UPLOAD[@]}"; do
    local_file="${LOCAL_MEDIA_DIR}/${file}"
    
    if [ ! -f "${local_file}" ]; then
        echo -e "${YELLOW}⚠ 跳过: ${file} (本地文件不存在)${NC}"
        SKIPPED_COUNT=$((SKIPPED_COUNT + 1))
        continue
    fi
    
    echo -e "${BLUE}传输: ${file}...${NC}"
    
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
            "${local_file}" \
            "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_MEDIA_DIR}/"
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 60
spawn scp -o StrictHostKeyChecking=no "${local_file}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_MEDIA_DIR}/"
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
        echo -e "${GREEN}✓ ${file} 传输成功${NC}"
        UPLOADED_COUNT=$((UPLOADED_COUNT + 1))
    else
        echo -e "${RED}✗ ${file} 传输失败${NC}"
    fi
done

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}上传完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}统计:${NC}"
echo -e "  成功上传: ${UPLOADED_COUNT} 个文件"
echo -e "  跳过: ${SKIPPED_COUNT} 个文件"
echo ""
echo -e "${BLUE}远程目录: ${REMOTE_MEDIA_DIR}${NC}"
echo ""
echo -e "${YELLOW}查看远程文件:${NC}"
echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST} 'ls -la ${REMOTE_MEDIA_DIR}'"
echo ""

