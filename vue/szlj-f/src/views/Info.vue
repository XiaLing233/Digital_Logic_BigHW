<template>
    <div class="markdown">
        <h1>本站说明</h1>
        <a-divider></a-divider>
        <p>本网站是24251学期数字逻辑大作业的数据展示部分，用来展示开发板收集到的、并上传到服务器的历史温湿度数据。很喜欢网络和网站设计，虽然同时也被折磨吧。。所以大作业选择了这个主题。</p>
        <p>网站的前端使用了<code>Vue3</code>，UI是<code>ant-design-vue</code>，后端使用<code>Flask</code>，数据库使用<code>MySQL</code>。基本上是吃计科导大作业的老本，不过也学到了一些新东西。但感觉，进步的空间还很大。寒假的时候可能会再花心思学一学<code>JavaScript</code>吧？这样就不至于代码全靠AI来辅助完成了。。</p>
        <p>关于数字逻辑开发板的设计，参见顶部导航栏右上方中<code>Github</code>的内容（如果哪天我开放了的话）。有什么碎碎念，后续再补充吧，估计也没人看2333。</p>
    </div>
</template>

<script>
export default {
    name: 'Info',
}
</script>

<style scoped>
    .markdown {
        padding: 20px;
        background-color: #fff;
        height: 100%;
    }
    .markdown h1 {
        text-align: center;
        font-size: 24px;
        font-weight: bold;
    }
    .markdown p {
        text-align: center;
        font-size: 18px;
    }
    .markdown code {
        background-color: #f0f0f0;
        padding: 2px;
        border-radius: 4px;
        font-family: consolas;
    }
</style>