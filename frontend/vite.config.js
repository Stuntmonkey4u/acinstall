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
import path from 'path' // Ensure path is imported

// https://vite.dev/config/
export default defineConfig({
  plugins: [vue()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  // If server options were previously defined, they'd need to be preserved.
  // For this project, the server options are not explicitly set in vite.config.js,
  // as CORS is handled by the backend and frontend is served via Nginx in Docker.
})
