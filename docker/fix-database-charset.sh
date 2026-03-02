#!/bin/bash
# 修复远程数据库字符集问题
# 使用方法: ./fix-database-charset.sh

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
REMOTE_DB_CONTAINER="polaris-mysql"
REMOTE_DB_USER="wvp_user"
REMOTE_DB_PASSWORD="wvp_password"
REMOTE_DB_NAME="wvp"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}修复数据库字符集问题${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查工具
if ! command -v sshpass &> /dev/null && ! command -v expect &> /dev/null; then
    echo -e "${RED}错误: 需要安装 sshpass 或 expect${NC}"
    exit 1
fi

# 创建修复SQL脚本
FIX_SQL=$(cat << 'SQL_EOF'
-- 修复数据库字符集
-- 设置数据库默认字符集
ALTER DATABASE wvp CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- 修复所有表的字符集
ALTER TABLE wvp_common_group CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_device CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_device_channel CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_platform CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_platform_channel CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_media_server CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_user CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_record_plan CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_record_plan_item CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_stream_proxy CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_stream_push CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_device_alarm CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_device_mobile_position CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_common_region CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_user_role CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_user_api_key CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_jt_terminal CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_jt_channel CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_platform_group CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_platform_region CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
ALTER TABLE wvp_cloud_record CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;

-- 显示修复结果
SELECT '字符集修复完成' AS status;
SQL_EOF
)

echo -e "${BLUE}执行字符集修复...${NC}"

if command -v sshpass &> /dev/null; then
    echo "$FIX_SQL" | sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
        "docker exec -i ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} --default-character-set=utf8mb4 ${REMOTE_DB_NAME}" 2>&1 | grep -v Warning
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 60
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "docker exec -i ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} --default-character-set=utf8mb4 ${REMOTE_DB_NAME}"
expect {
    "password:" {
        send "${REMOTE_PASSWORD}\r"
        exp_continue
    }
    eof
}
send "$FIX_SQL\r"
expect eof
EOF
fi

echo ""
echo -e "${GREEN}✓ 字符集修复完成${NC}"
echo ""

# 验证修复结果
echo -e "${BLUE}验证修复结果...${NC}"
if command -v sshpass &> /dev/null; then
    sshpass -p "${REMOTE_PASSWORD}" ssh -o StrictHostKeyChecking=no "${REMOTE_USER}@${REMOTE_HOST}" \
        "docker exec ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} --default-character-set=utf8mb4 -D${REMOTE_DB_NAME} -e 'SET NAMES utf8mb4; SELECT id, name FROM wvp_common_group LIMIT 5;'" 2>&1 | grep -v Warning
elif command -v expect &> /dev/null; then
    expect << EOF
set timeout 30
spawn ssh -o StrictHostKeyChecking=no ${REMOTE_USER}@${REMOTE_HOST} "docker exec ${REMOTE_DB_CONTAINER} mysql -u${REMOTE_DB_USER} -p${REMOTE_DB_PASSWORD} --default-character-set=utf8mb4 -D${REMOTE_DB_NAME} -e 'SET NAMES utf8mb4; SELECT id, name FROM wvp_common_group LIMIT 5;'"
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
echo -e "${GREEN}修复完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}注意: 如果数据仍然显示乱码，可能需要重新同步数据${NC}"
echo -e "${YELLOW}运行: python3 sync-common-group.py${NC}"

