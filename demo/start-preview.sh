#!/bin/bash

# WVP-Pro OpenAPI Demo 预览启动脚本

echo "🚀 WVP-Pro OpenAPI Demo 预览启动脚本"
echo "=================================="
echo ""

# 检查 Node.js 是否安装
if ! command -v node &> /dev/null; then
    echo "❌ 错误: 未找到 Node.js，请先安装 Node.js"
    exit 1
fi

# 检查 npm 是否安装
if ! command -v npm &> /dev/null; then
    echo "❌ 错误: 未找到 npm，请先安装 npm"
    exit 1
fi

echo "✅ Node.js 版本: $(node -v)"
echo "✅ npm 版本: $(npm -v)"
echo ""

# 检查 node_modules 是否存在
if [ ! -d "node_modules" ]; then
    echo "📦 正在安装依赖..."
    npm install
    if [ $? -ne 0 ]; then
        echo "❌ 依赖安装失败"
        exit 1
    fi
    echo "✅ 依赖安装完成"
    echo ""
fi

# 选择启动模式
echo "请选择启动模式:"
echo "1) 开发模式 (推荐) - npm run dev"
echo "2) 构建后预览 - npm run build && npm run preview"
echo "3) 预览服务器 - npm run build && npm run preview:server"
echo ""
read -p "请输入选项 (1-3): " choice

case $choice in
    1)
        echo ""
        echo "🚀 启动开发服务器..."
        echo "📝 访问地址: http://localhost:3000"
        echo "💡 提示: 在浏览器控制台设置 token: localStorage.setItem('wvp-token', 'your-token')"
        echo ""
        npm run dev
        ;;
    2)
        echo ""
        echo "📦 正在构建项目..."
        npm run build
        if [ $? -ne 0 ]; then
            echo "❌ 构建失败"
            exit 1
        fi
        echo "✅ 构建完成"
        echo ""
        echo "🚀 启动预览服务器..."
        echo "📝 访问地址: http://localhost:3000"
        echo ""
        npm run preview
        ;;
    3)
        echo ""
        echo "📦 正在构建项目..."
        npm run build
        if [ $? -ne 0 ]; then
            echo "❌ 构建失败"
            exit 1
        fi
        echo "✅ 构建完成"
        echo ""
        echo "🚀 启动预览服务器 (包含 API 代理)..."
        echo "📝 访问地址: http://localhost:3001"
        echo "📡 API 代理: http://localhost:18080/openapi"
        echo ""
        npm run preview:server
        ;;
    *)
        echo "❌ 无效的选项"
        exit 1
        ;;
esac

