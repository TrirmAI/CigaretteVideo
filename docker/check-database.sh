#!/bin/bash
# 数据库连接检查脚本
# 使用方法: 
#   ./check-database.sh
#   或指定参数: ./check-database.sh -H 192.168.1.100 -P 3306 -U wvp_user -p wvp_password -D wvp

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 默认值（从环境变量或配置文件读取）
DATABASE_HOST="${DATABASE_HOST:-polaris-mysql}"
DATABASE_PORT="${DATABASE_PORT:-3306}"
DATABASE_USER="${DATABASE_USER:-wvp_user}"
DATABASE_PASSWORD="${DATABASE_PASSWORD:-wvp_password}"
DATABASE_NAME="${DATABASE_NAME:-wvp}"

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -H|--host)
            DATABASE_HOST="$2"
            shift 2
            ;;
        -P|--port)
            DATABASE_PORT="$2"
            shift 2
            ;;
        -U|--user)
            DATABASE_USER="$2"
            shift 2
            ;;
        -p|--password)
            DATABASE_PASSWORD="$2"
            shift 2
            ;;
        -D|--database)
            DATABASE_NAME="$2"
            shift 2
            ;;
        -h|--help)
            echo "使用方法: $0 [选项]"
            echo "选项:"
            echo "  -H, --host HOST        数据库主机地址 (默认: ${DATABASE_HOST})"
            echo "  -P, --port PORT        数据库端口 (默认: ${DATABASE_PORT})"
            echo "  -U, --user USER        数据库用户名 (默认: ${DATABASE_USER})"
            echo "  -p, --password PASS    数据库密码 (默认: ${DATABASE_PASSWORD})"
            echo "  -D, --database DB      数据库名称 (默认: ${DATABASE_NAME})"
            echo "  -h, --help             显示帮助信息"
            echo ""
            echo "环境变量支持:"
            echo "  DATABASE_HOST, DATABASE_PORT, DATABASE_USER, DATABASE_PASSWORD, DATABASE_NAME"
            exit 0
            ;;
        *)
            echo -e "${RED}未知参数: $1${NC}"
            echo "使用 -h 或 --help 查看帮助信息"
            exit 1
            ;;
    esac
done

