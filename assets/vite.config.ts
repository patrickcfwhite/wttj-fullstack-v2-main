/// <reference types="vitest" />
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

const assetsUrl = process.env.ASSETS_URL || 'http://localhost:5173'

export default defineConfig({
  base: assetsUrl + '/',
  plugins: [react()],
  server: {
    origin: assetsUrl,
  },
  build: {
    outDir: '../priv/static/assets', // Specify Phoenix static directory
    emptyOutDir: true, // Ensure old files are cleaned
    rollupOptions: {
      input: './index.html', // Entry point for Vite
      output: {
        entryFileNames: 'index.js', // Fixed filename
        chunkFileNames: '[name].js',
        assetFileNames: '[name].[ext]',
      },
    },
  },
  test: {
    globals: true,
    environment: 'jsdom',
    teardownTimeout: 1000,
    setupFiles: './src/test/setup.ts',
    minWorkers: 1,
  },
})
