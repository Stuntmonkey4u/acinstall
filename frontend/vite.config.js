import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import { fileURLToPath, URL } from 'node:url'
import tailwindcssVite from '@tailwindcss/vite' // <-- IMPORT THE PLUGIN

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue(),
    tailwindcssVite() // <-- USE THE PLUGIN HERE
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
})
