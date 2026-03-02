# 部署和预览指南

## 快速预览

### 方式一：开发模式预览（推荐）

```bash
# 1. 安装依赖
npm install

# 2. 启动开发服务器
npm run dev

# 3. 访问 http://localhost:3000
```

### 方式二：构建后预览

```bash
# 1. 构建生产版本
npm run build

# 2. 预览构建结果
npm run preview

# 3. 访问 http://localhost:3000
```

### 方式三：使用预览服务器

```bash
# 1. 构建项目
npm run build

# 2. 启动预览服务器（包含 API 代理）
npm run preview:server

# 3. 访问 http://localhost:3001
```

## 部署到生产环境

### 静态文件部署

构建后的文件在 `dist` 目录，可以部署到任何静态文件服务器：

1. **Nginx 配置示例**

```nginx
server {
    listen 80;
    server_name your-domain.com;
    root /path/to/demo/dist;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /openapi {
        proxy_pass http://localhost:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

2. **Apache 配置示例**

```apache
<VirtualHost *:80>
    ServerName your-domain.com
    DocumentRoot /path/to/demo/dist

    <Directory /path/to/demo/dist>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ProxyPass /openapi http://localhost:18080/openapi
    ProxyPassReverse /openapi http://localhost:18080/openapi
</VirtualHost>
```

### Docker 部署

创建 `Dockerfile`:

```dockerfile
FROM node:18-alpine as builder

WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

创建 `nginx.conf`:

```nginx
server {
    listen 80;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location /openapi {
        proxy_pass http://host.docker.internal:18080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

构建和运行：

```bash
docker build -t wvp-demo .
docker run -d -p 8080:80 wvp-demo
```

## 配置说明

### API 代理配置

在 `vite.config.js` 中配置开发环境的 API 代理：

```javascript
proxy: {
  '/openapi': {
    target: 'http://localhost:18080',  // WVP-Pro 服务器地址
    changeOrigin: true
  }
}
```

### 生产环境配置

生产环境需要配置反向代理，将 `/openapi` 请求转发到 WVP-Pro 服务器。

### 认证 Token 配置

在浏览器控制台设置认证 token：

```javascript
localStorage.setItem('wvp-token', 'your-token-here')
```

或者修改代码自动从 URL 参数获取：

```javascript
// 在 main.js 中添加
const urlParams = new URLSearchParams(window.location.search)
const token = urlParams.get('token')
if (token) {
  localStorage.setItem('wvp-token', token)
}
```

然后访问：`http://localhost:3000?token=your-token`

## 常见问题

### 1. CORS 跨域问题

如果遇到跨域问题，需要在 WVP-Pro 服务器配置 CORS：

```java
// 在 WebSecurityConfig 中添加
corsConfiguration.addAllowedOriginPattern("http://localhost:3000");
```

### 2. 视频无法播放

- 检查浏览器是否支持相应的视频格式
- 检查流媒体服务器是否正常运行
- 检查网络连接和防火墙设置

### 3. API 请求失败

- 检查 token 是否正确设置
- 检查 API 代理配置是否正确
- 检查 WVP-Pro 服务器是否正常运行

## 性能优化

1. **启用 Gzip 压缩**
2. **使用 CDN 加速静态资源**
3. **配置浏览器缓存**
4. **使用 HTTP/2**

## 安全建议

1. **使用 HTTPS**
2. **配置 CSP 策略**
3. **定期更新依赖**
4. **限制 API 访问频率**

