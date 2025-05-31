<template>
  <div class="login-view max-w-md mx-auto mt-10 p-6 bg-white dark:bg-gray-800 shadow-xl rounded-lg">
    <h1 class="text-3xl font-bold text-center mb-6 text-gray-800 dark:text-gray-200">Admin Login</h1>
    <form @submit.prevent="handleLogin">
      <div class="mb-4">
        <label class="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2" for="username">
          Username
        </label>
        <input v-model="username"
               class="shadow-sm appearance-none border rounded w-full py-3 px-4 text-gray-700 dark:text-gray-200 bg-gray-50 dark:bg-gray-700 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:placeholder-gray-400"
               id="username" type="text" placeholder="admin" required>
      </div>
      <div class="mb-6">
        <label class="block text-gray-700 dark:text-gray-300 text-sm font-bold mb-2" for="password">
          Password
        </label>
        <input v-model="password"
               class="shadow-sm appearance-none border rounded w-full py-3 px-4 text-gray-700 dark:text-gray-200 bg-gray-50 dark:bg-gray-700 mb-3 leading-tight focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent dark:placeholder-gray-400"
               id="password" type="password" placeholder="******************" required>
      </div>
      <div v-if="auth.state.error" class="mb-4 p-3 bg-red-100 dark:bg-red-700 border border-red-400 dark:border-red-600 text-red-700 dark:text-red-200 rounded">
        {{ auth.state.error }}
      </div>
      <div class="flex items-center justify-between">
        <button :disabled="auth.state.loading"
                class="w-full bg-blue-600 hover:bg-blue-700 text-white font-bold py-3 px-4 rounded focus:outline-none focus:shadow-outline transition duration-150 ease-in-out flex items-center justify-center"
                :class="{ 'opacity-50 cursor-not-allowed': auth.state.loading }"
                type="submit">
          <svg v-if="auth.state.loading" class="animate-spin -ml-1 mr-3 h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          {{ auth.state.loading ? 'Signing In...' : 'Sign In' }}
        </button>
      </div>
    </form>
  </div>
</template>

<script>
import { ref } from 'vue';
import auth from '@/store/auth'; // Import the auth store

export default {
  name: 'LoginView',
  setup() {
    const username = ref('');
    const password = ref('');

    const handleLogin = async () => {
      await auth.login(username.value, password.value);
    };

    return {
      username,
      password,
      handleLogin,
      auth // Expose auth store to template
    };
  }
};
</script>
