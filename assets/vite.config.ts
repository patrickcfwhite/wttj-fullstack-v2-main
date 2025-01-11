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
  test: {
    globals: true,
    environment: 'jsdom',
    teardownTimeout: 1000,
    setupFiles: './src/test/setup.ts',
    minWorkers: 1,
  },
})
