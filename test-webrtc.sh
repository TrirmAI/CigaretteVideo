#!/bin/bash

# WebRTC播放功能测试脚本

# 配置
WVP_HOST="http://127.0.0.1:18080"
TOKEN="eyJhbGciOiJSUzI1NiIsImtpZCI6IjNlNzk2NDZjNGRiYzQwODM4M2E5ZWVkMDlmMmI4NWFlIn0.eyJqdGkiOiJzVWFFUE1fOThMTENENU5WTHFKSHNBIiwiaWF0IjoxNzY1Nzk1MzI4LCJleHAiOjEwNzkyMDU1MzQwMzkwNCwibmJmIjoxNzY1Nzk1MzI4LCJzdWIiOiJsb2dpbiIsImF1ZCI6IkF1ZGllbmNlIiwidXNlck5hbWUiOiJhZG1pbiIsImFwaUtleUlkIjoxfQ.kbqVeTb-TwYhVIkgDTBe0eY5gH4i6gsq6T7tt44Z1gE1rYGy0NN3EgRjAtoBz8-9uWunW-_s0eu1DO2jZot3muBMDX5sbndhLtI3EoBo4laZER-mV__8mX0qM_02NwKtMVxh-iDQLscxF1uaukgaiukGIbfFJFIhTrmdQ2UXerLp9CAE6buhmhu1TDjJooQlIY3adr7tulfO4ibLDIs-SVAq_Y8Bop1I6pOHuwmrSIXtDS-A7IwFjUrMmVfuqNVm9YjvP4r6mxSFL5xaMcJXkChKjxsMkLFMgQc3qZqRi4oEm2SaSVywbOlivkHpkBn1X2o44CA6UcduWvADi_egcg"

echo "=========================================="
echo "WebRTC播放功能测试"
echo "=========================================="
echo ""

# 1. 检查WVP服务状态
echo "1. 检查WVP服务状态..."
WVP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${WVP_HOST}/api/device/query/devices?page=1&count=1" -H "access-token: ${TOKEN}")
if [ "$WVP_STATUS" = "200" ]; then
    echo "   ✅ WVP服务运行正常 (HTTP $WVP_STATUS)"
else
    echo "   ❌ WVP服务异常 (HTTP $WVP_STATUS)"
    exit 1
fi
echo ""

# 2. 检查流媒体服务器状态
echo "2. 检查流媒体服务器状态..."
MEDIA_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:8080/index/api/getMediaList?secret=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR")
if [ "$MEDIA_STATUS" = "200" ]; then
    echo "   ✅ 流媒体服务器运行正常 (HTTP $MEDIA_STATUS)"
else
    echo "   ❌ 流媒体服务器异常 (HTTP $MEDIA_STATUS)"
    exit 1
fi
echo ""

# 3. 获取设备列表（示例）
echo "3. 获取设备列表..."
DEVICE_RESPONSE=$(curl -s "${WVP_HOST}/api/device/query/devices?page=1&count=5" -H "access-token: ${TOKEN}")
DEVICE_COUNT=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('data', {}).get('count', 0))" 2>/dev/null)
if [ -n "$DEVICE_COUNT" ] && [ "$DEVICE_COUNT" != "0" ]; then
    echo "   ✅ 找到 $DEVICE_COUNT 个设备"
    # 获取第一个设备ID
    DEVICE_ID=$(echo "$DEVICE_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); devices=d.get('data', {}).get('list', []); print(devices[0].get('deviceId', '') if devices else '')" 2>/dev/null)
    if [ -n "$DEVICE_ID" ]; then
        echo "   📱 示例设备ID: $DEVICE_ID"
    fi
else
    echo "   ⚠️  未找到设备，请先添加设备"
    DEVICE_ID=""
fi
echo ""

