# 📺 Demo 预览指南

## 🎯 快速预览

### 方法一：使用启动脚本（最简单）

**Linux/Mac:**
```bash
cd demo
./start-preview.sh
```

**Windows:**
```cmd
cd demo
start-preview.bat
```

### 方法二：手动启动

#### 1. 开发模式预览（推荐）

```bash
# 安装依赖（首次运行）
npm install

# 启动开发服务器
npm run dev

# 访问 http://localhost:3000
```

#### 2. 构建后预览

```bash
# 构建项目
npm run build

# 预览构建结果
npm run preview

# 访问 http://localhost:3000
```

#### 3. 使用预览服务器（包含 API 代理）

```bash
# 构建项目
npm run build

# 启动预览服务器
npm run preview:server

# 访问 http://localhost:3001
```

## 🔑 设置认证 Token

在浏览器控制台（F12）执行：

```javascript
localStorage.setItem('wvp-token', 'your-token-here')
```

或者通过 URL 参数传递（需要修改代码）：

```
http://localhost:3000?token=your-token-here
```

## 📋 预览功能

### ✅ 已实现功能

- [x] 设备目录树展示（懒加载）
- [x] 设备/通道搜索
- [x] 视频流播放（FLV/HLS/WebRTC）
- [x] 在线/离线状态显示
- [x] 流信息展示
- [x] 响应式设计

### 🎨 界面预览

1. **左侧面板**: 设备树形结构
   - 设备节点（蓝色图标）
   - 通道节点（绿色图标）
   - 在线/离线标签

2. **右侧面板**: 视频播放器
   - 视频播放窗口
   - 流信息展示
   - 控制按钮

3. **顶部工具栏**: 
   - 搜索框
   - 刷新按钮

## 🌐 访问地址

- **开发模式**: http://localhost:3000
- **预览模式**: http://localhost:3000 (vite preview)
- **预览服务器**: http://localhost:3001 (自定义服务器)

## 📱 移动端预览

项目支持响应式设计，可以在移动设备上访问：

1. 确保开发服务器允许外部访问（已在配置中设置）
2. 在移动设备浏览器访问：`http://your-ip:3000`

## 🔧 配置说明

### 修改 API 地址

编辑 `vite.config.js`:

```javascript
proxy: {
  '/openapi': {
    target: 'http://your-server:18080',  // 修改这里
    changeOrigin: true
  }
}
```

### 修改端口

编辑 `vite.config.js`:

```javascript
server: {
  port: 3000,  // 修改这里
  // ...
}
```

## 📸 截图说明

预览页面包含以下主要区域：

1. **设备树区域**: 显示所有设备和通道
2. **视频播放区域**: 显示选中的视频流
3. **搜索区域**: 快速查找设备或通道
4. **状态指示**: 显示在线/离线状态

## 🐛 故障排除

### 问题 1: 无法连接到服务器

**解决方案:**
- 检查 WVP-Pro 服务是否运行在 `localhost:18080`
- 检查防火墙设置
- 修改 `vite.config.js` 中的代理地址

### 问题 2: 视频无法播放

**解决方案:**
- 检查通道是否在线
- 检查浏览器是否支持视频格式
- 检查网络连接
- 查看浏览器控制台错误信息

### 问题 3: API 请求失败

**解决方案:**
- 检查 token 是否正确设置
- 检查 token 是否过期
- 检查服务器是否正常运行
- 查看网络请求详情

## 📚 相关文档

- [快速开始](./QUICK_START.md)
- [部署指南](./DEPLOY.md)
- [README](./README.md)

## 💡 提示

1. **首次运行**: 需要先运行 `npm install` 安装依赖
2. **Token 设置**: 必须设置有效的 token 才能访问 API
3. **浏览器兼容**: 建议使用 Chrome、Edge 或 Firefox 最新版本
4. **网络要求**: 需要能够访问 WVP-Pro 服务器

## 🎉 开始预览

现在你可以开始预览 demo 了！

```bash
cd demo
npm install
npm run dev
```

然后在浏览器访问 http://localhost:3000 🚀

