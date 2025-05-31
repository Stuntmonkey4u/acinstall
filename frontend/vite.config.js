import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
// import path from 'path' // path is not strictly needed for the new URL method - This comment is fine
import { fileURLToPath, URL } from 'node:url' // Import for ESM path resolution

// https://vite.dev/config/ - This comment is fine
// import path from 'path' // path is not strictly needed for the new URL method
import { fileURLToPath, URL } from 'node:url' // Import for ESM path resolution
import path from 'path'
import tailwindcssVite from '@tailwindcss/vite' // Import the plugin

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    vue()
  ],
  resolve: {
    alias: {
      '@': fileURLToPath(new URL('./src', import.meta.url))
    }
  }
      // Alternative using path.resolve if preferred (would need path import):
      // '@': path.resolve(path.dirname(fileURLToPath(import.meta.url)), './src'),
    vue(),
    tailwindcssVite() // Add the plugin here
  ],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
