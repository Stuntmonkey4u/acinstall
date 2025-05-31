import { reactive, readonly } from 'vue';
import axios from 'axios';
import router from '../router'; // Import router for navigation

// Axios instance that ensures credentials are sent
const apiClient = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL,
  withCredentials: true // Important for sessions/cookies
});

const state = reactive({
  isLoggedIn: false,
  user: null,
  error: null,
  loading: false,
});

async function checkAuthStatus() {
  state.loading = true;
  state.error = null;
  try {
    const response = await apiClient.get('/auth/status');
    if (response.data.isLoggedIn) {
      state.isLoggedIn = true;
      state.user = response.data.user;
    } else {
      state.isLoggedIn = false;
      state.user = null;
    }
  } catch (err) {
    console.error('Auth status check failed:', err);
    state.isLoggedIn = false;
    state.user = null;
    // Don't set global error for initial check failure, could be normal
  } finally {
    state.loading = false;
  }
}

async function login(username, password) {
  state.loading = true;
  state.error = null;
  try {
    const response = await apiClient.post('/auth/login', { username, password });
    state.isLoggedIn = true;
    state.user = response.data.user;
    state.error = null;
    await router.push(state.user && state.user.isAdmin ? '/admin' : '/'); // Redirect to admin or home
    return true;
  } catch (err) {
    console.error('Login failed:', err);
    state.isLoggedIn = false;
    state.user = null;
    state.error = err.response?.data?.message || 'Login failed. Please try again.';
    return false;
  } finally {
    state.loading = false;
  }
}

async function logout() {
  state.loading = true;
  state.error = null;
  try {
    await apiClient.post('/auth/logout');
    state.isLoggedIn = false;
    state.user = null;
    await router.push('/'); // Redirect to home
  } catch (err) {
    console.error('Logout failed:', err);
    // state.error = err.response?.data?.message || 'Logout failed.';
    // Best effort logout: clear state even if server call fails
    state.isLoggedIn = false;
    state.user = null;
    await router.push('/'); // Still redirect
  } finally {
    state.loading = false;
  }
}

// Call checkAuthStatus on store initialization (e.g. when app loads)
// This is important to re-establish session if user refreshes the page
checkAuthStatus();

export default {
  state: readonly(state), // Expose state as readonly to prevent direct mutation
  login,
  logout,
  checkAuthStatus // Expose this if manual re-check is needed
};
