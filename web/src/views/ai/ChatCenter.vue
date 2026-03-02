<template>
  <div class="app-container">
    <el-row :gutter="20">
      <el-col :span="18">
        <el-card class="chat-card" :body-style="{ padding: '0px', height: '100%' }">
          <div slot="header" class="clearfix">
            <span style="font-weight: bold; font-size: 16px;"><i class="el-icon-chat-dot-round"></i> 智能助手</span>
            <el-tag size="small" type="success" style="float: right;">在线</el-tag>
          </div>
          
          <div class="chat-window" ref="chatWindow">
            <div v-if="messages.length === 0" class="empty-state">
              <i class="el-icon-service" style="font-size: 48px; color: #ccc;"></i>
              <p>有什么我可以帮您的吗？</p>
              <div class="quick-actions">
                <el-tag @click="fillInput('查找戴红帽子的嫌疑人')" class="action-tag">查找戴红帽子的嫌疑人</el-tag>
                <el-tag @click="fillInput('分析当前视频流的人流量')" class="action-tag">分析人流量</el-tag>
                <el-tag @click="fillInput('显示最近的告警信息')" class="action-tag">显示最近告警</el-tag>
              </div>
            </div>

            <div v-for="(msg, index) in messages" :key="index" class="message-row" :class="msg.role === 'User' ? 'message-right' : 'message-left'">
              <el-avatar :size="40" :icon="msg.role === 'User' ? 'el-icon-user-solid' : 'el-icon-cpu'" :class="msg.role === 'User' ? 'avatar-user' : 'avatar-ai'"></el-avatar>
              <div class="message-content">
                <div class="message-info">{{ msg.role === 'User' ? '操作员' : 'AI 助手' }} <span class="time">{{ msg.time }}</span></div>
                <div class="message-bubble">
                  <div>{{ msg.content }}</div>
                </div>
              </div>
            </div>
            <div v-if="loading" class="message-row message-left">
              <el-avatar :size="40" icon="el-icon-cpu" class="avatar-ai"></el-avatar>
              <div class="message-content">
                <div class="message-bubble typing">
                  <span class="dot"></span><span class="dot"></span><span class="dot"></span>
                </div>
              </div>
            </div>
          </div>
          
          <!-- Search Result Panel -->
          <div v-if="searchResult && (searchResult.images.length > 0 || searchResult.videos.length > 0 || searchResult.charts.length > 0)" class="result-panel">
            <div class="result-header">
              <span><i class="el-icon-s-data"></i> 智能检索结果</span>
              <el-button type="text" icon="el-icon-close" size="mini" @click="clearResult" style="float: right; padding: 0;"></el-button>
            </div>
            <div class="result-content">
              <el-tabs v-model="activeTab" @tab-click="handleTabClick">
                 <el-tab-pane label="图片结果" name="images" v-if="searchResult.images.length > 0">
                    <div class="image-grid-scroll">
                      <el-image 
                        v-for="(img, i) in searchResult.images" 
                        :key="i"
                        :src="img.url" 
                        :preview-src-list="searchResult.images.map(item => item.url)"
                        class="result-image"
                        fit="cover">
                      </el-image>
                    </div>
                 </el-tab-pane>
                 <el-tab-pane label="关联视频" name="videos" v-if="searchResult.videos.length > 0">
                    <div class="video-grid-scroll">
                      <div v-for="(vid, i) in searchResult.videos" :key="'v'+i" class="result-video">
                         <video :src="vid.url" controls></video>
                         <div class="video-label">片段 {{ i + 1 }}</div>
                      </div>
                    </div>
                 </el-tab-pane>
                 <el-tab-pane label="数据图表" name="charts" v-if="searchResult.charts.length > 0">
                    <div v-for="(chart, i) in searchResult.charts" :key="'rc'+i" class="result-chart">
                       <div :id="'result-chart-' + i" style="width: 100%; height: 450px;"></div>
                    </div>
                 </el-tab-pane>
              </el-tabs>
            </div>
          </div>

          <div class="input-area">
            <div class="filter-toolbar">
              <el-select v-model="selectedChannel" placeholder="选择通道" size="small" style="width: 160px; margin-right: 10px;">
                <el-option label="全部通道" value="all"></el-option>
                <el-option v-for="item in channelOptions" :key="item.value" :label="item.label" :value="item.value"></el-option>
              </el-select>
              <el-date-picker
                v-model="dateRange"
                type="datetimerange"
                size="small"
                range-separator="至"
                start-placeholder="开始时间"
                end-placeholder="结束时间"
                :default-time="['00:00:00', '23:59:59']"
                style="width: 340px;">
              </el-date-picker>
            </div>
            <el-input 
              v-model="input" 
              placeholder="请输入指令..." 
              @keyup.enter.native="send"
              class="chat-input"
            >
              <el-button slot="append" type="primary" icon="el-icon-position" @click="send" :loading="loading">发送</el-button>
            </el-input>
          </div>
        </el-card>
      </el-col>
      
      <el-col :span="6">
        <el-card class="status-card">
          <div slot="header"><span><i class="el-icon-s-operation"></i> 执行状态</span></div>
          <el-steps direction="vertical" :active="activeStep" finish-status="success">
            <el-step title="意图识别" description="分析用户自然语言指令"></el-step>
            <el-step title="任务拆解" description="生成具体执行步骤"></el-step>
            <el-step title="模型调用" description="调用 CV/NLP 模型处理"></el-step>
            <el-step title="结果反馈" description="整合数据并展示"></el-step>
          </el-steps>
        </el-card>

        <el-card class="status-card" style="margin-top: 20px;">
          <div slot="header"><span><i class="el-icon-info"></i> 模型信息</span></div>
          <div class="model-info">
            <p><span class="label">当前模型:</span> GenAI-Pro-V2</p>
            <p><span class="label">响应延迟:</span> ~200ms</p>
            <p><span class="label">置信度:</span> 98.5%</p>
          </div>
        </el-card>
      </el-col>
    </el-row>
  </div>
