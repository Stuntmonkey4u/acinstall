<template>
  <div class="admin-view p-4 md:p-6">
    <h1 class="text-2xl md:text-3xl font-bold mb-6 text-gray-800 dark:text-gray-200">Manage Services</h1>

    <!-- Global Message Area -->
    <div v-if="globalMessage" :class="globalMessageClass" class="mb-4 p-3 rounded-md text-sm">
      {{ globalMessage }}
    </div>

    <!-- Add/Edit Service Form Section -->
    <div class="mb-8">
      <button @click="showAddForm" v-if="!showForm"
              class="px-4 py-2 bg-green-600 hover:bg-green-700 text-white font-semibold rounded-md shadow-sm focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-green-500 dark:focus:ring-offset-gray-800">
        Add New Service
      </button>
      <div v-if="showForm" class="mt-4 p-4 border border-gray-200 dark:border-gray-700 rounded-lg bg-white dark:bg-gray-800 shadow-lg">
        <h2 class="text-xl font-semibold mb-3 text-gray-700 dark:text-gray-300">{{ formTitle }}</h2>
        <ServiceForm :service="serviceToEdit" :loading="formLoading" :error="formError" :submit-button-text-prop="formSubmitButtonText"
                     @submit="handleFormSubmit" @cancel="hideForm" />
      </div>
    </div>

    <!-- Services List/Table -->
    <div class="bg-white dark:bg-gray-800 shadow-lg rounded-lg overflow-hidden">
      <h2 class="text-xl font-semibold p-4 text-gray-700 dark:text-gray-300 border-b border-gray-200 dark:border-gray-700">
        Configured Services ({{ services.length }})
        <button @click="fetchServices(true)" :disabled="listLoading" title="Refresh Services List"
              class="ml-4 px-2 py-1 text-xs font-medium text-indigo-600 dark:text-indigo-400 hover:text-indigo-800 dark:hover:text-indigo-300 rounded border border-indigo-300 dark:border-indigo-600 hover:bg-indigo-50 dark:hover:bg-indigo-700 focus:outline-none">
           <svg v-if="listLoading" class="animate-spin h-3 w-3 text-indigo-500 inline" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
            <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
            <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
          </svg>
          {{ listLoading ? '...' : 'Refresh' }}
        </button>
      </h2>
       <div v-if="listLoading && services.length === 0" class="p-4 text-center text-gray-500 dark:text-gray-400">Loading services...</div>
       <div v-else-if="listError" class="p-4 text-center text-red-500 dark:text-red-400">Error loading services: {{ listError }}</div>
       <div v-else-if="services.length === 0 && !listLoading" class="p-4 text-center text-gray-500 dark:text-gray-400">No services found. Add one!</div>
      <div v-else class="overflow-x-auto">
        <table class="min-w-full divide-y divide-gray-200 dark:divide-gray-700">
          <thead class="bg-gray-50 dark:bg-gray-700">
            <tr>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Name</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">URL</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Category</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Icon</th>
              <th scope="col" class="px-4 py-3 text-left text-xs font-medium text-gray-500 dark:text-gray-300 uppercase tracking-wider">Actions</th>
            </tr>
          </thead>
          <tbody class="bg-white dark:bg-gray-800 divide-y divide-gray-200 dark:divide-gray-700">
            <tr v-for="service in services" :key="service.id" class="hover:bg-gray-50 dark:hover:bg-gray-700/50">
              <td class="px-4 py-3 whitespace-nowrap text-sm font-medium text-gray-900 dark:text-gray-100">{{ service.name }}</td>
              <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300 truncate max-w-xs" :title="service.url"><a :href="service.url" target="_blank" class="hover:underline">{{ service.url }}</a></td>
              <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">{{ service.category || '-' }}</td>
              <td class="px-4 py-3 whitespace-nowrap text-sm text-gray-500 dark:text-gray-300">{{ service.icon || '-' }}</td>
              <td class="px-4 py-3 whitespace-nowrap text-sm font-medium space-x-2">
                <button @click="showEditForm(service)" class="text-indigo-600 hover:text-indigo-900 dark:text-indigo-400 dark:hover:text-indigo-300">Edit</button>
                <button @click="confirmDeleteService(service)" class="text-red-600 hover:text-red-900 dark:text-red-400 dark:hover:text-red-300">Delete</button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, onMounted, computed } from 'vue';
import axios from 'axios'; // Import axios directly
import ServiceForm from '@/components/ServiceForm.vue';

