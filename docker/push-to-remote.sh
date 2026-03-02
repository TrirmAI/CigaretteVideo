#!/bin/bash
# Docker镜像推送到远端服务器脚本
# 使用方法: ./push-to-remote.sh

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
REMOTE_TEMP_DIR="/home/wvp"

# 本地临时目录
LOCAL_TEMP_DIR="/tmp/docker-images-export"
IMAGE_FILE="${LOCAL_TEMP_DIR}/wvp-images.tar"

# 需要推送的镜像列表
IMAGES=(
    "redis:latest"
    "mysql:8"
    "zlmediakit/zlmediakit:master"
    "wvp-pro:latest"
)

# 检查并添加nginx镜像（可能有多种命名方式）
check_nginx_image() {
    local nginx_images=(
        "wvp-nginx:latest"
        "polaris-nginx:latest"
        "wvp-gb28181-pro_nginx:latest"
    )
    
    for img in "${nginx_images[@]}"; do
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${img}$"; then
            echo -e "${GREEN}找到nginx镜像: ${img}${NC}"
            IMAGES+=("${img}")
            return 0
        fi
    done
    
    echo -e "${YELLOW}警告: 未找到nginx镜像，将跳过${NC}"
    return 1
}

# 检查必要的工具
check_requirements() {
    echo -e "${BLUE}检查必要的工具...${NC}"
    
    if ! command -v docker &> /dev/null; then
        echo -e "${RED}错误: 未找到 docker 命令${NC}"
        exit 1
    fi
    
    if ! command -v sshpass &> /dev/null; then
        echo -e "${YELLOW}警告: 未找到 sshpass，将尝试使用 expect 或手动输入密码${NC}"
        if ! command -v expect &> /dev/null; then
            echo -e "${RED}错误: 需要安装 sshpass 或 expect 来处理密码认证${NC}"
            echo -e "${YELLOW}macOS安装: brew install sshpass 或 brew install expect${NC}"
            exit 1
        fi
    fi
    
    echo -e "${GREEN}✓ 工具检查完成${NC}"
}