</template>

<script>
import request from '@/utils/request'
import echarts from 'echarts'

export default {
  data() {
    return {
      input: '',
      messages: [],
      loading: false,
      activeStep: 0,
      useMock: true, // Dual-mode toggle
      selectedChannel: 'all',
      dateRange: [],
      channelOptions: [
        { label: '东门广场-CAM01', value: 'cam01' },
        { label: '办公楼大厅-CAM02', value: 'cam02' },
        { label: '仓库区-CAM03', value: 'cam03' },
        { label: '停车场入口-CAM05', value: 'cam05' }
      ],
      searchResult: {
        images: [],
        videos: [],
        charts: []
      },
      activeTab: 'images'
    }
  },
  watch: {
    searchResult: {
      handler(val) {
        if (val.charts.length > 0) {
          this.activeTab = 'charts' // 优先显示图表（如果有人流量分析）
          this.$nextTick(() => {
            this.renderCharts()
          })
        } else if (val.images.length > 0) {
          this.activeTab = 'images'
        } else if (val.videos.length > 0) {
          this.activeTab = 'videos'
        }
      },
      deep: true
    }
  },
  methods: {
    handleTabClick(tab) {
      if (tab.name === 'charts') {
        this.$nextTick(() => {
          this.resizeCharts()
        })
      }
    },
    resizeCharts() {
      if (this.searchResult && this.searchResult.charts.length > 0) {
        this.searchResult.charts.forEach((chartData, i) => {
           const domId = 'result-chart-' + i;
           const dom = document.getElementById(domId);
           if (dom) {
              const chart = echarts.getInstanceByDom(dom);
              if (chart) {
                chart.resize();
              } else {
                // 如果实例不存在（可能从未渲染过），尝试渲染
                this.renderCharts();
              }
           }
        });
      }
    },
    clearResult() {
      this.searchResult = { images: [], videos: [], charts: [] };
    },
    fillInput(text) {
      this.input = text;
    },
    send() {
      if (!this.input) return;
      
      const userMsg = { 
        role: 'User', 
        content: this.input, 
        time: new Date().toLocaleTimeString() 
      };
      this.messages.push(userMsg);
      const msg = this.input;
      this.input = '';
      this.loading = true;
      this.activeStep = 1;
      this.scrollToBottom();

      // Simulate steps
      setTimeout(() => { this.activeStep = 2 }, 500);
      setTimeout(() => { this.activeStep = 3 }, 1000);

      this.handleChatRequest(msg);
    },
    handleChatRequest(message) {
      if (this.useMock) {
        // Simulation Mode
        setTimeout(() => {
           const response = this.mockApiResponse(message);
           this.processResponse(response);
        }, 1500);
      } else {
        // Real API Mode
        request({
          url: '/api/ext/ai/chat',
          method: 'post',
          params: { message: message }
        }).then(res => {
          // Expecting res to follow the unified structure { text, attachments }
          // If the real API returns a string, wrap it
          const normalizedRes = typeof res === 'string' ? { text: res, attachments: [] } : res;
          this.processResponse(normalizedRes);
        }).catch(() => {
          this.loading = false;
          this.activeStep = 0;
          this.$message.error('请求失败，请检查网络或切换至仿真模式');
        })
      }
    },
    processResponse(response) {
      this.activeStep = 4;
      const aiMsg = { 
        role: 'AI', 
        content: response.text,
        time: new Date().toLocaleTimeString() 
      };
      this.messages.push(aiMsg);
      
      // Update Search Result Panel
      if (response.attachments && response.attachments.length > 0) {
        this.searchResult = {
          images: this.getAttachmentsByType(response.attachments, 'image'),
          videos: this.getAttachmentsByType(response.attachments, 'video'),
          charts: this.getAttachmentsByType(response.attachments, 'chart')
        };
      }
      
      this.loading = false;
      this.scrollToBottom();
    },
    mockApiResponse(input) {
      let contextPrefix = '';
      if (this.selectedChannel !== 'all') {
        const channelName = this.channelOptions.find(c => c.value === this.selectedChannel)?.label || this.selectedChannel;
        contextPrefix += `[限定通道: ${channelName}] `;
      }
      if (this.dateRange && this.dateRange.length === 2) {
        const start = this.dateRange[0].toLocaleTimeString();
        const end = this.dateRange[1].toLocaleTimeString();
        contextPrefix += `[时间范围: ${start} - ${end}] `;
      }

      if (input.includes('红帽子') || input.includes('嫌疑人')) {
        return {
          text: `${contextPrefix}收到。已为您在指定范围内检索特征：[红色帽子, 人员]。共发现 8 个匹配目标，并关联 2 段实时录像。`,
          attachments: [
            { type: 'image', url: '/static/images/ai/suspect-red-hat-1.jpg' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-2.jpg' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-3.webp' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-4.webp' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-5.webp' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-6.png' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-7.png' },
            { type: 'image', url: '/static/images/ai/suspect-red-hat-8.png' },
            { type: 'video', url: '/static/images/ai/suspect-red-hat-1.mp4' },
            { type: 'video', url: '/static/images/ai/suspect-red-hat-2.mp4' }
          ]
        }
      } else if (input.includes('人流量')) {
         // Calculate dynamic time points based on dateRange
         let startTime, endTime;
         if (this.dateRange && this.dateRange.length === 2) {
            startTime = new Date(this.dateRange[0]).getTime();
            endTime = new Date(this.dateRange[1]).getTime();
         } else {
            // Default to today 00:00 to 23:59
            const now = new Date();
            startTime = new Date(now.setHours(0,0,0,0)).getTime();
            endTime = new Date(now.setHours(23,59,59,999)).getTime();
         }

         const targetPoints = 24; // Target around 20-30 points
         const duration = endTime - startTime;
         const interval = duration / targetPoints;
         
         const xData = [];
         const yData = [];
         
         for (let i = 0; i <= targetPoints; i++) {
            const timePoint = new Date(startTime + i * interval);
            const hours = timePoint.getHours().toString().padStart(2, '0');
            const minutes = timePoint.getMinutes().toString().padStart(2, '0');
            xData.push(`${hours}:${minutes}`);
            // Generate mock data with some randomness
            // Base flow around 100, peak at noon/evening
            let base = 100;
            if (timePoint.getHours() >= 8 && timePoint.getHours() <= 9) base = 200; // Morning peak
            if (timePoint.getHours() >= 17 && timePoint.getHours() <= 18) base = 220; // Evening peak
            const random = Math.floor(Math.random() * 60) - 30;
            yData.push(Math.max(0, base + random));
         }

         return {
          text: `${contextPrefix}正在分析指定范围内的视频流... 当前区域人流密度为中等，过去一小时累计通过 1280 人次。`,
          attachments: [
            { 
               type: 'chart', 
               data: {
                 tooltip: { trigger: 'axis' },
                 grid: { left: '1%', right: '2%', bottom: '3%', top: '30px', containLabel: true },
                 xAxis: { 
                   type: 'category', 
                   boundaryGap: false,
                   data: xData
                 },
                 yAxis: { type: 'value', name: '人数' },
                 series: [{ 
                   name: '实时人流',
                   data: yData, 
                   type: 'line', 
                   smooth: true,
                   areaStyle: { opacity: 0.3 },
                   itemStyle: { color: '#409EFF' }
                 }]
               }
             },
             { type: 'image', url: '/demo/ryjj01.jpg' },
             { type: 'image', url: '/demo/phjc01.jpg' }
          ]
        }
      } else if (input.includes('告警')) {
        return {
          text: `${contextPrefix}在指定范围内共发生 5 起高风险告警。最新一条为：仓库区-烟火检测（10分钟前）。`,
           attachments: [
            { type: 'image', url: '/demo/yhjc01.jpg' },
            { type: 'image', url: '/demo/ddh01.jpeg' }
          ]
        }
      } else {
        return {
          text: "抱歉，我还在学习中，暂时无法理解该指令。您可以尝试询问‘查找嫌疑人’或‘分析人流量’。",
          attachments: []
        }
      }
    },
    hasAttachmentType(attachments, type) {
      return attachments.some(a => a.type === type);
    },
    getAttachmentsByType(attachments, type) {
      return attachments.filter(a => a.type === type);
    },
    renderCharts() {
      // Render charts in result panel
      if (this.searchResult && this.searchResult.charts.length > 0) {
        this.$nextTick(() => {
          this.searchResult.charts.forEach((chartData, i) => {
             const domId = 'result-chart-' + i;
             const dom = document.getElementById(domId);
             if (dom) {
                // Dispose old instance to ensure clean resize/re-render
                const oldChart = echarts.getInstanceByDom(dom);
                if (oldChart) oldChart.dispose();
                
                const chart = echarts.init(dom);
                chart.setOption(chartData.data);
                
                // Auto resize on window change
                window.addEventListener('resize', () => chart.resize());
             }
          });
        });
      }
    },
    scrollToBottom() {
      this.$nextTick(() => {
        const container = this.$refs.chatWindow;
        container.scrollTop = container.scrollHeight;
      });
    }
  }
}
</script>

