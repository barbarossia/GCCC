import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export default defineConfig(({ mode }) => {
  return {
    plugins: [react()],

    // 开发服务器配置
    server: {
      port: 3000,
      open: true,
      cors: true,
      host: true, // 允许外部访问
    },

    // 构建配置
    build: {
      target: 'ES2020',
      outDir: 'dist',
      sourcemap: mode === 'development',
      minify: mode === 'production' ? 'terser' : false,

      // 生产环境优化
      terserOptions:
        mode === 'production'
          ? {
              compress: {
                drop_console: true,
                drop_debugger: true,
              },
            }
          : {},

      // 代码分割
      rollupOptions: {
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom'],
          },
        },
      },

      // 静态资源处理
      assetsDir: 'assets',
      assetsInlineLimit: 4096,
    },

    // 路径解析
    resolve: {
      alias: {
        '@': path.resolve(__dirname, './src'),
        '@/components': path.resolve(__dirname, './src/components'),
        '@/utils': path.resolve(__dirname, './src/utils'),
        '@/types': path.resolve(__dirname, './src/types'),
        '@/contexts': path.resolve(__dirname, './src/contexts'),
      },
    },

    // 环境变量
    define: {
      __APP_VERSION__: JSON.stringify(
        process.env.npm_package_version || '1.0.0'
      ),
      __BUILD_TIME__: JSON.stringify(new Date().toISOString()),
    },

    // 依赖优化
    optimizeDeps: {
      include: ['react', 'react-dom'],
      exclude: ['@testing-library/react'],
    },

    // CSS 配置
    css: {
      modules: {
        localsConvention: 'camelCase',
      },
    },
  };
});
