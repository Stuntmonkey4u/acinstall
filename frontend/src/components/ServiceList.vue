<template>
  <div class="service-list">
    <div class="mb-4 flex justify-between items-center">
      <h2 class="text-xl font-semibold text-gray-700 dark:text-gray-200">Services Overview</h2>
      <button @click="fetchServiceStatuses(true)" :disabled="isRefreshing"
              class="px-4 py-2 text-sm font-medium text-white bg-blue-600 rounded-md hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 dark:bg-blue-500 dark:hover:bg-blue-600 dark:focus:ring-offset-gray-800"
              :class="{ 'opacity-50 cursor-not-allowed': isRefreshing }">
        <svg v-if="isRefreshing" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        {{ isRefreshing ? 'Refreshing...' : 'Refresh Now' }}
      </button>
    </div>

    <div v-if="isLoading && Object.keys(groupedServices).length === 0" class="text-center py-10">
      <p class="text-lg text-gray-600 dark:text-gray-300">Loading services and their statuses...</p>
    </div>
    <div v-else-if="error" class="text-center py-10">
      <p class="text-lg text-red-500 dark:text-red-400">Error loading service statuses: {{ error.message }}</p>
      <p class="text-sm text-gray-500 dark:text-gray-400">Ensure the backend is running (port 3001) and accessible.</p>
    </div>
    <div v-else-if="Object.keys(groupedServices).length === 0 && !isLoading" class="text-center py-10">
      <p class="text-lg text-gray-600 dark:text-gray-300">No services configured yet.</p>
    </div>
    <div v-else>
      <div v-for="(servicesInCategory, category) in groupedServices" :key="category" class="mb-8">
        <h3 class="text-xl font-semibold mb-3 text-gray-700 dark:text-gray-300 capitalize sticky top-0 bg-gray-100 dark:bg-gray-900 py-2 z-10">
          {{ category === 'undefined' || category === '' || category === 'General' ? 'General' : category }}
        </h3>
        <div class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 gap-6">
          <ServiceCard v-for="service in servicesInCategory" :key="service.id" :service="service" />
        </div>
      </div>
    </div>
    <div v-if="lastUpdated" class="mt-4 text-xs text-gray-500 dark:text-gray-400 text-center">
      Last updated: {{ new Date(lastUpdated).toLocaleTimeString() }}
    </div>
  </div>
</template>

<script>
import axios from 'axios';
import ServiceCard from './ServiceCard.vue';

const REFRESH_INTERVAL = 30000; // 30 seconds

export default {
  name: 'ServiceList',
  components: {
    ServiceCard
  },
  data() {
    return {
      services: [], // Raw list from API
      isLoading: true,
      isRefreshing: false,
      error: null,
      refreshIntervalId: null,
      lastUpdated: null,
    };
  },
  computed: {
    groupedServices() {
      const groups = this.services.reduce((acc, service) => {
        let category = service.category || 'General'; // Default category
        if (category.trim() === '') category = 'General'; // Treat empty string as General

        if (!acc[category]) {
          acc[category] = [];
        }
        acc[category].push(service);
        return acc;
      }, {});

      // Sort categories by name (optional, but good for consistency)
      const sortedCategories = Object.keys(groups).sort((a, b) => {
        if (a === 'General') return -1; // Always put 'General' first or last
        if (b === 'General') return 1;
        return a.localeCompare(b);
      });

      const result = {};
      for (const category of sortedCategories) {
        // Sort services within each category by name
        result[category] = groups[category].sort((a,b) => a.name.localeCompare(b.name));
      }
      return result;
    }
  },
  async created() {
    await this.fetchServiceStatuses(false);
    this.refreshIntervalId = setInterval(() => this.fetchServiceStatuses(true), REFRESH_INTERVAL);
  },
  beforeUnmount() {
    if (this.refreshIntervalId) {
      clearInterval(this.refreshIntervalId);
    }
  },
  methods: {
    async fetchServiceStatuses(isRefresh = false) {
      if (isRefresh) {
        this.isRefreshing = true;
      } else {
        this.isLoading = true;
      }
      this.error = null;

      try {
        const response = await axios.get('http://localhost:3001/api/services/statuses');
        this.services = response.data; // Keep raw list, computed prop will group and sort
        this.lastUpdated = Date.now();
      } catch (err) {
        console.error('Failed to fetch service statuses:', err);
        this.error = err;
        if (err.response) {
          this.error.message = err.response.data.message || `Server error: ${err.response.status}`;
        } else if (err.request) {
          this.error.message = 'No response from server. Is it running?';
        } else {
          this.error.message = err.message;
        }
      } finally {
        this.isLoading = false;
        this.isRefreshing = false;
      }
    }
  }
};
</script>
<style scoped>
/* Make category headers sticky. Ensure parent has enough padding if App.vue has a fixed navbar */
.sticky {
  /* background-color inherits from dark/light mode via parent */
  /* Consider adding a slight box-shadow or border to sticky headers if they overlap content visually */
}
</style>
