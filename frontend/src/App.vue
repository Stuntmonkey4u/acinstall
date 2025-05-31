<template>
  <div id="app" class="min-h-screen bg-gray-100 dark:bg-gray-900 text-gray-900 dark:text-gray-100">
    <header class="bg-white dark:bg-gray-800 shadow-md">
      <nav class="container mx-auto px-6 py-3 flex justify-between items-center">
        <div>
          <router-link to="/" class="text-lg font-semibold text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400 mr-4">
            HomeDash
          </router-link>
          <router-link v-if="auth.state.isLoggedIn && auth.state.user?.isAdmin" to="/admin"
                       class="text-gray-700 dark:text-gray-200 hover:text-blue-600 dark:hover:text-blue-400 mr-4">
            Admin
          </router-link>
        </div>
        <div class="flex items-center">
          <button @click="toggleDarkMode" class="mr-4 p-2 rounded-full hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none">
            <svg v-if="isDarkMode" xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-yellow-400" viewBox="0 0 20 20" fill="currentColor">
              <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z" />
            </svg>
            <svg v-else xmlns="http://www.w3.org/2000/svg" class="h-5 w-5 text-gray-600" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 15.657a1 1 0 00-1.414-1.414l-.707.707a1 1 0 001.414 1.414l.707-.707zm1.414-12.021a1 1 0 011.414 0l.707.707a1 1 0 11-1.414 1.414L6.464 5.05A1 1 0 015.05 3.636zM3 11a1 1 0 100-2H2a1 1 0 100 2h1z" clip-rule="evenodd" />
            </svg>
          </button>
          <div v-if="auth.state.isLoggedIn && auth.state.user" class="flex items-center">
            <span class="text-gray-700 dark:text-gray-300 mr-3 text-sm">Welcome, {{ auth.state.user.username }}!</span>
            <button @click="handleLogout"
                    class="bg-red-500 hover:bg-red-700 dark:bg-red-600 dark:hover:bg-red-700 text-white text-sm font-medium py-2 px-3 rounded-md focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 dark:focus:ring-offset-gray-800">
              Logout
            </button>
          </div>
          <router-link v-else to="/login"
                       class="bg-blue-600 hover:bg-blue-700 text-white text-sm font-medium py-2 px-3 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:focus:ring-offset-gray-800">
            Login
          </router-link>
        </div>
      </nav>
    </header>
    <main class="container mx-auto p-4">
      <router-view />
    </main>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue';
import auth from '@/store/auth'; // Import the auth store

export default {
  name: 'App',
  setup() {
    const isDarkMode = ref(false);

    const toggleDarkMode = () => {
      isDarkMode.value = !isDarkMode.value;
      if (isDarkMode.value) {
        document.documentElement.classList.add('dark');
        localStorage.setItem('theme', 'dark');
      } else {
        document.documentElement.classList.remove('dark');
        localStorage.setItem('theme', 'light');
      }
    };

    const handleLogout = async () => {
      await auth.logout();
    };

    onMounted(() => {
      // Apply saved theme on load
      const savedTheme = localStorage.getItem('theme');
      if (savedTheme === 'dark' || (!savedTheme && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
        isDarkMode.value = true;
        document.documentElement.classList.add('dark');
      } else {
        isDarkMode.value = false;
        document.documentElement.classList.remove('dark');
      }
      // Initial auth status check is done in auth.js
    });

    return {
      auth, // Expose auth store to template
      handleLogout,
      isDarkMode,
      toggleDarkMode
    };
  }
};
</script>

<style>
/* Ensure router-link-exact-active has good visibility if needed */
.router-link-exact-active {
  /* Example: color: #3b82f6; dark:color: #60a5fa; */
}
</style>