<style scoped lang="scss">
.chat-card {
  height: calc(100vh - 120px);
  display: flex;
  flex-direction: column;
}

.chat-window {
  flex: 1;
  overflow-y: auto;
  padding: 20px;
  background-color: var(--bg-color); // Use theme variable
  
  .empty-state {
    text-align: center;
    padding-top: 100px;
    color: var(--text-color-secondary); // Use theme variable
    
    .quick-actions {
      margin-top: 20px;
      .action-tag {
        margin: 5px;
        cursor: pointer;
        &:hover {
          transform: translateY(-2px);
        }
      }
    }
  }
}

.message-row {
  display: flex;
  margin-bottom: 20px;
  align-items: flex-start;
  
  &.message-right {
    flex-direction: row-reverse;
    
    .message-content {
      align-items: flex-end;
      margin-right: 12px;
      margin-left: 0;
    }
    
    .message-bubble {
      background-color: #006838; // Primary color
      color: white;
      border-radius: 8px 0 8px 8px;
    }
  }
  
  &.message-left {
    .message-content {
      align-items: flex-start;
      margin-left: 12px;
    }
    
    .message-bubble {
      background-color: var(--container-bg); // Use theme variable
      color: var(--text-color-primary); // Use theme variable
      border-radius: 0 8px 8px 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }
  }
}

