@echo off
chcp 65001 >nul
echo 🚀 WVP-Pro OpenAPI Demo 预览启动脚本
echo ==================================
echo.

REM 检查 Node.js 是否安装
where node >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到 Node.js，请先安装 Node.js
    pause
    exit /b 1
)

REM 检查 npm 是否安装
where npm >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ 错误: 未找到 npm，请先安装 npm
    pause
    exit /b 1
)

echo ✅ Node.js 版本:
node -v
echo ✅ npm 版本:
npm -v
echo.

REM 检查 node_modules 是否存在
if not exist "node_modules" (
    echo 📦 正在安装依赖...
    call npm install
    if %errorlevel% neq 0 (
        echo ❌ 依赖安装失败
        pause
        exit /b 1
    )
    echo ✅ 依赖安装完成
    echo.
)

REM 选择启动模式
echo 请选择启动模式:
echo 1) 开发模式 (推荐) - npm run dev
echo 2) 构建后预览 - npm run build ^&^& npm run preview
echo 3) 预览服务器 - npm run build ^&^& npm run preview:server
echo.
set /p choice="请输入选项 (1-3): "

if "%choice%"=="1" (
    echo.
    echo 🚀 启动开发服务器...
    echo 📝 访问地址: http://localhost:3000
    echo 💡 提示: 在浏览器控制台设置 token: localStorage.setItem('wvp-token', 'your-token')
    echo.
    call npm run dev
) else if "%choice%"=="2" (
    echo.
    echo 📦 正在构建项目...
    call npm run build
    if %errorlevel% neq 0 (
        echo ❌ 构建失败
        pause
        exit /b 1
    )
    echo ✅ 构建完成
    echo.
    echo 🚀 启动预览服务器...
    echo 📝 访问地址: http://localhost:3000
    echo.
    call npm run preview
) else if "%choice%"=="3" (
    echo.
    echo 📦 正在构建项目...
    call npm run build
    if %errorlevel% neq 0 (
        echo ❌ 构建失败
        pause
        exit /b 1
    )
    echo ✅ 构建完成
    echo.
    echo 🚀 启动预览服务器 (包含 API 代理)...
    echo 📝 访问地址: http://localhost:3001
    echo 📡 API 代理: http://localhost:18080/openapi
    echo.
    call npm run preview:server
) else (
    echo ❌ 无效的选项
    pause
    exit /b 1
)

pause

