#!/bin/bash
# 增量上传项目源码到远程服务器
# 使用方法: ./upload-source-to-remote.sh

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
REMOTE_BUILD_DIR="/home/build"

# 获取脚本所在目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}增量上传项目源码到远程服务器${NC}"
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

# 检查远程目录已存在的文件
echo -e "${BLUE}检查远程目录已存在的文件...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "mkdir -p ${REMOTE_BUILD_DIR} && find ${REMOTE_BUILD_DIR} -type f -name '*.java' -o -name '*.xml' -o -name '*.yml' -o -name '*.properties' | head -20" > "${TEMP_DIR}/remote_files.txt" 2>/dev/null || echo "" > "${TEMP_DIR}/remote_files.txt"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "mkdir -p ${REMOTE_BUILD_DIR} && find ${REMOTE_BUILD_DIR} -type f | head -20"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

echo -e "${GREEN}✓ 远程目录检查完成${NC}"
echo ""

# 准备项目文件（排除不必要的文件）
echo -e "${BLUE}准备项目文件...${NC}"
cd "${PROJECT_ROOT}"

# 创建项目打包（排除不必要的文件）
tar --exclude='.git' \
    --exclude='node_modules' \
    --exclude='target' \
    --exclude='logs' \
    --exclude='*.log' \
    --exclude='.idea' \
    --exclude='.vscode' \
    --exclude='.DS_Store' \
    --exclude='._*' \
    -czf "${TEMP_DIR}/wvp-project.tar.gz" \
    -C "${PROJECT_ROOT}" .

# 计算文件大小
FILE_SIZE=$(du -h "${TEMP_DIR}/wvp-project.tar.gz" | cut -f1)
echo -e "${GREEN}✓ 项目文件打包完成，大小: ${FILE_SIZE}${NC}"
echo ""

# 传输文件到远程服务器
echo -e "${BLUE}传输文件到远程服务器 ${REMOTE_BUILD_DIR}...${NC}"
echo -e "${YELLOW}文件大小: ${FILE_SIZE}，传输可能需要一些时间...${NC}"

if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        "${TEMP_DIR}/wvp-project.tar.gz" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 600
spawn scp -o StrictHostKeyChecking=no "${TEMP_DIR}/wvp-project.tar.gz" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
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
    echo -e "${GREEN}✓ 文件传输成功${NC}"
else
    echo -e "${RED}✗ 文件传输失败${NC}"
    rm -rf "${TEMP_DIR}"
    exit 1
fi

# 在远程服务器上解压（如果目录不存在或为空）
echo -e "${BLUE}在远程服务器上解压文件...${NC}"

# 创建解压脚本
cat > "${TEMP_DIR}/extract.sh" << 'EXTRACT_SCRIPT'
#!/bin/bash
cd /home/build
if [ ! -d "wvp-GB28181-pro" ] || [ -z "$(ls -A wvp-GB28181-pro 2>/dev/null)" ]; then
    echo "解压项目文件..."
    tar -xzf wvp-project.tar.gz
    echo "✓ 解压完成"
else
    echo "项目目录已存在且不为空，跳过解压"
    echo "如需重新解压，请先删除远程目录: rm -rf /home/build/wvp-GB28181-pro"
fi
EXTRACT_SCRIPT

if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        "${TEMP_DIR}/extract.sh" \
        "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
    
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" \
        "chmod +x ${REMOTE_BUILD_DIR}/extract.sh && bash ${REMOTE_BUILD_DIR}/extract.sh"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 300
spawn scp -o StrictHostKeyChecking=no "${TEMP_DIR}/extract.sh" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_BUILD_DIR}/"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "chmod +x ${REMOTE_BUILD_DIR}/extract.sh && bash ${REMOTE_BUILD_DIR}/extract.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

# 清理临时目录
rm -rf "${TEMP_DIR}"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}上传完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}远程目录: ${REMOTE_BUILD_DIR}${NC}"
echo -e "${BLUE}项目路径: ${REMOTE_BUILD_DIR}/wvp-GB28181-pro${NC}"
echo ""
echo -e "${YELLOW}查看远程文件:${NC}"
echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST} 'ls -la ${REMOTE_BUILD_DIR}'"
echo ""