.message-content {
  display: flex;
  flex-direction: column;
  max-width: 70%;
  
  .message-info {
    font-size: 12px;
    color: var(--text-color-secondary); // Use theme variable
    margin-bottom: 4px;
    
    .time {
      margin-left: 5px;
    }
  }
}

.message-bubble {
  padding: 10px 15px;
  font-size: 14px;
  line-height: 1.5;
  word-break: break-word;
  
  &.typing {
    padding: 15px;
    .dot {
      display: inline-block;
      width: 6px;
      height: 6px;
      background: var(--text-color-secondary); // Use theme variable
      border-radius: 50%;
      margin: 0 2px;
      animation: typing 1.4s infinite ease-in-out both;
      
      &:nth-child(1) { animation-delay: -0.32s; }
      &:nth-child(2) { animation-delay: -0.16s; }
    }
  }
}

.result-panel {
  border-top: 1px solid var(--border-color-base); // Use theme variable
  background: var(--container-bg); // Use theme variable
  height: 60%;
  display: flex;
  flex-direction: column;
  
  .result-header {
    padding: 10px 20px;
    border-bottom: 1px solid var(--border-color-base); // Use theme variable
    font-weight: bold;
    color: var(--text-color-primary); // Use theme variable
    display: flex;
    justify-content: space-between;
    align-items: center;
  }
  
  .result-content {
    flex: 1;
    overflow-y: auto;
    padding: 10px 20px;
  }
}

