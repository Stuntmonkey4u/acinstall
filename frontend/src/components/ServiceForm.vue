<template>
  <form @submit.prevent="handleSubmit" class="space-y-4 p-4 bg-gray-50 dark:bg-gray-700 rounded-lg shadow">
    <div>
      <label for="serviceName" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Service Name</label>
      <input type="text" v-model="editableService.name" id="serviceName" required
             class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm dark:bg-gray-600 dark:text-white dark:placeholder-gray-400">
    </div>
    <div>
      <label for="serviceUrl" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Service URL</label>
      <input type="url" v-model="editableService.url" id="serviceUrl" required placeholder="e.g., http://localhost:8080 or mynas.local"
             class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm dark:bg-gray-600 dark:text-white dark:placeholder-gray-400">
    </div>
    <div>
      <label for="serviceCategory" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Category</label>
      <input type="text" v-model="editableService.category" id="serviceCategory" placeholder="e.g., Media, Network, Utilities"
             class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm dark:bg-gray-600 dark:text-white dark:placeholder-gray-400">
    </div>
    <div>
      <label for="serviceIcon" class="block text-sm font-medium text-gray-700 dark:text-gray-300">Icon Filename</label>
      <input type="text" v-model="editableService.icon" id="serviceIcon" placeholder="e.g., sonarr.png (place in public/icons)"
             pattern="[\w\-\_\.]+\.(png|jpe?g|svg|gif|webp|ico)" title="Must be a valid filename ending in .png, .jpg, .svg, .gif, .webp, or .ico"
             class="mt-1 block w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm dark:bg-gray-600 dark:text-white dark:placeholder-gray-400">
      <p class="mt-1 text-xs text-gray-500 dark:text-gray-400">Place icon files in the 'frontend/public/icons/' directory.</p>
    </div>
    <div class="flex justify-end space-x-3">
      <button type="button" @click="handleCancel"
              class="px-4 py-2 text-sm font-medium text-gray-700 dark:text-gray-200 bg-white dark:bg-gray-600 border border-gray-300 dark:border-gray-500 rounded-md shadow-sm hover:bg-gray-50 dark:hover:bg-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500">
        Cancel
      </button>
      <button type="submit" :disabled="loading"
              class="px-4 py-2 text-sm font-medium text-white bg-indigo-600 hover:bg-indigo-700 border border-transparent rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 flex items-center"
              :class="{ 'opacity-50 cursor-not-allowed': loading }">
        <svg v-if="loading" class="animate-spin -ml-1 mr-2 h-4 w-4 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
          <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
          <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
        </svg>
        {{ submitButtonText }}
      </button>
    </div>
    <p v-if="error" class="text-sm text-red-600 dark:text-red-400">{{ error }}</p>
  </form>
</template>

<script>
import { ref, watch, computed } from 'vue';

export default {
  name: 'ServiceForm',
  props: {
    service: { // For editing existing service
      type: Object,
      default: null
    },
    loading: Boolean,
    error: String,
    submitButtonTextProp: {
        type: String,
        default: 'Save Service'
    }
  },
  emits: ['submit', 'cancel'],
  setup(props, { emit }) {
    const defaultService = { name: '', url: '', category: '', icon: '' };
    const editableService = ref({ ...defaultService });

    watch(() => props.service, (newVal) => {
      if (newVal) {
        editableService.value = { ...newVal };
      } else {
        editableService.value = { ...defaultService };
      }
    }, { immediate: true, deep: true });

    const submitButtonText = computed(() => props.submitButtonTextProp || (props.service ? 'Update Service' : 'Add Service'));


    const handleSubmit = () => {
      // Basic validation
      if (!editableService.value.name || !editableService.value.url) {
        alert('Service Name and URL are required.');
        return;
      }
      emit('submit', { ...editableService.value });
    };

    const handleCancel = () => {
      emit('cancel');
    };

    return {
      editableService,
      handleSubmit,
      handleCancel,
      submitButtonText
    };
  }
};
</script>
