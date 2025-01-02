import { createRouter, createWebHistory } from 'vue-router';
import Welcome from '../views/Welcome.vue';
import Table from '../views/Table.vue';
import Info from '../views/Info.vue';

const routes = [
  {
    path: '/',
    component: Welcome,
  },
  {
    path: '/table',
    component: Table,
  },
  {
    path: '/info',
    component: Info,
  }
];

const router = createRouter({
  history: createWebHistory(),
  routes,
});



export default router