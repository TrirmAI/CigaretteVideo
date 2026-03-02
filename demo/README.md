# WVP-Pro OpenAPI Vue3 Demo

这是一个基于 Vue3 的视频目录树查询和播放功能的演示项目。

## 🚀 快速预览

### 一键启动（推荐）

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

### 手动启动

```bash
# 1. 安装依赖
npm install

# 2. 启动开发服务器
npm run dev

# 3. 访问 http://localhost:3000
```

> 💡 **提示**: 详细预览说明请查看 [PREVIEW.md](./PREVIEW.md)

## 功能特性

- 📹 设备目录树展示（懒加载）
- 🔍 设备/通道搜索
- ▶️ 视频流播放（支持 FLV/HLS/WebRTC）
- 📊 流信息显示
- 🎯 实时状态更新
- 📱 响应式设计

## 技术栈

- Vue 3
- Element Plus
- Axios
- Vite

## 📦 安装和运行

### 方式一：快速启动（推荐）

使用提供的启动脚本：

**Linux/Mac:**
```bash
./start-preview.sh
```

**Windows:**
```cmd
start-preview.bat
```

### 方式二：手动启动

#### 1. 安装依赖

```bash
cd demo
npm install
```

#### 2. 配置 API 地址

编辑 `vite.config.js` 中的代理配置，将 `target` 修改为你的 WVP-Pro 服务器地址：

```javascript
proxy: {
  '/openapi': {
    target: 'http://localhost:18080',  // 修改为你的服务器地址
    changeOrigin: true
  }
}
```

#### 3. 配置认证 Token

在浏览器控制台（F12）执行以下代码设置 token：

```javascript
localStorage.setItem('wvp-token', 'your-token-here')
```

#### 4. 启动开发服务器

```bash
npm run dev
```

访问 http://localhost:3000

### 方式三：构建后预览

```bash
# 构建项目
npm run build

# 预览构建结果
npm run preview

# 或使用预览服务器（包含 API 代理）
npm run preview:server
```

## 项目结构

```
demo/
├── src/
│   ├── components/
│   │   ├── VideoTree.vue      # 视频目录树组件
│   │   └── VideoPlayer.vue    # 视频播放组件
│   ├── api/
│   │   └── video.js           # 视频相关 API
│   ├── App.vue                 # 主应用组件
│   ├── main.js                # 入口文件
│   └── style.css              # 全局样式
├── index.html                 # HTML 模板
├── vite.config.js             # Vite 配置
├── package.json               # 项目配置
└── README.md                  # 说明文档
```

## API 接口说明

### 获取设备树

```
GET /openapi/v1/video/tree?query=&status=
```

### 获取设备通道列表

```
GET /openapi/v1/video/devices/{deviceId}/channels?page=1&count=1000
```

### 开始播放

```
GET /openapi/v1/video/play/{deviceId}/{channelId}
```

### 停止播放

```
GET /openapi/v1/video/stop/{deviceId}/{channelId}
```

## 使用说明

1. **查看设备树**: 左侧显示设备列表，点击设备节点可展开查看通道
2. **搜索**: 在顶部搜索框输入关键词，点击搜索或按回车键
3. **播放视频**: 点击通道节点，右侧会显示视频播放器并开始播放
4. **停止播放**: 点击"停止播放"按钮停止当前视频流

## 注意事项

1. 需要先登录 WVP-Pro 系统获取 token
2. 确保 WVP-Pro 服务器已启动并可访问
3. 视频播放需要浏览器支持相应的视频格式（FLV/HLS/WebRTC）
4. 建议使用 Chrome 或 Edge 浏览器以获得最佳体验

## 开发说明

### 添加新功能

1. 在 `src/api/video.js` 中添加新的 API 方法
2. 在组件中调用 API 方法
3. 更新 UI 界面

### 自定义样式

修改 `src/style.css` 或组件内的 `<style>` 部分

## 📚 更多文档

- [快速开始指南](./QUICK_START.md) - 快速上手指南
- [预览指南](./PREVIEW.md) - 详细的预览说明
- [部署指南](./DEPLOY.md) - 生产环境部署说明

## 🎯 预览地址

启动后访问：
- **开发模式**: http://localhost:3000
- **预览模式**: http://localhost:3000 (vite preview)
- **预览服务器**: http://localhost:3001 (自定义服务器)

## 📝 许可证

MIT

