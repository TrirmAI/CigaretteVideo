#!/bin/bash
# 在远程服务器初始化 MySQL 数据库

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

# MySQL 配置
MYSQL_ROOT_PASSWORD="${1:-root}"
MYSQL_DATABASE="wvp"
MYSQL_USER="${2:-ylcx}"
MYSQL_USER_PASSWORD="${3:-ylcx}"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}初始化远程 MySQL 数据库${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 创建远程初始化脚本
TEMP_REMOTE_SCRIPT=$(mktemp)
cat > "${TEMP_REMOTE_SCRIPT}" << 'REMOTE_INIT_SCRIPT'
#!/bin/bash
set -e

BUILD_DIR="/home/wvp/build"
MYSQL_ROOT_PASSWORD="${MYSQL_ROOT_PASSWORD:-root}"
MYSQL_DATABASE="${MYSQL_DATABASE:-wvp}"
MYSQL_USER="${MYSQL_USER:-ylcx}"
MYSQL_USER_PASSWORD="${MYSQL_USER_PASSWORD:-ylcx}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}初始化 MySQL 数据库${NC}"
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

# 检查 MySQL 镜像是否存在
if ! ${DOCKER_CMD} images | grep -q "polaris-mysql\|mysql.*8"; then
    echo -e "${YELLOW}警告: 未找到 MySQL 镜像，请先构建 MySQL 镜像${NC}"
    exit 1
fi

# 检查 MySQL 容器是否已存在
CONTAINER_NAME="polaris-mysql"
if ${DOCKER_CMD} ps -a --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
    echo -e "${BLUE}检测到 MySQL 容器已存在${NC}"
    
    # 检查容器是否运行
    if ${DOCKER_CMD} ps --format "{{.Names}}" | grep -q "^${CONTAINER_NAME}$"; then
        echo -e "${GREEN}✓ MySQL 容器正在运行${NC}"
    else
        echo -e "${YELLOW}MySQL 容器已存在但未运行，启动容器...${NC}"
        ${DOCKER_CMD} start ${CONTAINER_NAME}
        echo -e "${GREEN}✓ MySQL 容器已启动${NC}"
        
        # 等待 MySQL 启动
        echo -e "${BLUE}等待 MySQL 服务启动...${NC}"
        sleep 10
    fi
else
    echo -e "${BLUE}创建并启动 MySQL 容器...${NC}"
    
    # 创建数据目录
    mkdir -p ${BUILD_DIR}/volumes/mysql/data
    mkdir -p ${BUILD_DIR}/logs/mysql
    
    # 启动 MySQL 容器
    ${DOCKER_CMD} run -d \
        --name ${CONTAINER_NAME} \
        --network host \
        -e MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD} \
        -e MYSQL_DATABASE=${MYSQL_DATABASE} \
        -e MYSQL_USER=${MYSQL_USER} \
        -e MYSQL_PASSWORD=${MYSQL_USER_PASSWORD} \
        -e TZ=Asia/Shanghai \
        -v ${BUILD_DIR}/docker/mysql/db:/docker-entrypoint-initdb.d \
        -v ${BUILD_DIR}/volumes/mysql/data:/var/lib/mysql \
        -v ${BUILD_DIR}/logs/mysql:/logs \
        polaris-mysql:latest \
        --character-set-server=utf8mb4 \
        --collation-server=utf8mb4_general_ci \
        --default-time-zone=+8:00 \
        --lower-case-table-names=1
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ MySQL 容器已创建并启动${NC}"
        
        # 等待 MySQL 启动和初始化完成
        echo -e "${BLUE}等待 MySQL 服务启动并初始化数据库...${NC}"
        echo -e "${YELLOW}这可能需要 30-60 秒，请耐心等待...${NC}"
        
        # 检查 MySQL 是否就绪
        for i in {1..60}; do
            if ${DOCKER_CMD} exec ${CONTAINER_NAME} mysqladmin ping -h localhost --silent 2>/dev/null; then
                echo -e "${GREEN}✓ MySQL 服务已就绪${NC}"
                break
            fi
            if [ $i -eq 60 ]; then
                echo -e "${RED}✗ MySQL 服务启动超时${NC}"
                exit 1
            fi
            sleep 2
            echo -n "."
        done
        echo ""
    else
        echo -e "${RED}✗ MySQL 容器启动失败${NC}"
        exit 1
    fi
fi

# 检查数据库是否已初始化
echo -e "${BLUE}检查数据库初始化状态...${NC}"
DB_EXISTS=$(${DOCKER_CMD} exec ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} -e "SHOW DATABASES LIKE '${MYSQL_DATABASE}';" 2>/dev/null | grep -c "${MYSQL_DATABASE}" || echo "0")

