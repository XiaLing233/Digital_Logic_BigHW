<script>

</script>

<template>
    <div class="welcome-container">
        <div id = "welcome">
        <a-card id="wel-box">
            <h1>欢迎查询温湿度历史信息！ :bordered="flase"</h1>
            <p>请点击右上方导航栏进行操作</p>
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
        /* background-image: url('../assets/welcome_bg.png'); */
        background-size: cover;
        background-position: center;
        height: calc(100vh - 140px);
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