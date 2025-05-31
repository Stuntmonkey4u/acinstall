import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
// import path from 'path' // path is not strictly needed for the new URL method
import { fileURLToPath, URL } from 'node:url' // Import for ESM path resolution

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
      // Alternative using path.resolve if preferred (would need path import):
      // '@': path.resolve(path.dirname(fileURLToPath(import.meta.url)), './src'),
    },
  },
})
