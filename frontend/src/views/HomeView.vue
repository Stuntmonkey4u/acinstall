<template>
  <div class="home-view">
    <h1 class="text-2xl font-bold mb-4">My Services</h1>
    <ServiceList />
  </div>
</template>

<script>
import ServiceList from '@/components/ServiceList.vue';

export default {
  name: 'HomeView',
  components: {
    ServiceList
  }
};
</script>