# 4. 测试播放接口（如果有设备）
if [ -n "$DEVICE_ID" ] && [ "$DEVICE_ID" != "" ]; then
    echo "4. 测试播放接口..."
    echo "   设备ID: $DEVICE_ID"
    echo "   通道ID: 34020000001320000011 (示例)"
    echo "   正在调用播放接口..."
    
    PLAY_RESPONSE=$(curl -s -w "\n%{http_code}" "${WVP_HOST}/api/play/start/${DEVICE_ID}/34020000001320000011" -H "access-token: ${TOKEN}" --max-time 30)
    HTTP_CODE=$(echo "$PLAY_RESPONSE" | tail -1)
    RESPONSE_BODY=$(echo "$PLAY_RESPONSE" | head -n -1)
    
    if [ "$HTTP_CODE" = "200" ]; then
        echo "   ✅ 播放接口调用成功"
        # 解析返回的流信息
        RTC_URL=$(echo "$RESPONSE_BODY" | python3 -c "import sys, json; d=json.load(sys.stdin); data=d.get('data', {}); print(data.get('rtc', '') or data.get('rtcs', ''))" 2>/dev/null)
        if [ -n "$RTC_URL" ] && [ "$RTC_URL" != "" ]; then
            echo "   ✅ WebRTC地址获取成功:"
            echo "      $RTC_URL"
            # 检查地址格式
            if echo "$RTC_URL" | grep -q "webrtc"; then
                echo "   ✅ WebRTC地址格式正确"
            else
                echo "   ⚠️  WebRTC地址格式可能不正确"
            fi
            # 检查端口
            if echo "$RTC_URL" | grep -q ":8080"; then
                echo "   ✅ HTTP端口正确 (8080)"
            else
                echo "   ⚠️  HTTP端口可能不正确"
            fi
        else
            echo "   ⚠️  未获取到WebRTC地址"
            echo "   响应内容: $RESPONSE_BODY"
        fi
    else
        echo "   ❌ 播放接口调用失败 (HTTP $HTTP_CODE)"
        echo "   响应内容: $RESPONSE_BODY"
    fi
else
    echo "4. 跳过播放接口测试（无可用设备）"
fi
echo ""

# 5. 测试流信息查询接口
echo "5. 测试流信息查询接口..."
echo "   测试参数: app=rtp, stream=test_stream"
STREAM_INFO_RESPONSE=$(curl -s "${WVP_HOST}/api/media/stream_info_by_app_and_stream?app=rtp&stream=test_stream" -H "access-token: ${TOKEN}" --max-time 10)
STREAM_INFO_CODE=$(echo "$STREAM_INFO_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); print(d.get('code', -1))" 2>/dev/null)
if [ "$STREAM_INFO_CODE" = "0" ] || [ "$STREAM_INFO_CODE" = "-1" ]; then
    echo "   ✅ 流信息查询接口正常"
    RTC_URL=$(echo "$STREAM_INFO_RESPONSE" | python3 -c "import sys, json; d=json.load(sys.stdin); data=d.get('data', {}); print(data.get('rtc', '') or data.get('rtcs', ''))" 2>/dev/null)
    if [ -n "$RTC_URL" ] && [ "$RTC_URL" != "" ]; then
        echo "   ✅ 返回的WebRTC地址: $RTC_URL"
    fi
else
    echo "   ⚠️  流信息查询接口响应: $STREAM_INFO_CODE"
fi
echo ""

# 6. 验证流媒体服务器RTC配置
echo "6. 验证流媒体服务器RTC配置..."
RTC_CONFIG=$(curl -s "http://127.0.0.1:8080/index/api/getServerConfig?secret=5j76zqeppUp7mpsawXIGo5gLW1O6j7CR" | python3 -c "import sys, json; d=json.load(sys.stdin); rtc=d.get('rtc', {}); print('port:', rtc.get('port', 'N/A'), 'tcpPort:', rtc.get('tcpPort', 'N/A'), 'externIP:', rtc.get('externIP', 'N/A'))" 2>/dev/null)
if [ -n "$RTC_CONFIG" ]; then
    echo "   ✅ RTC配置: $RTC_CONFIG"
else
    echo "   ⚠️  无法获取RTC配置"
fi
echo ""

echo "=========================================="
echo "测试完成"
echo "=========================================="
echo ""
echo "📝 测试说明:"
echo "   1. 如果看到WebRTC地址，说明配置正确"
echo "   2. WebRTC地址格式应为: http://172.31.127.42:8080/index/api/webrtc?..."
echo "   3. 实际播放需要先推流，然后才能播放"
echo ""

