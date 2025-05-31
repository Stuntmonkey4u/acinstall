import { createRouter, createWebHistory } from 'vue-router';
import HomeView from '../views/HomeView.vue';
import LoginView from '../views/LoginView.vue';
import AdminView from '../views/AdminView.vue';
import auth from '@/store/auth'; // Import auth store

const routes = [
  {
    path: '/',
    name: 'home',
    component: HomeView
  },
  {
    path: '/login',
    name: 'login',
    component: LoginView,
    meta: { requiresGuest: true } // Prevent logged-in users from seeing login page
  },
  {
    path: '/admin',
    name: 'admin',
    component: AdminView,
    meta: { requiresAuth: true, requiresAdmin: true } // Protected route
  }
  // Example lazy-loaded route for About page:
  // {
  //   path: '/about',
  //   name: 'about',
  //   component: () => import(/* webpackChunkName: "about" */ '../views/AboutView.vue')
  // }
];

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL || '/'), // Vite uses import.meta.env.BASE_URL
  routes
});

router.beforeEach(async (to, from, next) => {
  // Ensure auth state is checked before navigation, especially on first load
  // The store now checks auth on init, but this is an extra safeguard or for complex scenarios.
  // If auth.state.loading is true from the initial checkAuthStatus, we might want to wait.
  // However, for simplicity, we'll rely on the store's initial check.

  const isLoggedIn = auth.state.isLoggedIn;
  const isAdmin = auth.state.user?.isAdmin;

  if (to.meta.requiresAuth && !isLoggedIn) {
    // Needs auth, but user is not logged in
    next({ name: 'login', query: { redirect: to.fullPath } }); // Redirect to login, save original destination
  } else if (to.meta.requiresGuest && isLoggedIn) {
    // Guest page (like login), but user is logged in
    next({ name: 'home' }); // Redirect to home or dashboard
  } else if (to.meta.requiresAdmin && !isAdmin) {
    // Needs admin rights, but user is not admin (or not logged in)
    if (!isLoggedIn) {
        next({ name: 'login', query: { redirect: to.fullPath } });
    } else {
        // Logged in but not admin - show an "access denied" page or redirect to home
        // For now, redirect to home. A dedicated "Access Denied" view would be better.
        console.warn('Access denied: User is not an admin.');
        next({ name: 'home' });
    }
  }
  else {
    // All good
    next();
  }
});

export default router;