if [ "$DB_EXISTS" -gt 0 ]; then
    echo -e "${GREEN}✓ 数据库 ${MYSQL_DATABASE} 已存在${NC}"
    
    # 检查表是否存在
    TABLE_COUNT=$(${DOCKER_CMD} exec ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "SHOW TABLES;" 2>/dev/null | wc -l || echo "0")
    
    if [ "$TABLE_COUNT" -gt 1 ]; then
        echo -e "${GREEN}✓ 数据库表已存在（${TABLE_COUNT} 个表）${NC}"
        echo -e "${YELLOW}数据库已初始化，无需重复初始化${NC}"
    else
        echo -e "${YELLOW}数据库存在但表未初始化，执行初始化...${NC}"
        ${DOCKER_CMD} exec -i ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} < ${BUILD_DIR}/docker/mysql/db/wvp.sql
        ${DOCKER_CMD} exec -i ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} < ${BUILD_DIR}/docker/mysql/db/privileges.sql
        echo -e "${GREEN}✓ 数据库初始化完成${NC}"
    fi
else
    echo -e "${BLUE}数据库不存在，执行初始化...${NC}"
    ${DOCKER_CMD} exec -i ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} < ${BUILD_DIR}/docker/mysql/db/wvp.sql
    ${DOCKER_CMD} exec -i ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} < ${BUILD_DIR}/docker/mysql/db/privileges.sql
    echo -e "${GREEN}✓ 数据库初始化完成${NC}"
fi

# 显示数据库信息
echo ""
echo -e "${BLUE}数据库信息:${NC}"
echo -e "  数据库名: ${MYSQL_DATABASE}"
echo -e "  用户名: ${MYSQL_USER}"
echo -e "  容器名: ${CONTAINER_NAME}"
echo -e "  端口: 3306"

# 显示表列表
echo ""
echo -e "${BLUE}数据库表列表:${NC}"
${DOCKER_CMD} exec ${CONTAINER_NAME} mysql -uroot -p${MYSQL_ROOT_PASSWORD} -D ${MYSQL_DATABASE} -e "SHOW TABLES;" 2>/dev/null | head -20

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MySQL 数据库初始化完成！${NC}"
echo -e "${GREEN}========================================${NC}"
REMOTE_INIT_SCRIPT

# 添加参数到远程脚本
sed -i.bak "s|MYSQL_ROOT_PASSWORD=\${MYSQL_ROOT_PASSWORD:-root}|MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD}|" "${TEMP_REMOTE_SCRIPT}"
sed -i.bak "s|MYSQL_DATABASE=\${MYSQL_DATABASE:-wvp}|MYSQL_DATABASE=${MYSQL_DATABASE}|" "${TEMP_REMOTE_SCRIPT}"
sed -i.bak "s|MYSQL_USER=\${MYSQL_USER:-ylcx}|MYSQL_USER=${MYSQL_USER}|" "${TEMP_REMOTE_SCRIPT}"
sed -i.bak "s|MYSQL_USER_PASSWORD=\${MYSQL_USER_PASSWORD:-ylcx}|MYSQL_USER_PASSWORD=${MYSQL_USER_PASSWORD}|" "${TEMP_REMOTE_SCRIPT}"
rm -f "${TEMP_REMOTE_SCRIPT}.bak"

chmod +x "${TEMP_REMOTE_SCRIPT}"

# 传输并执行远程脚本
echo -e "${BLUE}传输初始化脚本到远程服务器...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no \
        "${TEMP_REMOTE_SCRIPT}" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/init-mysql-remote.sh"
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no \
        "${REMOTE_USER}@${REMOTE_HOST}" "bash /tmp/init-mysql-remote.sh && rm -f /tmp/init-mysql-remote.sh"
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 300
spawn scp -o StrictHostKeyChecking=no ${TEMP_REMOTE_SCRIPT} ${REMOTE_USER}@${REMOTE_HOST}:/tmp/init-mysql-remote.sh
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}

spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "bash /tmp/init-mysql-remote.sh && rm -f /tmp/init-mysql-remote.sh"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    -re ".*" {
        exp_continue
    }
    eof
}
EOF
else
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

rm -f "${TEMP_REMOTE_SCRIPT}"

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${YELLOW}提示:${NC}"
echo -e "  查看 MySQL 日志: ssh ${REMOTE_USER}@${REMOTE_HOST} '${DOCKER_CMD} logs polaris-mysql'"
echo -e "  连接 MySQL: ssh ${REMOTE_USER}@${REMOTE_HOST} '${DOCKER_CMD} exec -it polaris-mysql mysql -uroot -p${MYSQL_ROOT_PASSWORD}'"
echo -e "${BLUE}========================================${NC}"

