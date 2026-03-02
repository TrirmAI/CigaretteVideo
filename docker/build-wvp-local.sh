#!/bin/bash
# WVP-Pro Docker 镜像构建脚本（使用本地已编译的 JAR 文件）

set -e

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 获取版本号（从 pom.xml）
VERSION=$(grep -m1 '<version>' ../pom.xml | sed 's/.*<version>\(.*\)<\/version>.*/\1/' | tr -d ' ')

echo -e "${GREEN}开始构建 WVP-Pro Docker 镜像（使用本地 JAR）...${NC}"
echo -e "${YELLOW}版本: ${VERSION}${NC}"

# 检查是否在正确的目录
if [ ! -f "wvp/Dockerfile.local" ]; then
    echo -e "${RED}错误: 请在 docker 目录下执行此脚本${NC}"
    exit 1
fi

# 检查本地 JAR 文件是否存在
JAR_FILE=$(find ../target -name "wvp-pro-*.jar" -type f | head -1)
if [ -z "$JAR_FILE" ]; then
    echo -e "${RED}错误: 未找到已编译的 JAR 文件${NC}"
    echo -e "${YELLOW}请先运行: mvn clean package -Dmaven.test.skip=true${NC}"
    exit 1
fi

echo -e "${GREEN}找到 JAR 文件: $JAR_FILE${NC}"
ls -lh "$JAR_FILE"

# 构建镜像（从项目根目录构建，以便访问 target 目录）
echo -e "${GREEN}正在构建镜像...${NC}"
cd ..
docker build \
    -f docker/wvp/Dockerfile.local \
    -t wvp-pro:${VERSION} \
    -t wvp-pro:latest \
    .

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