export default {
  name: 'AdminView',
  components: {
    ServiceForm
  },
  setup() {
    const services = ref([]);
    const listLoading = ref(false);
    const listError = ref(null);

    const showForm = ref(false);
    const serviceToEdit = ref(null); // null for Add, service object for Edit
    const formLoading = ref(false);
    const formError = ref(null);

    const globalMessage = ref('');
    const globalMessageType = ref('success'); // 'success' or 'error'

    // Create an Axios instance for admin actions, ensuring credentials are sent
    const adminApiClient = axios.create({
        baseURL: 'http://localhost:3001/api', // Backend API base URL
        withCredentials: true // Important for sessions/cookies
    });


    const fetchServices = async (isRefresh = false) => {
      listLoading.value = true;
      listError.value = null;
      if(!isRefresh) services.value = []; // Clear on initial load only
      try {
        // Use /api/services as status is not strictly needed for admin list, simpler data
        const response = await adminApiClient.get('/services');
        services.value = response.data.sort((a, b) => a.name.localeCompare(b.name));
      } catch (err) {
        console.error('Failed to fetch services for admin:', err);
        listError.value = err.response?.data?.message || err.message || 'Could not load services.';
      } finally {
        listLoading.value = false;
      }
    };

    const formTitle = computed(() => serviceToEdit.value ? 'Edit Service' : 'Add New Service');
    const formSubmitButtonText = computed(() => serviceToEdit.value ? 'Update Service' : 'Add Service');


    const showAddForm = () => {
      serviceToEdit.value = null; // Clear any existing edit data
      formError.value = null;
      showForm.value = true;
    };

    const showEditForm = (service) => {
      serviceToEdit.value = { ...service }; // Clone to avoid mutating original list item directly
      formError.value = null;
      showForm.value = true;
    };

    const hideForm = () => {
      showForm.value = false;
      serviceToEdit.value = null;
      formError.value = null;
    };

    const setGlobalMessage = (message, type = 'success', duration = 4000) => {
        globalMessage.value = message;
        globalMessageType.value = type;
        if (duration) {
            setTimeout(() => globalMessage.value = '', duration);
        }
    };

    const globalMessageClass = computed(() => ({
        'bg-green-100 dark:bg-green-700 border border-green-400 dark:border-green-600 text-green-700 dark:text-green-200': globalMessageType.value === 'success',
        'bg-red-100 dark:bg-red-700 border border-red-400 dark:border-red-600 text-red-700 dark:text-red-200': globalMessageType.value === 'error',
    }));

    const handleFormSubmit = async (serviceData) => {
      formLoading.value = true;
      formError.value = null;
      try {
        if (serviceToEdit.value && serviceToEdit.value.id) {
          // Update existing service
          const response = await adminApiClient.put(\`/services/\${serviceToEdit.value.id}\`, serviceData);
          setGlobalMessage(\`Service '\${response.data.name}' updated successfully!\`, 'success');
        } else {
          // Add new service
          const response = await adminApiClient.post('/services', serviceData);
          setGlobalMessage(\`Service '\${response.data.name}' added successfully!\`, 'success');
        }
        hideForm();
        await fetchServices(true); // Refresh list
      } catch (err) {
        console.error('Failed to save service:', err);
        formError.value = err.response?.data?.message || err.message || 'Failed to save service.';
        setGlobalMessage(formError.value, 'error', 6000); // Show error in global message too if form is hidden
      } finally {
        formLoading.value = false;
      }
    };

    const confirmDeleteService = async (service) => {
      if (window.confirm(\`Are you sure you want to delete the service "\${service.name}"?\`)) {
        listLoading.value = true; // Use listLoading as it affects the table area
        try {
          await adminApiClient.delete(\`/services/\${service.id}\`);
          setGlobalMessage(\`Service '\${service.name}' deleted successfully.\`, 'success');
          await fetchServices(true); // Refresh list
        } catch (err) {
          console.error('Failed to delete service:', err);
          const errorMsg = err.response?.data?.message || err.message || 'Failed to delete service.';
          setGlobalMessage(errorMsg, 'error');
          listError.value = errorMsg; // Also show in list error area if appropriate
        } finally {
          listLoading.value = false;
        }
      }
    };

    onMounted(async () => {
      await fetchServices();
    });

    return {
      services,
      listLoading,
      listError,
      fetchServices,
      showForm,
      serviceToEdit,
      formLoading,
      formError,
      formTitle,
      formSubmitButtonText,
      showAddForm,
      showEditForm,
      hideForm,
      handleFormSubmit,
      confirmDeleteService,
      globalMessage,
      globalMessageClass
    };
  }
};
</script>
