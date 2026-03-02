#!/bin/bash
# 同步本地数据库业务分组信息到远程数据库
# 使用方法: ./sync-common-group.sh

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 本地数据库配置
LOCAL_DB_HOST="127.0.0.1"
LOCAL_DB_PORT="3306"
LOCAL_DB_USER="root"
LOCAL_DB_PASSWORD="123456"
LOCAL_DB_NAME="wvp"

# 远程服务器配置
REMOTE_HOST="172.31.127.47"
REMOTE_USER="root"
REMOTE_PASSWORD="Shenzhoulu9#"
REMOTE_DB_CONTAINER="polaris-mysql"
REMOTE_DB_USER="wvp_user"
REMOTE_DB_PASSWORD="wvp_password"
REMOTE_DB_NAME="wvp"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}同步业务分组数据到远程数据库${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查本地MySQL连接
echo -e "${BLUE}检查本地数据库连接...${NC}"
if ! mysql -h"${LOCAL_DB_HOST}" -P"${LOCAL_DB_PORT}" -u"${LOCAL_DB_USER}" -p"${LOCAL_DB_PASSWORD}" -e "USE ${LOCAL_DB_NAME};" &>/dev/null; then
    echo -e "${RED}错误: 无法连接到本地数据库${NC}"
    echo -e "${YELLOW}请检查数据库配置:${NC}"
    echo -e "  主机: ${LOCAL_DB_HOST}:${LOCAL_DB_PORT}"
    echo -e "  用户: ${LOCAL_DB_USER}"
    echo -e "  数据库: ${LOCAL_DB_NAME}"
    exit 1
fi
echo -e "${GREEN}✓ 本地数据库连接正常${NC}"
echo ""

# 查询本地业务分组数据
echo -e "${BLUE}查询本地业务分组数据...${NC}"
LOCAL_COUNT=$(mysql -h"${LOCAL_DB_HOST}" -P"${LOCAL_DB_PORT}" -u"${LOCAL_DB_USER}" -p"${LOCAL_DB_PASSWORD}" -D"${LOCAL_DB_NAME}" -sN -e "SELECT COUNT(*) FROM wvp_common_group;" 2>/dev/null || echo "0")

if [ "$LOCAL_COUNT" = "0" ] || [ -z "$LOCAL_COUNT" ]; then
    echo -e "${YELLOW}警告: 本地数据库中没有业务分组数据${NC}"
    exit 0
fi

echo -e "${GREEN}✓ 找到 ${LOCAL_COUNT} 条业务分组记录${NC}"
echo ""

# 导出本地数据到SQL文件
TEMP_SQL="/tmp/wvp_common_group_sync_$(date +%Y%m%d_%H%M%S).sql"
echo -e "${BLUE}导出本地业务分组数据...${NC}"

# 先删除旧数据（如果需要）
cat > "${TEMP_SQL}" << 'EOF'
-- 同步业务分组数据
-- 注意：此操作会先删除远程数据库中的现有业务分组数据

-- 禁用外键检查（如果有外键约束）
SET FOREIGN_KEY_CHECKS=0;

-- 删除现有数据（可选，如果需要完全替换）
-- DELETE FROM wvp_common_group;

EOF

# 导出数据（使用INSERT IGNORE避免重复）
mysql -h"${LOCAL_DB_HOST}" -P"${LOCAL_DB_PORT}" -u"${LOCAL_DB_USER}" -p"${LOCAL_DB_PASSWORD}" -D"${LOCAL_DB_NAME}" -sN -e "
SELECT CONCAT('INSERT IGNORE INTO wvp_common_group (id, device_id, name, parent_id, parent_device_id, business_group, create_time, update_time, civil_code, alias) VALUES (',
    IFNULL(id, 'NULL'), ', ',
    QUOTE(IFNULL(device_id, '')), ', ',
    QUOTE(IFNULL(name, '')), ', ',
    IFNULL(parent_id, 'NULL'), ', ',
    IFNULL(QUOTE(parent_device_id), 'NULL'), ', ',
    QUOTE(IFNULL(business_group, '')), ', ',
    QUOTE(IFNULL(create_time, '')), ', ',
    QUOTE(IFNULL(update_time, '')), ', ',
    IFNULL(QUOTE(civil_code), 'NULL'), ', ',
    IFNULL(QUOTE(alias), 'NULL'),
    ');')
FROM wvp_common_group
ORDER BY id;
" >> "${TEMP_SQL}" 2>/dev/null

cat >> "${TEMP_SQL}" << 'EOF'

-- 恢复外键检查
SET FOREIGN_KEY_CHECKS=1;
EOF

echo -e "${GREEN}✓ 数据已导出到: ${TEMP_SQL}${NC}"
echo ""

# 显示导出的数据预览
echo -e "${BLUE}数据预览（前5条）:${NC}"
head -10 "${TEMP_SQL}" | grep -E "^INSERT" | head -5
echo ""

# 传输SQL文件到远程服务器
echo -e "${BLUE}传输SQL文件到远程服务器...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" scp -o StrictHostKeyChecking=no "${TEMP_SQL}" "${REMOTE_USER}@${REMOTE_HOST}:/tmp/" &>/dev/null
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn scp -o StrictHostKeyChecking=no "${TEMP_SQL}" ${REMOTE_USER}@${REMOTE_HOST}:/tmp/
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
else
    echo -e "${RED}错误: 需要安装 sshpass 或 expect 来传输文件${NC}"
    rm -f "${TEMP_SQL}"
    exit 1
fi

REMOTE_SQL_FILE="/tmp/$(basename ${TEMP_SQL})"
echo -e "${GREEN}✓ 文件已传输到远程服务器: ${REMOTE_SQL_FILE}${NC}"
echo ""

# 执行SQL导入
echo -e "${BLUE}导入数据到远程数据库...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
        "docker exec -i ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} ${REMOTE_DB_NAME} < ${REMOTE_SQL_FILE}" 2>&1
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 60
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "docker exec -i ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} ${REMOTE_DB_NAME} < ${REMOTE_SQL_FILE}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
fi

# 验证同步结果
echo ""
echo -e "${BLUE}验证同步结果...${NC}"
if command -v sshpass &> /dev/null; then
    REMOTE_COUNT=$(sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
        "docker exec ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} -D${REMOTE_DB_NAME} -sN -e 'SELECT COUNT(*) FROM wvp_common_group;'" 2>/dev/null || echo "0")
elif command -v expect &> /dev/null; then
    REMOTE_COUNT=$(expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "docker exec ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} -D${REMOTE_DB_NAME} -sN -e 'SELECT COUNT(*) FROM wvp_common_group;'"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
EOF
    REMOTE_COUNT=$(echo "$REMOTE_COUNT" | grep -E "^[0-9]+$" | tail -1)
fi

echo -e "${GREEN}✓ 同步完成！${NC}"
echo ""
echo -e "${BLUE}同步统计:${NC}"
echo -e "  本地记录数: ${LOCAL_COUNT}"
echo -e "  远程记录数: ${REMOTE_COUNT:-未知}"

# 清理临时文件
rm -f "${TEMP_SQL}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" "rm -f ${REMOTE_SQL_FILE}" &>/dev/null
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 10
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "rm -f ${REMOTE_SQL_FILE}"
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
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}同步完成！${NC}"
echo -e "${GREEN}========================================${NC}"

