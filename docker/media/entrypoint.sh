#!/bin/bash

# 获取环境变量
HOOK_IP=${SIP_ShowIP:-127.0.0.1}
HOOK_PORT=18080

# 替换 config.ini 中的 Hook 地址
sed -i "s|on_play=.*|on_play=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_play|g" /conf/config.ini
sed -i "s|on_publish=.*|on_publish=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_publish|g" /conf/config.ini
sed -i "s|on_record_mp4=.*|on_record_mp4=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_record_mp4|g" /conf/config.ini
sed -i "s|on_rtp_server_timeout=.*|on_rtp_server_timeout=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_rtp_server_timeout|g" /conf/config.ini
sed -i "s|on_send_rtp_stopped=.*|on_send_rtp_stopped=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_send_rtp_stopped|g" /conf/config.ini
sed -i "s|on_server_keepalive=.*|on_server_keepalive=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_server_keepalive|g" /conf/config.ini
sed -i "s|on_server_started=.*|on_server_started=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_server_started|g" /conf/config.ini
sed -i "s|on_stream_changed=.*|on_stream_changed=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_stream_changed|g" /conf/config.ini
sed -i "s|on_stream_none_reader=.*|on_stream_none_reader=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_stream_none_reader|g" /conf/config.ini
sed -i "s|on_stream_not_found=.*|on_stream_not_found=http://${HOOK_IP}:${HOOK_PORT}/index/hook/on_stream_not_found|g" /conf/config.ini

# 启动 MediaServer
exec "$@"