# 检查镜像是否存在
check_images() {
    echo -e "${BLUE}检查镜像是否存在...${NC}"
    local missing_images=()
    
    for image in "${IMAGES[@]}"; do
        if docker images --format "{{.Repository}}:{{.Tag}}" | grep -q "^${image}$"; then
            echo -e "${GREEN}✓ 找到镜像: ${image}${NC}"
        else
            echo -e "${RED}✗ 未找到镜像: ${image}${NC}"
            missing_images+=("${image}")
        fi
    done
    
    # 检查nginx镜像（忽略返回值，nginx是可选的）
    check_nginx_image || true
    
    if [ ${#missing_images[@]} -gt 0 ]; then
        echo -e "${RED}错误: 以下镜像不存在，请先构建或拉取:${NC}"
        for img in "${missing_images[@]}"; do
            echo -e "  - ${img}"
        done
        exit 1
    fi
    
    echo -e "${GREEN}✓ 所有镜像检查完成${NC}"
}

# 导出镜像
export_images() {
    echo -e "${BLUE}开始导出镜像...${NC}"
    
    # 创建临时目录
    mkdir -p "${LOCAL_TEMP_DIR}"
    
    # 清理旧文件
    if [ -f "${IMAGE_FILE}" ]; then
        echo -e "${YELLOW}删除旧的镜像文件...${NC}"
        rm -f "${IMAGE_FILE}"
    fi
    
    # 导出所有镜像到单个文件
    echo -e "${BLUE}正在导出 ${#IMAGES[@]} 个镜像到 ${IMAGE_FILE}...${NC}"
    echo -e "${YELLOW}这可能需要几分钟时间，请耐心等待...${NC}"
    
    docker save "${IMAGES[@]}" -o "${IMAGE_FILE}"
    
    if [ $? -eq 0 ]; then
        local file_size=$(du -h "${IMAGE_FILE}" | cut -f1)
        echo -e "${GREEN}✓ 镜像导出成功！文件大小: ${file_size}${NC}"
    else
        echo -e "${RED}✗ 镜像导出失败${NC}"
        exit 1
    fi
}

# 传输镜像到远端服务器
transfer_images() {
    echo -e "${BLUE}开始传输镜像到远端服务器 ${REMOTE_USER}@${REMOTE_HOST}...${NC}"
    
    # 检查文件是否存在
    if [ ! -f "${IMAGE_FILE}" ]; then
        echo -e "${RED}错误: 镜像文件不存在: ${IMAGE_FILE}${NC}"
        exit 1
    fi
    
    local file_size=$(du -h "${IMAGE_FILE}" | cut -f1)
    echo -e "${YELLOW}文件大小: ${file_size}，传输可能需要一些时间...${NC}"
    
    # 使用sshpass传输文件
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
            "${IMAGE_FILE}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TEMP_DIR}/"
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 3600
spawn scp -o StrictHostKeyChecking=no "${IMAGE_FILE}" "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TEMP_DIR}/"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    else
        echo -e "${YELLOW}请手动执行以下命令传输文件:${NC}"
        echo -e "scp ${IMAGE_FILE} ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_TEMP_DIR}/"
        read -p "传输完成后按回车继续..."
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 镜像传输成功${NC}"
    else
        echo -e "${RED}✗ 镜像传输失败${NC}"
        exit 1
    fi
}

# 在远端服务器加载镜像
load_images_on_remote() {
    echo -e "${BLUE}在远端服务器加载镜像...${NC}"
    
    local remote_file="${REMOTE_TEMP_DIR}/$(basename ${IMAGE_FILE})"
    
    # 构建SSH命令
    local ssh_cmd="mkdir -p ${REMOTE_TEMP_DIR} && \
        docker load -i ${remote_file} && \
        echo '镜像加载完成' && \
        rm -f ${remote_file} && \
        echo '临时文件已清理'"
    
    # 执行SSH命令
    if command -v sshpass &> /dev/null; then
        sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
            "${REMOTE_USER}@${REMOTE_HOST}" "${ssh_cmd}"
    elif command -v expect &> /dev/null; then
        expect << EOF
set timeout 3600
spawn ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "${ssh_cmd}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    else
        echo -e "${YELLOW}请手动执行以下命令在远端服务器加载镜像:${NC}"
        echo -e "ssh ${REMOTE_USER}@${REMOTE_HOST}"
        echo -e "docker load -i ${remote_file}"
        read -p "加载完成后按回车继续..."
    fi
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ 远端服务器镜像加载成功${NC}"
    else
        echo -e "${RED}✗ 远端服务器镜像加载失败${NC}"
        exit 1
    fi
}

# 清理本地临时文件
cleanup_local() {
    echo -e "${BLUE}清理本地临时文件...${NC}"
    if [ -f "${IMAGE_FILE}" ]; then
        rm -f "${IMAGE_FILE}"
        echo -e "${GREEN}✓ 本地临时文件已清理${NC}"
    fi
    if [ -d "${LOCAL_TEMP_DIR}" ]; then
        rmdir "${LOCAL_TEMP_DIR}" 2>/dev/null || true
    fi
}

# 主函数
main() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Docker镜像推送到远端服务器${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    
    # 检查工具
    check_requirements
    echo ""
    
    # 检查镜像
    check_images
    echo ""
    
    # 导出镜像
    export_images
    echo ""
    
    # 传输镜像
    transfer_images
    echo ""
    
    # 在远端加载镜像
    load_images_on_remote
    echo ""
    
    # 清理本地文件
    cleanup_local
    echo ""
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}所有操作完成！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${BLUE}已推送的镜像:${NC}"
    for image in "${IMAGES[@]}"; do
        echo -e "  - ${image}"
    done
    echo ""
    echo -e "${YELLOW}可以在远端服务器使用以下命令查看镜像:${NC}"
    echo -e "  ssh ${REMOTE_USER}@${REMOTE_HOST}"
    echo -e "  docker images"
}

# 执行主函数
main

