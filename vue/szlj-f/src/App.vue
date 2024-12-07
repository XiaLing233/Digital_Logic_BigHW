<template>
  <a-layout>
    <a-layout-header>
      <div class="logo" />
      <a-menu
        theme="light"
        mode="horizontal"
        :style="{ lineHeight: '64px' }"
      >
      <a-menu-item key="1">
        <LineChartOutlined />
        <router-link to="/table">数据显示</router-link>
      </a-menu-item>
      <a-menu-item key="2">
        <InfoCircleOutlined />
        <router-link to="/support">联系与支持</router-link>
      </a-menu-item>
      </a-menu>
    </a-layout-header>

    <a-layout-content>
      <router-view />
    </a-layout-content>

    <a-layout-footer>
      <p>数字逻辑大作业</p>
      <p>{{ new Date().getFullYear() }} — <strong>夏凌</strong></p>
    </a-layout-footer>

  </a-layout>
</template>