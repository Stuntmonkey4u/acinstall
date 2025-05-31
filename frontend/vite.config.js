import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
// import path from 'path' // path is not strictly needed for the new URL method - This comment is fine
import { fileURLToPath, URL } from 'node:url' // Import for ESM path resolution

// https://vite.dev/config/ - This comment is fine
export default defineConfig({
  plugins: [
    vue()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
})
