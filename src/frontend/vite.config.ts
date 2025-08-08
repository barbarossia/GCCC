import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import { resolve } from 'path';

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
      target: 'es2015',
      outDir: 'dist',
      sourcemap: mode === 'development',
      minify: mode === 'production' ? 'terser' : false,
      
      // 生产环境优化
      terserOptions: mode === 'production' ? {
        compress: {
          drop_console: true,
          drop_debugger: true,
        },
      } : {},
      
      // 代码分割
      rollupOptions: {
        input: {
          main: resolve(__dirname, 'index.html'),
        },
        output: {
          manualChunks: {
            vendor: ['react', 'react-dom'],
            utils: ['./utils/authService', './utils/mockData'],
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
        '@': resolve(__dirname, './'),
        '@components': resolve(__dirname, './components'),
        '@utils': resolve(__dirname, './utils'),
        '@types': resolve(__dirname, './types'),
        '@contexts': resolve(__dirname, './contexts'),
      },
    },
    
    // 环境变量
    define: {
      __APP_VERSION__: JSON.stringify(process.env.npm_package_version),
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
      preprocessorOptions: {
        scss: {
          additionalData: '@import "@/styles/variables.scss";',
        },
      },
    },
    
    // 测试配置
    test: {
      globals: true,
      environment: 'jsdom',
      setupFiles: ['./tests/setup.ts'],
      css: true,
      coverage: {
        provider: 'v8',
        reporter: ['text', 'json', 'html'],
        exclude: [
          'node_modules/',
          'tests/',
          '**/*.d.ts',
          'vite.config.ts',
        ],
        thresholds: {
          global: {
            branches: 75,
            functions: 80,
            lines: 80,
            statements: 80,
          },
        },
      },
    },
  };
});
