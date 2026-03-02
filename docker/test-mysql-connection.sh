#!/bin/bash
# MySQL外部连接测试脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 服务器配置
REMOTE_HOST="172.31.127.47"
REMOTE_PORT="3306"
DB_NAME="wvp"

# 用户配置
ROOT_USER="root"
ROOT_PASSWORD="root"
WVP_USER="wvp_user"
WVP_PASSWORD="wvp_password"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}MySQL外部连接测试${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

echo -e "${BLUE}连接信息：${NC}"
echo "  服务器：${REMOTE_HOST}"
echo "  端口：${REMOTE_PORT}"
echo "  数据库：${DB_NAME}"
echo ""

# 检查MySQL客户端是否安装
if ! command -v mysql &> /dev/null; then
    echo -e "${YELLOW}警告：未找到mysql客户端，请先安装：${NC}"
    echo "  macOS: brew install mysql-client"
    echo "  Ubuntu/Debian: sudo apt-get install mysql-client"
    echo "  CentOS/RHEL: sudo yum install mysql"
    echo ""
    echo -e "${BLUE}使用telnet测试端口连通性：${NC}"
    if command -v telnet &> /dev/null; then
        echo "telnet ${REMOTE_HOST} ${REMOTE_PORT}"
    elif command -v nc &> /dev/null; then
        echo "nc -zv ${REMOTE_HOST} ${REMOTE_PORT}"
    else
        echo "请安装telnet或nc工具"
    fi
    exit 1
fi

# 测试连接
echo -e "${BLUE}测试连接...${NC}"
echo ""

# 测试root用户连接
echo -e "${BLUE}1. 测试root用户连接：${NC}"
if mysql -h "${REMOTE_HOST}" -P "${REMOTE_PORT}" -u "${ROOT_USER}" -p"${ROOT_PASSWORD}" -e "SELECT VERSION(), DATABASE();" 2>&1 | grep -v "Warning"; then
    echo -e "${GREEN}✓ root用户连接成功${NC}"
else
    echo -e "${RED}✗ root用户连接失败${NC}"
fi
echo ""

# 测试wvp_user用户连接
echo -e "${BLUE}2. 测试wvp_user用户连接：${NC}"
if mysql -h "${REMOTE_HOST}" -P "${REMOTE_PORT}" -u "${WVP_USER}" -p"${WVP_PASSWORD}" "${DB_NAME}" -e "SELECT DATABASE();" 2>&1 | grep -v "Warning"; then
    echo -e "${GREEN}✓ wvp_user用户连接成功${NC}"
else
    echo -e "${RED}✗ wvp_user用户连接失败${NC}"
fi
echo ""

# 显示连接命令
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}连接命令示例${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${BLUE}使用root用户：${NC}"
echo "mysql -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${ROOT_USER} -p"
echo "（输入密码：${ROOT_PASSWORD}）"
echo ""
echo -e "${BLUE}使用wvp_user用户：${NC}"
echo "mysql -h ${REMOTE_HOST} -P ${REMOTE_PORT} -u ${WVP_USER} -p${WVP_PASSWORD} ${DB_NAME}"
echo ""
echo -e "${BLUE}JDBC连接字符串：${NC}"
echo "jdbc:mysql://${REMOTE_HOST}:${REMOTE_PORT}/${DB_NAME}?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true"
echo ""

