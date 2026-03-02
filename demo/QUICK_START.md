# 🚀 快速开始指南

## 一键启动预览

### 步骤 1: 安装依赖

```bash
cd demo
npm install
```

### 步骤 2: 启动开发服务器

```bash
npm run dev
```

### 步骤 3: 设置认证 Token

打开浏览器控制台（F12），执行：

```javascript
localStorage.setItem('wvp-token', 'your-token-here')
```

> 💡 **提示**: Token 可以从 WVP-Pro 系统登录后获取

### 步骤 4: 访问预览

打开浏览器访问：**http://localhost:3000**

## 📋 功能演示

1. **查看设备树**
   - 左侧显示所有设备
   - 点击设备节点展开查看通道

2. **搜索设备/通道**
   - 在顶部搜索框输入关键词
   - 点击搜索按钮或按回车

3. **播放视频**
   - 点击通道节点
   - 右侧自动开始播放视频

4. **停止播放**
   - 点击"停止播放"按钮

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

### 构建生产版本

```bash
npm run build
```

构建后的文件在 `dist` 目录。

### 预览构建结果

```bash
npm run preview
```

## 📦 项目结构

```
demo/
├── src/
│   ├── components/      # Vue 组件
│   ├── api/            # API 接口
│   └── App.vue         # 主应用
├── dist/               # 构建输出（运行 build 后生成）
├── index.html          # HTML 模板
└── vite.config.js     # Vite 配置
```

## ❓ 常见问题

**Q: 无法连接到服务器？**

A: 确保 WVP-Pro 服务运行在 `http://localhost:18080`，或修改 `vite.config.js` 中的代理地址。

**Q: 视频无法播放？**

A: 
1. 检查通道是否在线
2. 检查浏览器是否支持视频格式
3. 检查网络连接

**Q: API 请求失败？**

A:
1. 检查 token 是否正确设置
2. 检查 token 是否过期
3. 检查服务器是否正常运行

## 📚 更多信息

查看 [README.md](./README.md) 获取详细文档。

查看 [DEPLOY.md](./DEPLOY.md) 获取部署指南。