# 显示配置信息
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}数据库连接检查${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "主机地址: ${YELLOW}${DATABASE_HOST}${NC}"
echo -e "端口:     ${YELLOW}${DATABASE_PORT}${NC}"
echo -e "用户名:   ${YELLOW}${DATABASE_USER}${NC}"
echo -e "数据库:   ${YELLOW}${DATABASE_NAME}${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# 检查结果统计
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

# 检查函数
check_result() {
    local check_name="$1"
    local result="$2"
    TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
    
    if [ "$result" -eq 0 ]; then
        echo -e "${GREEN}✓ ${check_name}${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
        return 0
    else
        echo -e "${RED}✗ ${check_name}${NC}"
        FAILED_CHECKS=$((FAILED_CHECKS + 1))
        return 1
    fi
}

# 1. 检查网络连通性（ping）
echo -e "${BLUE}[1/5] 检查网络连通性...${NC}"
if ping -c 1 -W 2 "${DATABASE_HOST}" >/dev/null 2>&1; then
    check_result "网络连通性 (ping)" 0
else
    echo -e "${YELLOW}  警告: ping 失败，但可能服务器禁用了ICMP，继续检查端口...${NC}"
    check_result "网络连通性 (ping)" 1
fi
echo ""

# 2. 检查端口是否开放
echo -e "${BLUE}[2/5] 检查端口是否开放...${NC}"
if command -v nc >/dev/null 2>&1; then
    if nc -z -w 3 "${DATABASE_HOST}" "${DATABASE_PORT}" 2>/dev/null; then
        check_result "端口 ${DATABASE_PORT} 可访问" 0
    else
        check_result "端口 ${DATABASE_PORT} 不可访问" 1
        echo -e "${RED}   错误: 无法连接到 ${DATABASE_HOST}:${DATABASE_PORT}${NC}"
        echo -e "${YELLOW}   请检查:${NC}"
        echo -e "${YELLOW}   1. 数据库服务是否运行${NC}"
        echo -e "${YELLOW}   2. 防火墙是否开放端口${NC}"
        echo -e "${YELLOW}   3. 数据库是否配置为允许远程连接${NC}"
    fi
elif command -v telnet >/dev/null 2>&1; then
    if timeout 3 bash -c "cat < /dev/null > /dev/tcp/${DATABASE_HOST}/${DATABASE_PORT}" 2>/dev/null; then
        check_result "端口 ${DATABASE_PORT} 可访问" 0
    else
        check_result "端口 ${DATABASE_PORT} 不可访问" 1
    fi
else
    echo -e "${YELLOW}   警告: 未找到 nc 或 telnet 命令，跳过端口检查${NC}"
fi
echo ""

# 3. 检查MySQL客户端是否可用
echo -e "${BLUE}[3/5] 检查MySQL客户端工具...${NC}"
MYSQL_CLIENT=""
MYSQL_CONTAINER=""
if command -v mysql >/dev/null 2>&1; then
    MYSQL_CLIENT="mysql"
    check_result "MySQL客户端可用" 0
elif docker ps >/dev/null 2>&1; then
    # 检查是否有MySQL容器可用
    if docker ps --format '{{.Names}}' | grep -q "polaris-mysql"; then
        MYSQL_CONTAINER="polaris-mysql"
        MYSQL_CLIENT="docker exec ${MYSQL_CONTAINER} mysql"
        check_result "使用Docker容器 polaris-mysql 中的MySQL客户端" 0
    elif docker ps --format '{{.Names}}' | grep -q "alldata-mysql"; then
        MYSQL_CONTAINER="alldata-mysql"
        MYSQL_CLIENT="docker exec ${MYSQL_CONTAINER} mysql"
        check_result "使用Docker容器 alldata-mysql 中的MySQL客户端" 0
    else
        check_result "MySQL客户端可用" 1
        echo -e "${YELLOW}   警告: 未找到 mysql 客户端，将使用Python进行连接测试${NC}"
    fi
else
    check_result "MySQL客户端可用" 1
    echo -e "${YELLOW}   警告: 未找到 mysql 客户端，将使用Python进行连接测试${NC}"
fi
echo ""

# 4. 测试数据库连接
echo -e "${BLUE}[4/5] 测试数据库连接...${NC}"
if [ -n "$MYSQL_CLIENT" ]; then
    # 使用MySQL客户端测试连接
    if [ "$MYSQL_CLIENT" = "mysql" ]; then
        if mysql -h"${DATABASE_HOST}" -P"${DATABASE_PORT}" -u"${DATABASE_USER}" -p"${DATABASE_PASSWORD}" -e "SELECT 1;" >/dev/null 2>&1; then
            check_result "数据库连接成功" 0
            CONNECTION_OK=0
        else
            check_result "数据库连接失败" 1
            echo -e "${RED}   错误: 无法连接到数据库${NC}"
            echo -e "${YELLOW}   可能的原因:${NC}"
            echo -e "${YELLOW}   1. 用户名或密码错误${NC}"
            echo -e "${YELLOW}   2. 用户没有远程连接权限${NC}"
            echo -e "${YELLOW}   3. 数据库服务器配置不允许远程连接${NC}"
            CONNECTION_OK=1
        fi
    else
        # Docker容器中的MySQL客户端
        CONNECTION_OUTPUT=$(${MYSQL_CLIENT} -h"${DATABASE_HOST}" -P"${DATABASE_PORT}" -u"${DATABASE_USER}" -p"${DATABASE_PASSWORD}" -e "SELECT 1;" 2>&1)
        CONNECTION_RESULT=$?
        if [ $CONNECTION_RESULT -eq 0 ]; then
            check_result "数据库连接成功" 0
            CONNECTION_OK=0
        else
            check_result "数据库连接失败" 1
            echo -e "${RED}   错误: 无法连接到数据库${NC}"
            echo -e "${YELLOW}   错误详情: ${CONNECTION_OUTPUT}${NC}"
            echo -e "${YELLOW}   可能的原因:${NC}"
            echo -e "${YELLOW}   1. 用户名或密码错误${NC}"
            echo -e "${YELLOW}   2. 用户没有远程连接权限${NC}"
            echo -e "${YELLOW}   3. 数据库服务器配置不允许远程连接${NC}"
            CONNECTION_OK=1
        fi
    fi
else
    # 使用Python测试连接
    if command -v python3 >/dev/null 2>&1; then
        PYTHON_TEST=$(python3 << EOF
import sys
try:
    import pymysql
    try:
        conn = pymysql.connect(
            host='${DATABASE_HOST}',
            port=${DATABASE_PORT},
            user='${DATABASE_USER}',
            password='${DATABASE_PASSWORD}',
            connect_timeout=5
        )
        conn.close()
        sys.exit(0)
    except Exception as e:
        print(f"连接错误: {e}", file=sys.stderr)
        sys.exit(1)
except ImportError:
    print("pymysql未安装，跳过Python连接测试", file=sys.stderr)
    sys.exit(2)
EOF
)
        PYTHON_RESULT=$?
        if [ $PYTHON_RESULT -eq 0 ]; then
            check_result "数据库连接成功 (Python)" 0
            CONNECTION_OK=0
        elif [ $PYTHON_RESULT -eq 2 ]; then
            echo -e "${YELLOW}   跳过: 未安装 pymysql 模块${NC}"
            CONNECTION_OK=1
        else
            check_result "数据库连接失败 (Python)" 1
            CONNECTION_OK=1
        fi
    else
        echo -e "${YELLOW}   跳过: 未找到 python3${NC}"
        CONNECTION_OK=1
    fi
fi
echo ""

# 5. 检查数据库是否存在
if [ "${CONNECTION_OK}" -eq 0 ]; then
    echo -e "${BLUE}[5/5] 检查数据库是否存在...${NC}"
    if [ -n "$MYSQL_CLIENT" ]; then
        if [ "$MYSQL_CLIENT" = "mysql" ]; then
            DB_EXISTS=$(mysql -h"${DATABASE_HOST}" -P"${DATABASE_PORT}" -u"${DATABASE_USER}" -p"${DATABASE_PASSWORD}" -e "SHOW DATABASES LIKE '${DATABASE_NAME}';" 2>/dev/null | grep -c "${DATABASE_NAME}" || echo "0")
        else
            DB_EXISTS=$(${MYSQL_CLIENT} -h"${DATABASE_HOST}" -P"${DATABASE_PORT}" -u"${DATABASE_USER}" -p"${DATABASE_PASSWORD}" -e "SHOW DATABASES LIKE '${DATABASE_NAME}';" 2>/dev/null | grep -c "${DATABASE_NAME}" || echo "0")
        fi
        
        if [ "$DB_EXISTS" -gt 0 ]; then
            check_result "数据库 '${DATABASE_NAME}' 存在" 0
            
            # 检查表是否存在
            if [ "$MYSQL_CLIENT" = "mysql" ]; then
                TABLE_COUNT=$(mysql -h"${DATABASE_HOST}" -P"${DATABASE_PORT}" -u"${DATABASE_USER}" -p"${DATABASE_PASSWORD}" -D"${DATABASE_NAME}" -e "SHOW TABLES;" 2>/dev/null | wc -l)
            else
                TABLE_COUNT=$(${MYSQL_CLIENT} -h"${DATABASE_HOST}" -P"${DATABASE_PORT}" -u"${DATABASE_USER}" -p"${DATABASE_PASSWORD}" -D"${DATABASE_NAME}" -e "SHOW TABLES;" 2>/dev/null | wc -l)
            fi
            
            if [ "$TABLE_COUNT" -gt 1 ]; then
                echo -e "${GREEN}  ✓ 数据库包含 $((TABLE_COUNT-1)) 个表${NC}"
            else
                echo -e "${YELLOW}  ⚠ 数据库存在但可能未初始化表结构${NC}"
            fi
        else
            check_result "数据库 '${DATABASE_NAME}' 不存在" 1
            echo -e "${YELLOW}   提示: 需要创建数据库或运行初始化脚本${NC}"
        fi
    else
        echo -e "${YELLOW}   跳过: 需要MySQL客户端来检查数据库${NC}"
    fi
else
    echo -e "${YELLOW}[5/5] 跳过数据库检查（连接失败）${NC}"
fi
echo ""

# 总结
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}检查结果总结${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "总检查项: ${TOTAL_CHECKS}"
echo -e "${GREEN}通过: ${PASSED_CHECKS}${NC}"
if [ $FAILED_CHECKS -gt 0 ]; then
    echo -e "${RED}失败: ${FAILED_CHECKS}${NC}"
    echo ""
    echo -e "${YELLOW}建议:${NC}"
    echo -e "${YELLOW}1. 检查数据库服务是否运行${NC}"
    echo -e "${YELLOW}2. 检查网络连接和防火墙设置${NC}"
    echo -e "${YELLOW}3. 验证数据库用户权限配置${NC}"
    echo -e "${YELLOW}4. 确认数据库已创建并初始化${NC}"
    exit 1
else
    echo -e "${GREEN}失败: ${FAILED_CHECKS}${NC}"
    echo ""
    echo -e "${GREEN}✓ 所有检查通过！数据库连接正常。${NC}"
    exit 0
fi

