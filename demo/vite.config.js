import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  base: './', // 使用相对路径，方便部署
  server: {
    port: 3000,
    host: '0.0.0.0', // 允许外部访问
    proxy: {
      // 代理所有 /api 请求到后端服务器
      '/api': {
        target: 'http://localhost:18080',
        changeOrigin: true,
        secure: false
      },
      // 代理 OpenAPI 请求
      '/openapi': {
        target: 'http://localhost:18080',
        changeOrigin: true,
        secure: false
      },
      // 代理流媒体服务器请求（WebRTC等）
      // 根据文档，WebRTC API 路径为: /index/api/webrtc
      // 注意：需要根据实际的流媒体服务器地址修改target
      '/index': {
        target: 'http://127.0.0.1:8080', // 流媒体服务器地址（ZLMediaKit默认HTTP端口）
        changeOrigin: true,
        secure: false,
        ws: true, // 支持WebSocket（用于WebSocket FLV等协议）
        rewrite: (path) => path // 保持路径不变
        // 注意：Vite 代理默认支持 POST 请求，无需特殊配置
        // ZLMRTCClient 会自动使用 POST 方法发送 SDP 到 /index/api/webrtc
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    sourcemap: false,
    minify: 'esbuild',
    rollupOptions: {
      output: {
        manualChunks: {
          'element-plus': ['element-plus'],
          'vue': ['vue']
        }
      }
    }
  },
  preview: {
    port: 3000,
    host: '0.0.0.0',
    open: true
  }
})

