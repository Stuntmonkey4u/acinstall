import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import path from 'path'
import tailwindcssVite from '@tailwindcss/vite' // Import the plugin

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    tailwindcssVite() // Add the plugin here
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
