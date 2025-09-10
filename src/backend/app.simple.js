/**
 * 超级简化版 app.js
 */

const express = require('express');

// 创建Express应用
const app = express();

// 基本中间件
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 简单路由
app.get('/', (req, res) => {
  res.json({
    message: 'GCCC Backend API',
    version: '1.0.0',
    status: 'running',
    timestamp: new Date().toISOString(),
  });
});

app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    uptime: process.uptime(),
  });
});

// 导出app
module.exports = app;
