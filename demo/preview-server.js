#!/usr/bin/env node

/**
 * 简单的预览服务器
 * 用于预览构建后的 demo 项目
 */

const http = require('http')
const fs = require('fs')
const path = require('path')

const PORT = 3001
const DIST_DIR = path.join(__dirname, 'dist')

// MIME 类型映射
const mimeTypes = {
  '.html': 'text/html',
  '.js': 'text/javascript',
  '.css': 'text/css',
  '.json': 'application/json',
  '.png': 'image/png',
  '.jpg': 'image/jpg',
  '.gif': 'image/gif',
  '.svg': 'image/svg+xml',
  '.ico': 'image/x-icon',
  '.woff': 'application/font-woff',
  '.woff2': 'application/font-woff2',
  '.ttf': 'application/font-ttf',
  '.eot': 'application/vnd.ms-fontobject'
}

const server = http.createServer((req, res) => {
  console.log(`${req.method} ${req.url}`)

  // 处理代理请求
  if (req.url.startsWith('/openapi')) {
    // 代理到 WVP-Pro 服务器
    const options = {
      hostname: 'localhost',
      port: 18080,
      path: req.url,
      method: req.method,
      headers: req.headers
    }

    const proxyReq = http.request(options, (proxyRes) => {
      res.writeHead(proxyRes.statusCode, proxyRes.headers)
      proxyRes.pipe(res)
    })

    proxyReq.on('error', (e) => {
      console.error(`代理错误: ${e.message}`)
      res.writeHead(500)
      res.end('代理服务器错误')
    })

    req.pipe(proxyReq)
    return
  }

  // 解析请求路径
  let filePath = path.join(DIST_DIR, req.url === '/' ? 'index.html' : req.url)
  const extname = String(path.extname(filePath)).toLowerCase()
  const contentType = mimeTypes[extname] || 'application/octet-stream'

  // 检查文件是否存在
  fs.exists(filePath, (exists) => {
    if (!exists) {
      // 如果文件不存在，尝试返回 index.html（用于 SPA 路由）
      if (extname === '') {
        filePath = path.join(DIST_DIR, 'index.html')
      } else {
        res.writeHead(404, { 'Content-Type': 'text/html' })
        res.end('<h1>404 Not Found</h1>')
        return
      }
    }

    // 读取文件
    fs.readFile(filePath, (error, content) => {
      if (error) {
        if (error.code === 'ENOENT') {
          res.writeHead(404, { 'Content-Type': 'text/html' })
          res.end('<h1>404 Not Found</h1>')
        } else {
          res.writeHead(500)
          res.end(`服务器错误: ${error.code}`)
        }
      } else {
        res.writeHead(200, { 'Content-Type': contentType })
        res.end(content, 'utf-8')
      }
    })
  })
})

// 检查 dist 目录是否存在
if (!fs.existsSync(DIST_DIR)) {
  console.error('❌ dist 目录不存在，请先运行 npm run build 构建项目')
  process.exit(1)
}

server.listen(PORT, () => {
  console.log('🚀 预览服务器已启动')
  console.log(`📦 服务目录: ${DIST_DIR}`)
  console.log(`🌐 访问地址: http://localhost:${PORT}`)
  console.log(`📡 API 代理: http://localhost:18080/openapi`)
  console.log('\n按 Ctrl+C 停止服务器')
})

