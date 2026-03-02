#!/bin/bash
# WVP-Pro Docker 镜像构建脚本

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取版本号（从 pom.xml）
VERSION=$(grep -m1 '<version>' ../pom.xml | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | tr -d ' ')

echo -e "${GREEN}开始构建 WVP-Pro Docker 镜像...${NC}"
echo -e "${YELLOW}版本: ${VERSION}${NC}"

# 检查是否在正确的目录
if [ ! -f "wvp/Dockerfile" ]; then
    echo -e "${RED}错误: 请在 docker 目录下执行此脚本${NC}"
    exit 1
fi

# 检测并使用系统代理
PROXY_ARGS=""
USE_PROXY="${USE_PROXY:-auto}"

# 函数：将本地地址转换为 Docker 可访问的地址
convert_proxy_host() {
    local host=$1
    if [ "$host" = "127.0.0.1" ] || [ "$host" = "localhost" ]; then
        echo "host.docker.internal"
    else
        echo "$host"
    fi
}

# 如果明确禁用代理
if [ "$USE_PROXY" = "no" ] || [ "$USE_PROXY" = "false" ]; then
    echo -e "${YELLOW}已禁用代理${NC}"
    PROXY_ARGS=""
elif [ -n "$http_proxy" ] || [ -n "$HTTP_PROXY" ]; then
    # 从环境变量获取代理
    HTTP_PROXY_VALUE="${http_proxy:-$HTTP_PROXY}"
    # 提取主机和端口
    PROXY_HOST=$(echo "$HTTP_PROXY_VALUE" | sed 's|http://||' | sed 's|https://||' | cut -d: -f1)
    PROXY_PORT=$(echo "$HTTP_PROXY_VALUE" | sed 's|http://||' | sed 's|https://||' | cut -d: -f2 | cut -d/ -f1)
    PROXY_HOST=$(convert_proxy_host "$PROXY_HOST")
    HTTP_PROXY_VALUE="http://${PROXY_HOST}:${PROXY_PORT}"
    PROXY_ARGS="$PROXY_ARGS --build-arg http_proxy=$HTTP_PROXY_VALUE"
    PROXY_ARGS="$PROXY_ARGS --build-arg HTTP_PROXY=$HTTP_PROXY_VALUE"
    echo -e "${YELLOW}检测到 HTTP 代理: $HTTP_PROXY_VALUE${NC}"
fi

if [ -n "$https_proxy" ] || [ -n "$HTTPS_PROXY" ]; then
    HTTPS_PROXY_VALUE="${https_proxy:-$HTTPS_PROXY}"
    PROXY_HOST=$(echo "$HTTPS_PROXY_VALUE" | sed 's|http://||' | sed 's|https://||' | cut -d: -f1)
    PROXY_PORT=$(echo "$HTTPS_PROXY_VALUE" | sed 's|http://||' | sed 's|https://||' | cut -d: -f2 | cut -d/ -f1)
    PROXY_HOST=$(convert_proxy_host "$PROXY_HOST")
    HTTPS_PROXY_VALUE="http://${PROXY_HOST}:${PROXY_PORT}"
    PROXY_ARGS="$PROXY_ARGS --build-arg https_proxy=$HTTPS_PROXY_VALUE"
    PROXY_ARGS="$PROXY_ARGS --build-arg HTTPS_PROXY=$HTTPS_PROXY_VALUE"
    echo -e "${YELLOW}检测到 HTTPS 代理: $HTTPS_PROXY_VALUE${NC}"
fi

if [ -n "$no_proxy" ] || [ -n "$NO_PROXY" ]; then
    NO_PROXY_VALUE="${no_proxy:-$NO_PROXY}"
    PROXY_ARGS="$PROXY_ARGS --build-arg no_proxy=$NO_PROXY_VALUE"
    PROXY_ARGS="$PROXY_ARGS --build-arg NO_PROXY=$NO_PROXY_VALUE"
    echo -e "${YELLOW}检测到 NO_PROXY: $NO_PROXY_VALUE${NC}"
fi

# 如果没有检测到代理且 USE_PROXY=auto，尝试从系统设置获取
if [ -z "$PROXY_ARGS" ] && [ "$USE_PROXY" != "no" ]; then
    # macOS: 尝试从系统设置获取代理
    if command -v networksetup >/dev/null 2>&1; then
        # 尝试多个网络接口
        for INTERFACE in Wi-Fi Ethernet "USB 10/100/1000 LAN" "Thunderbolt Bridge"; do
            PROXY_ENABLED=$(networksetup -getwebproxy "$INTERFACE" 2>/dev/null | grep "Enabled:" | awk '{print $2}')
            if [ "$PROXY_ENABLED" = "Yes" ]; then
                PROXY_HOST=$(networksetup -getwebproxy "$INTERFACE" 2>/dev/null | grep "Server:" | awk '{print $2}' || echo "")
                PROXY_PORT=$(networksetup -getwebproxy "$INTERFACE" 2>/dev/null | grep "Port:" | awk '{print $2}' || echo "")
                if [ -n "$PROXY_HOST" ] && [ -n "$PROXY_PORT" ]; then
                    PROXY_HOST=$(convert_proxy_host "$PROXY_HOST")
                    PROXY_URL="http://${PROXY_HOST}:${PROXY_PORT}"
                    PROXY_ARGS="--build-arg http_proxy=$PROXY_URL --build-arg HTTP_PROXY=$PROXY_URL"
                    PROXY_ARGS="$PROXY_ARGS --build-arg https_proxy=$PROXY_URL --build-arg HTTPS_PROXY=$PROXY_URL"
                    echo -e "${GREEN}✓ 从系统设置检测到代理 ($INTERFACE): $PROXY_URL${NC}"
                    echo -e "${YELLOW}提示: 如果代理连接失败，可以设置 USE_PROXY=no 禁用代理${NC}"
                    break
                fi
            fi
        done
    fi
fi

# 显示最终使用的代理配置
if [ -n "$PROXY_ARGS" ]; then
    echo -e "${GREEN}将使用以下代理配置进行构建:${NC}"
    echo "$PROXY_ARGS" | tr ' ' '\n' | grep -E "(http_proxy|https_proxy)" | sed 's/--build-arg/  /'
fi

# 构建镜像
echo -e "${GREEN}正在构建镜像...${NC}"
docker build \
    $PROXY_ARGS \
    -f wvp/Dockerfile \
    -t wvp-pro:${VERSION} \
    -t wvp-pro:latest \
    ..

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ 镜像构建成功！${NC}"
    echo -e "${GREEN}镜像标签:${NC}"
    echo -e "  - wvp-pro:${VERSION}"
    echo -e "  - wvp-pro:latest"
    echo ""
    echo -e "${YELLOW}使用以下命令运行容器:${NC}"
    echo -e "  docker run -d --name wvp-pro -p 18978:18978 -p 8116:8116/udp -p 8116:8116/tcp wvp-pro:latest"
    echo ""
    echo -e "${YELLOW}或使用 docker-compose:${NC}"
    echo -e "  docker-compose up -d polaris-wvp"
else
    echo -e "${RED}✗ 镜像构建失败！${NC}"
    exit 1
fi

