import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  
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
        '../test/',
        '**/*.d.ts',
        '**/*.config.ts',
        '**/coverage/**',
      ],
      
      // 覆盖率目标
      thresholds: {
        global: {
          branches: 75,
          functions: 80,
          lines: 80,
          statements: 80,
        },
      },
    },
    
    // 测试文件匹配规则
    include: [
      './**/*.{test,spec}.{js,ts,tsx}',
    ],
    
    // 排除文件
    exclude: [
      'node_modules',
      '../test/frontend/node_modules',
      'dist',
      'coverage',
      '**/*.config.*',
      '../test/**/node_modules/**',
    ],
  },
});
