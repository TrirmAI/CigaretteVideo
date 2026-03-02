#!/bin/bash

# ZLMediaKit配置检查脚本

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

SECRET="5j76zqeppUp7mpsawXIGo5gLW1O6j7CR"
ZLM_URL="http://localhost:8080"

echo "=========================================="
echo "ZLMediaKit 配置检查"
echo "=========================================="
echo ""

# 1. 检查secret配置
echo -e "${YELLOW}[1] 检查Secret配置...${NC}"
ZLM_SECRET=$(curl -s "${ZLM_URL}/index/api/getServerConfig?secret=${SECRET}" 2>/dev/null | python3 -c "import sys, json; data=json.load(sys.stdin); print(data.get('data', {}).get('api.secret', ''))" 2>/dev/null)

if [ "$ZLM_SECRET" = "$SECRET" ]; then
    echo -e "${GREEN}✓ ZLMediaKit Secret: ${ZLM_SECRET}${NC}"
    echo -e "${GREEN}✓ WVP配置Secret: ${SECRET}${NC}"
    echo -e "${GREEN}✓ Secret配置一致${NC}"
else
    echo -e "${RED}✗ Secret配置不一致！${NC}"
    echo "  ZLMediaKit: ${ZLM_SECRET}"
    echo "  WVP配置: ${SECRET}"
fi
echo ""

# 2. 检查Hook配置
echo -e "${YELLOW}[2] 检查Hook配置...${NC}"
HOOK_CONFIG=$(curl -s "${ZLM_URL}/index/api/getServerConfig?secret=${SECRET}" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
config = data.get('data', {})
hooks = {
    'on_play': config.get('hook.on_play', ''),
    'on_publish': config.get('hook.on_publish', ''),
    'on_stream_changed': config.get('hook.on_stream_changed', ''),
    'on_stream_not_found': config.get('hook.on_stream_not_found', ''),
    'on_server_keepalive': config.get('hook.on_server_keepalive', '')
}
for k, v in hooks.items():
    print(f'{k}: {v}')
" 2>/dev/null)

echo "$HOOK_CONFIG"
echo ""

# 3. 检查流媒体服务器状态
echo -e "${YELLOW}[3] 检查流媒体服务器状态...${NC}"
SERVER_INFO=$(curl -s "${ZLM_URL}/index/api/getServerConfig?secret=${SECRET}" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('code') == 0:
    print('✓ ZLMediaKit API连接正常')
    config = data.get('data', {})
    print(f\"  媒体服务器ID: {config.get('general.mediaServerId', 'N/A')}\")
    print(f\"  监听IP: {config.get('general.listen_ip', 'N/A')}\")
else:
    print('✗ ZLMediaKit API连接失败')
    print(f\"  错误: {data.get('msg', 'Unknown')}\")
" 2>/dev/null)

echo "$SERVER_INFO"
echo ""

# 4. 检查当前流列表
echo -e "${YELLOW}[4] 检查当前流列表...${NC}"
STREAM_LIST=$(curl -s "${ZLM_URL}/index/api/getMediaList?secret=${SECRET}" 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('code') == 0:
    streams = data.get('data', [])
    print(f'当前活跃流数量: {len(streams)}')
    if streams:
        print('流列表:')
        for s in streams[:5]:
            print(f\"  - {s.get('app', 'N/A')}/{s.get('stream', 'N/A')}\")
else:
    print(f'获取流列表失败: {data.get('msg', 'Unknown')}')
" 2>/dev/null)

echo "$STREAM_LIST"
echo ""

# 5. 检查WVP数据库中的流媒体服务器配置
echo -e "${YELLOW}[5] 检查WVP数据库配置...${NC}"
DB_CONFIG=$(docker exec alldata-mysql mysql -uroot -p123456 wvp -e "SELECT id, ip, http_port, secret FROM wvp_media_server LIMIT 1;" 2>&1 | grep -v "Warning" | tail -1)

if [ ! -z "$DB_CONFIG" ]; then
    echo "数据库中的流媒体服务器配置:"
    echo "$DB_CONFIG"
else
    echo -e "${RED}✗ 无法读取数据库配置${NC}"
fi
echo ""

echo "=========================================="
echo "检查完成"
echo "=========================================="

