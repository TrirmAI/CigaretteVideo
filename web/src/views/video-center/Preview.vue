<template>
  <div class="app-container video-container">
    <div class="toolbar">
      <el-radio-group v-model="layout" size="small" fill="#006838">
        <el-radio-button label="1"><i class="el-icon-menu"></i> 单屏</el-radio-button>
        <el-radio-button label="4"><i class="el-icon-s-grid"></i> 四分屏</el-radio-button>
        <el-radio-button label="9"><i class="el-icon-s-grid"></i> 九分屏</el-radio-button>
        <el-radio-button label="16"><i class="el-icon-s-grid"></i> 十六分屏</el-radio-button>
      </el-radio-group>
      <div class="right-tools">
        <el-button size="small" type="danger" icon="el-icon-video-camera">全部录像</el-button>
        <el-button size="small" type="warning" icon="el-icon-close">全部关闭</el-button>
      </div>
    </div>

    <div class="video-grid" :class="'layout-' + layout">
      <div v-for="i in parseInt(layout)" :key="i" class="video-cell" :class="{active: activeIndex === i}" @click="activeIndex = i">
        <div class="video-content">
          <!-- Placeholder for actual player -->
          <div class="placeholder-content">
            <i class="el-icon-video-play" style="font-size: 48px; margin-bottom: 10px; opacity: 0.5;"></i>
            <div>通道 {{ i }}</div>
            <div class="status-text">无信号</div>
          </div>
        </div>
        <div class="cell-tools">
          <i class="el-icon-camera" title="截图"></i>
          <i class="el-icon-video-camera" title="录像"></i>
          <i class="el-icon-microphone" title="对讲"></i>
          <i class="el-icon-full-screen" title="全屏"></i>
        </div>
      </div>
    </div>
    
    <div class="ptz-control">
      <el-card class="box-card" :body-style="{ padding: '10px' }">
         <div slot="header" class="clearfix" style="padding: 5px 0;">
            <span><i class="el-icon-aim"></i> 云台控制</span>
          </div>
          <el-row :gutter="10" style="text-align: center;">
            <el-col :span="8"><el-button icon="el-icon-top-left" size="mini" circle></el-button></el-col>
            <el-col :span="8"><el-button icon="el-icon-top" size="mini" circle></el-button></el-col>
            <el-col :span="8"><el-button icon="el-icon-top-right" size="mini" circle></el-button></el-col>
          </el-row>
          <el-row :gutter="10" style="text-align: center; margin-top: 5px;">
            <el-col :span="8"><el-button icon="el-icon-back" size="mini" circle></el-button></el-col>
            <el-col :span="8"><el-button icon="el-icon-rank" size="mini" circle></el-button></el-col>
            <el-col :span="8"><el-button icon="el-icon-right" size="mini" circle></el-button></el-col>
          </el-row>
          <el-row :gutter="10" style="text-align: center; margin-top: 5px;">
            <el-col :span="8"><el-button icon="el-icon-bottom-left" size="mini" circle></el-button></el-col>
            <el-col :span="8"><el-button icon="el-icon-bottom" size="mini" circle></el-button></el-col>
            <el-col :span="8"><el-button icon="el-icon-bottom-right" size="mini" circle></el-button></el-col>
          </el-row>
          <div style="margin-top: 10px; border-top: 1px solid #eee; padding-top: 10px;">
             <el-slider v-model="zoom" :min="1" :max="10" style="width: 90%; margin: 0 auto;"></el-slider>
             <div style="text-align: center; font-size: 12px; color: #909399;">变倍</div>
          </div>
      </el-card>
    </div>
  </div>
</template>

<script>
export default {
  data() {
    return {
      layout: '4',
      activeIndex: 1,
      zoom: 1
    }
  }
}
</script>

<style scoped lang="scss">
.video-container {
  display: flex;
  flex-direction: column;
  height: calc(100vh - 84px);
  background-color: #000;
  padding: 0 !important; // Override app-container padding
  position: relative;
}

.toolbar {
  padding: 10px 20px;
  background-color: #1f1f1f;
  display: flex;
  justify-content: space-between;
  align-items: center;
  border-bottom: 1px solid #333;
}

.video-grid {
  flex: 1;
  display: flex;
  flex-wrap: wrap;
  background: #000;
  align-content: flex-start;
  position: relative;
}

.video-cell {
  border: 1px solid #333;
  box-sizing: border-box;
  position: relative;
  background-color: #1a1a1a;
  color: #fff;
  transition: all 0.2s;
  
  &.active {
    border: 2px solid #006838;
    z-index: 10;
  }
  
  &:hover {
    .cell-tools {
      opacity: 1;
    }
  }

  .video-content {
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
  }

  .placeholder-content {
    text-align: center;
    color: #666;
    
    .status-text {
      margin-top: 5px;
      font-size: 12px;
      color: #d9001b;
    }
  }

  .cell-tools {
    position: absolute;
    bottom: 0;
    left: 0;
    right: 0;
    height: 30px;
    background: rgba(0,0,0,0.7);
    display: flex;
    align-items: center;
    justify-content: flex-end;
    padding: 0 10px;
    opacity: 0;
    transition: opacity 0.3s;

    i {
      cursor: pointer;
      margin-left: 10px;
      &:hover {
        color: #006838;
      }
    }
  }
}

.layout-1 .video-cell { width: 100%; height: 100%; }
.layout-4 .video-cell { width: 50%; height: 50%; }
.layout-9 .video-cell { width: 33.33%; height: 33.33%; }
.layout-16 .video-cell { width: 25%; height: 25%; }

.ptz-control {
  position: absolute;
  right: 20px;
  bottom: 20px;
  width: 200px;
  opacity: 0.8;
  z-index: 100;
  
  &:hover {
    opacity: 1;
  }
}
</style>
