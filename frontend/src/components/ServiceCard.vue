<template>
  <div class="service-card p-4 border rounded-lg shadow hover:shadow-xl transition-shadow duration-300 bg-white dark:bg-gray-800 flex flex-col justify-between">
    <div>
      <div class="flex items-center mb-2">
        <div v-if="service.icon" class="mr-3 flex-shrink-0">
          <img :src="getIconUrl(service.icon)" :alt="service.name + ' icon'" class="w-8 h-8 object-contain">
        </div>
        <h3 class="text-xl font-semibold text-gray-800 dark:text-gray-200 truncate" :title="service.name">{{ service.name }}</h3>
      </div>
      <p class="text-xs text-gray-500 dark:text-gray-400 mb-1 italic break-all" v-if="service.category">Category: {{ service.category }}</p>
      <p class="text-sm text-gray-600 dark:text-gray-400 mb-3 break-all">
        <a :href="normalizedUrl(service.url)" target="_blank" rel="noopener noreferrer" class="text-blue-500 hover:text-blue-700 dark:hover:text-blue-400 hover:underline" :title="normalizedUrl(service.url)">
          {{ service.url }}
        </a>
      </p>
    </div>
    <div>
      <p class="text-sm font-medium">
        Status: <span :class="statusColor" class="font-bold">{{ statusText }}</span>
      </p>
      <p v-if="service.lastChecked" class="text-xs text-gray-400 dark:text-gray-500">
        Last checked: {{ formatTime(service.lastChecked) }}
      </p>
      <p v-if="service.status === 'down' && service.error" class="text-xs text-red-400 dark:text-red-500" :title="service.error">
        Error: {{ service.error }}
      </p>
       <p v-if="service.status === 'down' && service.statusCode" class="text-xs text-red-400 dark:text-red-500">
        Status Code: {{ service.statusCode }}
      </p>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ServiceCard',
  props: {
    service: {
      type: Object,
      required: true
    }
  },
  computed: {
    statusText() {
      if (!this.service.status) return 'Unknown';
      switch (this.service.status.toLowerCase()) {
        case 'up':
          return 'Up';
        case 'down':
          return 'Down';
        default:
          return this.service.status; // Or 'Unknown'
      }
    },
    statusColor() {
      if (!this.service.status) return 'text-gray-500 dark:text-gray-400';
      switch (this.service.status.toLowerCase()) {
        case 'up':
          return 'text-green-500 dark:text-green-400';
        case 'down':
          return 'text-red-500 dark:text-red-400';
        default:
          return 'text-yellow-500 dark:text-yellow-400'; // For other statuses like 'checking' or errors
      }
    }
  },
  methods: {
    getIconUrl(iconName) {
      // Assuming icons are in frontend/public/icons/
      return \`/icons/\${iconName}\`;
    },
    normalizedUrl(url) {
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return 'http://' + url;
      }
      return url;
    },
    formatTime(isoString) {
      if (!isoString) return 'N/A';
      try {
        return new Date(isoString).toLocaleTimeString();
      } catch (e) {
        return 'Invalid Date';
      }
    }
  }
};
</script>
