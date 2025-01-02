<script>
    export default {
        name: 'Welcome',
    }
</script>

<template>
    <div class="welcome-container">
        <div id = "welcome">
        <a-card id="wel-box">
            <p>欢迎查询温湿度历史信息！</p>
            <p>请操作左侧导航栏</p>
        </a-card>
    </div>
    </div>
</template>

<style scoped>
    #welcome h1 {
        text-align: center;
    }

    #welcome p {
        text-align: center;
        font-size: 25px;
    }

    .welcome-container {
        background-image: url('../assets/welcome_bg_2.webp');
        background-size: cover;
        background-position: center;
        height: calc(100vh - 160px);
        width: 100%;
    }

    #wel-box {
        float: right; 
        margin-top: 5%;
        margin-right: 8%;
        background-color: rgba(0, 0, 0, 0.4); 
        backdrop-filter: blur(20px);
        border-radius: 4px;
        box-shadow: 0 4px 36px 0 #0d5ead1a;
        padding: 24px;
        position:relative;
        color: white;
        border: 0px;
    }

</style>