<template>
  <a-layout>
    <a-layout-header>
      <div style="float: left;"><h1 style="color:#fff; display: inline-block; margin: 0"><ControlOutlined style="margin-right:8px; vertical-align: middle" />温湿度数据可视化</h1></div>
      <div style="float:inline-end; padding-top: 8px"><a href="https://github.com/XiaLing233/Digital_Logic_BigHW" target="_blank"><GithubFilled style="color:#fff; font-size: 40px;"/></a></div>
    </a-layout-header>
  <a-layout style="min-height: calc(100vh - 170px);">
    <a-layout-sider width="200" style="background: #fff">
      <a-menu
        :default-selected-keys="['/']"
        :selected-keys="[$route.path]"
        mode="inline"
        theme="light"
        @select="menuSelect"
      >
      <a-menu-item key="/">
        <HomeOutlined style="margin-right:8px" />欢迎
      </a-menu-item>
      <a-menu-item key="/table">
        <LineChartOutlined style="margin-right: 8px;" />数据显示
      </a-menu-item>
      <a-menu-item key="/info">
        <InfoCircleOutlined style="margin-right:8px" />本站说明
      </a-menu-item>
      </a-menu>
    </a-layout-sider>
    <a-layout>
      <a-layout-content>
        <router-view />
      </a-layout-content>
    </a-layout>
  </a-layout>
  <a-layout-footer class="footer" style="text-align:center">
        <p>数字逻辑大作业</p>
        <p>{{ new Date().getFullYear() }} — <strong>夏凌</strong></p>
  </a-layout-footer>
</a-layout>
</template>

<script>
  import { HomeOutlined, LineChartOutlined, GithubFilled, InfoCircleOutlined, ControlOutlined} from '@ant-design/icons-vue';

  export default {
    components: {
      HomeOutlined,
      LineChartOutlined,
      GithubFilled,
      InfoCircleOutlined,
      ControlOutlined
    },

    data() {
      return {
        current: this.$route.path,
      };
    },
    methods: {
      menuSelect({ key }) {
        this.$router.push(key);
      },
    },
  };

</script>

<style scoped>
.footer {
  text-align: center;
}

.footer p {
  margin: 2px 2px 0 0;
}
</style>