.image-grid-scroll {
  display: flex;
  flex-wrap: wrap;
  gap: 10px;
  
  .result-image {
    width: 120px;
    height: 120px;
    border-radius: 4px;
    border: 1px solid var(--border-color-base); // Use theme variable
    cursor: pointer;
    transition: all 0.2s;
    
    &:hover {
      transform: scale(1.05);
      box-shadow: 0 4px 12px rgba(0,0,0,0.1);
    }
  }
}

.video-grid-scroll {
  display: flex;
  flex-wrap: wrap;
  gap: 20px;
  
  .result-video {
    width: 300px;
    
    video {
      width: 100%;
      border-radius: 4px;
      background: #000;
    }
    
    .video-label {
      font-size: 12px;
      color: var(--text-color-regular); // Use theme variable
      margin-top: 5px;
      text-align: center;
    }
  }
}

@keyframes typing {
  0%, 80%, 100% { transform: scale(0); }
  40% { transform: scale(1); }
}

.avatar-user {
  background-color: #006838;
}

.avatar-ai {
  background-color: #52c41a;
}

.input-area {
  padding: 20px;
  background: var(--container-bg); // Use theme variable
  border-top: 1px solid var(--border-color-base); // Use theme variable

  .filter-toolbar {
    margin-bottom: 15px;
    display: flex;
    align-items: center;
  }
}

.model-info {
  .label {
    color: var(--text-color-secondary); // Use theme variable
    margin-right: 10px;
  }
  p {
    margin: 10px 0;
    font-size: 14px;
    color: var(--text-color-primary); // Use theme variable
  }
}
</style>
