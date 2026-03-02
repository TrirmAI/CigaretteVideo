#!/bin/bash

# WVP API测试脚本
# 用于测试拉流接口是否正常工作

BASE_URL="http://localhost:18080"
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

echo "=========================================="
echo "WVP API 接口测试脚本"
echo "=========================================="
echo ""

# 1. 测试登录接口
echo -e "${YELLOW}[1] 测试登录接口...${NC}"
# 密码需要MD5加密，admin的MD5是: 21232f297a57a5a743894a0e4a801fc3
LOGIN_RESPONSE=$(curl -s -X GET "${BASE_URL}/api/user/login?username=admin&password=21232f297a57a5a743894a0e4a801fc3")

echo "登录响应: $LOGIN_RESPONSE"
echo ""

# 提取token
TOKEN=$(echo $LOGIN_RESPONSE | grep -o '"accessToken":"[^"]*' | cut -d'"' -f4)

if [ -z "$TOKEN" ]; then
  echo -e "${RED}错误: 无法获取token，请检查登录凭据${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Token获取成功: ${TOKEN:0:20}...${NC}"
echo ""

# 2. 测试获取通道列表
echo -e "${YELLOW}[2] 测试获取通道列表...${NC}"
CHANNEL_LIST=$(curl -s -X GET "${BASE_URL}/api/common/channel/list?page=1&count=10" \
  -H "access-token: ${TOKEN}")

echo "通道列表响应: $CHANNEL_LIST" | head -c 500
echo ""
echo ""

# 提取第一个通道ID（从list数组中提取gbId）
# 优先选择在线且有视频的通道
CHANNEL_ID=$(echo $CHANNEL_LIST | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('code') == 0 and data.get('data') and data['data'].get('list'):
        channels = data['data']['list']
        # 优先选择在线的通道
        for ch in channels:
            if ch.get('gbStatus') == 'ON':
                print(ch.get('gbId'))
                break
        else:
            # 如果没有在线的，选择第一个
            if channels:
                print(channels[0].get('gbId'))
except:
    pass
" 2>/dev/null)

if [ -z "$CHANNEL_ID" ] || [ "$CHANNEL_ID" = "null" ]; then
  # 备用方法：使用grep提取
  CHANNEL_ID=$(echo $CHANNEL_LIST | grep -o '"gbId":[0-9]*' | head -1 | cut -d':' -f2)
fi

if [ -z "$CHANNEL_ID" ] || [ "$CHANNEL_ID" = "null" ]; then
  echo -e "${RED}错误: 无法获取通道ID，请确保系统中有可用的通道${NC}"
  echo "通道列表响应: $CHANNEL_LIST" | head -c 500
  exit 1
else
  echo -e "${GREEN}✓ 找到通道ID: ${CHANNEL_ID}${NC}"
fi
echo ""

# 3. 测试播放通道接口
echo -e "${YELLOW}[3] 测试播放通道接口 (channelId=${CHANNEL_ID})...${NC}"
echo "请求URL: ${BASE_URL}/api/common/channel/play?channelId=${CHANNEL_ID}"
echo "请求头: access-token: ${TOKEN:0:20}..."
echo ""

PLAY_RESPONSE=$(curl -s -w "\nHTTP状态码: %{http_code}\n" -X GET "${BASE_URL}/api/common/channel/play?channelId=${CHANNEL_ID}" \
  -H "access-token: ${TOKEN}" \
  --max-time 30)

HTTP_CODE=$(echo "$PLAY_RESPONSE" | grep "HTTP状态码" | cut -d' ' -f2)
RESPONSE_BODY=$(echo "$PLAY_RESPONSE" | grep -v "HTTP状态码")

echo "HTTP状态码: $HTTP_CODE"
echo "响应内容:"
echo "$RESPONSE_BODY" | head -c 1000
echo ""
echo ""

if [ "$HTTP_CODE" = "200" ]; then
  echo -e "${GREEN}✓ 播放接口调用成功${NC}"
  
  # 检查响应内容
  if echo "$RESPONSE_BODY" | grep -q '"code":0'; then
    echo -e "${GREEN}✓ API返回成功状态${NC}"
    
    # 提取流地址
    WS_FLV=$(echo "$RESPONSE_BODY" | grep -o '"ws_flv":"[^"]*' | cut -d'"' -f4)
    WSS_FLV=$(echo "$RESPONSE_BODY" | grep -o '"wss_flv":"[^"]*' | cut -d'"' -f4)
    
    if [ ! -z "$WS_FLV" ]; then
      echo -e "${GREEN}✓ 获取到WS-FLV流地址: ${WS_FLV}${NC}"
    fi
    if [ ! -z "$WSS_FLV" ]; then
      echo -e "${GREEN}✓ 获取到WSS-FLV流地址: ${WSS_FLV}${NC}"
    fi
  else
    ERROR_MSG=$(echo "$RESPONSE_BODY" | grep -o '"msg":"[^"]*' | cut -d'"' -f4)
    echo -e "${RED}✗ API返回错误: ${ERROR_MSG}${NC}"
  fi
elif [ "$HTTP_CODE" = "401" ]; then
  echo -e "${RED}✗ 认证失败 (401)，token可能无效或已过期${NC}"
elif [ "$HTTP_CODE" = "403" ]; then
  echo -e "${RED}✗ 权限不足 (403)${NC}"
else
  echo -e "${RED}✗ 请求失败，HTTP状态码: ${HTTP_CODE}${NC}"
fi

echo ""
echo "=========================================="
echo "测试完成"
echo "=========================================="

