<template>
  <div
    ref="container"
    style="width:100%; height: 100%; background-color: #000000;margin:0 auto;position: relative;"
    @dblclick="fullscreenSwich"
  >
    <div style="width:100%; padding-top: 56.25%; position: relative;" />
    
    <!-- Centered Watermark Overlay -->
    <div v-if="showWatermark && watermarkText" class="jessibuca-watermark-center">
      <div>{{ watermarkText }}</div>
      <div v-if="deviceId" style="font-size: 0.6em; margin-top: 5px;">{{ deviceId }}</div>
    </div>

    <div id="buttonsBox" class="buttons-box" >
      <div class="buttons-box-left">
        <i v-if="!playing" class="iconfont icon-play jessibuca-btn" @click="playBtnClick" />
        <i v-if="playing" class="iconfont icon-pause jessibuca-btn" @click="pause" />
        <i class="iconfont icon-stop jessibuca-btn" @click="stop" />
        <i v-if="isNotMute" class="iconfont icon-audio-high jessibuca-btn" @click="mute()" />
        <i v-if="!isNotMute" class="iconfont icon-audio-mute jessibuca-btn" @click="cancelMute()" />
      </div>
      <div class="buttons-box-right">
        <span class="jessibuca-btn">{{ kBps }} kb/s</span>
        
        <!-- Watermark Toggle Button -->
        <i 
          class="iconfont icon-shuiyin jessibuca-btn" 
          :style="{ color: showWatermark ? '#006838' : '#fff' }"
          title="水印开关"
          @click="toggleWatermark"
        >印</i>

        <i
          class="iconfont icon-camera1196054easyiconnet jessibuca-btn"
          style="font-size: 1rem !important"
          @click="screenshot"
        />
        <i class="iconfont icon-shuaxin11 jessibuca-btn" @click="playBtnClick" />
        <i v-if="!fullscreen" class="iconfont icon-weibiaoti10 jessibuca-btn" @click="fullscreenSwich" />
        <i v-if="fullscreen" class="iconfont icon-weibiaoti11 jessibuca-btn" @click="fullscreenSwich" />
      </div>
    </div>
  </div>
</template>

<script>
const jessibucaPlayer = {}
export default {
  name: 'Jessibuca',
  props: ['videoUrl', 'error', 'hasAudio', 'height', 'showButton', 'watermarkText', 'deviceId'],
  data() {
    return {
      currentVideoUrl: this.videoUrl, // Use local data property
      playing: false,
      isNotMute: true,
      quieting: false,
      fullscreen: false,
      loaded: false, // mute
      speed: 0,
      performance: '', // 工作情况
      kBps: 0,
      btnDom: null,
      videoInfo: null,
      volume: 1,
      playerTime: 0,
      rotate: 0,
      vod: true, // 点播
      forceNoOffscreen: false,
      showWatermark: false // Default hidden
    }
  },
  watch: {
    videoUrl(newVal) {
      this.currentVideoUrl = newVal;
    }
  },
  created() {
    const paramUrl = decodeURIComponent(this.$route.params.url)
    console.log(paramUrl)
    if (!this.currentVideoUrl && paramUrl) {
      this.currentVideoUrl = paramUrl
    }
    this.btnDom = document.getElementById('buttonsBox')
  },
  mounted() {},
  destroyed() {
    if (jessibucaPlayer[this._uid]) {
      jessibucaPlayer[this._uid].videoPTS = 0
      jessibucaPlayer[this._uid].destroy()
    }
    this.playing = false
    this.loaded = false
    this.performance = ''
    this.playerTime = 0
  },
  methods: {
    create() {
      if (jessibucaPlayer[this._uid]) {
        jessibucaPlayer[this._uid].destroy()
      }
      if (this.$refs.container.dataset['jessibuca']) {
        this.$refs.container.dataset['jessibuca'] = undefined
      }

      if (this.$refs.container.getAttribute('data-jessibuca')) {
        this.$refs.container.removeAttribute('data-jessibuca')
      }
      const options = {
        container: this.$refs.container,
        videoBuffer: 0,
        isResize: true,
        useMSE: true,
        useWCS: false,
        text: '',
        // background: '',
        controlAutoHide: false,
        debug: false,
        hotKey: true,
        decoder: '/static/js/jessibuca/decoder.js',
        sNotMute: true,
        timeout: 10,
        recordType: 'mp4',
        isFlv: false,
        forceNoOffscreen: true,
        hasAudio: typeof (this.hasAudio) === 'undefined' ? true : this.hasAudio,
        heartTimeout: 5,
        heartTimeoutReplay: true,
        heartTimeoutReplayTimes: 3,
        hiddenAutoPause: false,
        isFullResize: false,

        isNotMute: this.isNotMute,
        keepScreenOn: true,
        loadingText: '请稍等, 视频加载中......',
        loadingTimeout: 10,
        loadingTimeoutReplay: true,
        loadingTimeoutReplayTimes: 3,
        openWebglAlignment: false,
        operateBtns: {
          fullscreen: false,
          screenshot: false,
          play: false,
          audio: false,
          recorder: false
        },
        // rotate: 0,
        showBandwidth: false,
        supportDblclickFullscreen: false,

        useWebFullSreen: true,

        wasmDecodeErrorReplay: true,
        wcsUseVideoRendcer: true
      }
      console.log('Jessibuca -> options: ', options)
      jessibucaPlayer[this._uid] = new window.Jessibuca(options)

      const jessibuca = jessibucaPlayer[this._uid]
      jessibuca.on('pause', () => {
        this.playing = false
        this.$emit('playStatusChange', false)
      })
      jessibuca.on('play', () => {
        this.playing = true
        this.$emit('playStatusChange', true)
      })
      jessibuca.on('fullscreen', (msg) => {
        this.fullscreen = msg
      })
      jessibuca.on('mute', (msg) => {
        this.isNotMute = !msg
      })
      jessibuca.on('performance', (performance) => {
        let show = '卡顿'
        if (performance === 2) {
          show = '非常流畅'
        } else if (performance === 1) {
          show = '流畅'
        }
        this.performance = show
      })
      jessibuca.on('kBps', (kBps) => {
        this.kBps = Math.round(kBps)
      })
      jessibuca.on('videoInfo', (msg) => {
        console.log('Jessibuca -> videoInfo: ', msg)
      })
      jessibuca.on('audioInfo', (msg) => {
        console.log('Jessibuca -> audioInfo: ', msg)
      })
      jessibuca.on('error', (msg) => {
        console.log('Jessibuca -> error: ', msg)
      })
      jessibuca.on('timeout', (msg) => {
        console.log('Jessibuca -> timeout: ', msg)
      })
      jessibuca.on('loadingTimeout', (msg) => {
        console.log('Jessibuca -> timeout: ', msg)
      })
      jessibuca.on('delayTimeout', (msg) => {
        console.log('Jessibuca -> timeout: ', msg)
      })
      jessibuca.on('playToRenderTimes', (msg) => {
        console.log('Jessibuca -> playToRenderTimes: ', msg)
      })
      jessibuca.on('timeUpdate', (videoPTS) => {
        if (jessibuca.videoPTS) {
          this.playerTime += (videoPTS - jessibuca.videoPTS)
          this.$emit('playTimeChange', this.playerTime)
        }
        jessibuca.videoPTS = videoPTS
      })
      jessibuca.on('play', () => {
        this.playing = true
        this.loaded = true
        this.quieting = jessibuca.quieting
      })
    },
    playBtnClick: function() {
      this.play(this.currentVideoUrl)
    },
    play: function(url) {
      this.currentVideoUrl = url
      console.log('Jessibuca -> url: ', url)
      if (!jessibucaPlayer[this._uid]) {
        this.create()
      }
      jessibucaPlayer[this._uid].play(url)

      if (jessibucaPlayer[this._uid].hasLoaded()) {
        // jessibucaPlayer[this._uid].play(url)
      } else {
        jessibucaPlayer[this._uid].on('load', () => {
          // jessibucaPlayer[this._uid].play(url)
        })
      }

    },
    pause: function() {
      if (jessibucaPlayer[this._uid]) {
        jessibucaPlayer[this._uid].pause()
      }
      this.playing = false
      this.err = ''
      this.performance = ''
    },
    stop: function() {
      if (jessibucaPlayer[this._uid]) {
        jessibucaPlayer[this._uid].pause()
        jessibucaPlayer[this._uid].clearView()
      }
      this.playing = false
      this.err = ''
      this.performance = ''
    },
    screenshot: function() {
      if (jessibucaPlayer[this._uid]) {
        // 手动抓取画面，不依赖 jessibuca.screenshot API，确保能拿到数据且不触发默认下载
        const container = this.$refs.container
        const video = container.querySelector('video')
        const canvas = container.querySelector('canvas')
        
        let base64Image = null
        
        try {
          if (video) {
            const tempCanvas = document.createElement('canvas')
            tempCanvas.width = video.videoWidth
            tempCanvas.height = video.videoHeight
            const ctx = tempCanvas.getContext('2d')
            ctx.drawImage(video, 0, 0, tempCanvas.width, tempCanvas.height)
            base64Image = tempCanvas.toDataURL('image/png')
          } else if (canvas) {
            base64Image = canvas.toDataURL('image/png')
          }
        } catch (e) {
          console.error('手动抓拍失败', e)
        }

        if (base64Image) {
           this.addWatermarkAndDownload(base64Image)
        } else {
           // Fallback: 如果手动抓取失败，尝试调用原生API (可能无水印)
           console.warn('手动抓取失败，尝试使用原生API')
           const screenshotBase64 = jessibucaPlayer[this._uid].screenshot('base64', 'png', 1.0)
           if (screenshotBase64) {
             this.addWatermarkAndDownload(screenshotBase64)
           }
        }
      }
    },
    toggleWatermark() {
      this.showWatermark = !this.showWatermark;
    },
    addWatermarkAndDownload(base64Image) {
      const canvas = document.createElement('canvas')
      const ctx = canvas.getContext('2d')
      const img = new Image()
      
      // 处理跨域问题（如果需要）
      img.crossOrigin = 'Anonymous'

      img.onload = () => {
        canvas.width = img.width
        canvas.height = img.height
        
        // 绘制视频画面
        ctx.drawImage(img, 0, 0)
        
        // 绘制水印
        if (this.watermarkText) {
           // 动态计算字体大小，确保在不同分辨率下可见
           const fontSize = Math.max(24, Math.floor(canvas.width / 15));
           ctx.font = `bold ${fontSize}px Arial`
           ctx.fillStyle = 'rgba(255, 204, 0, 0.25)' // 金色，透明度 25%
           ctx.textAlign = 'center'
           ctx.textBaseline = 'middle'
           
           // 中心位置
           const x = canvas.width / 2
           const y = canvas.height / 2
           
           // 绘制文字阴影以增强对比度
           ctx.shadowColor = 'rgba(0, 0, 0, 0.25)'
           ctx.shadowBlur = 6
           ctx.shadowOffsetX = 3
           ctx.shadowOffsetY = 3
           
           ctx.fillText(this.watermarkText, x, y - (this.deviceId ? fontSize * 0.6 : 0))
           
           // 绘制设备标识 (组织+通道)
           if (this.deviceId) {
             ctx.font = `bold ${Math.floor(fontSize * 0.6)}px Arial`
             ctx.fillStyle = 'rgba(255, 204, 0, 0.25)' // 同样使用金色
             ctx.fillText(this.deviceId, x, y + fontSize * 0.4)
           }

           // 绘制时间戳 (可选)
           const timeStr = new Date().toLocaleString()
           ctx.font = `bold ${Math.floor(fontSize * 0.5)}px Arial`
           ctx.fillStyle = 'rgba(255, 255, 255, 0.25)' // 白色，透明度 25%
           ctx.fillText(timeStr, x, y + fontSize * (this.deviceId ? 1.4 : 1.2))
        }
        
        // 下载
        try {
          const dataUrl = canvas.toDataURL('image/png')
          const link = document.createElement('a')
          link.download = `screenshot_${new Date().getTime()}.png`
          link.href = dataUrl
          document.body.appendChild(link) // 兼容性
          link.click()
          document.body.removeChild(link)
        } catch (e) {
          console.error('截图导出失败', e)
        }
      }
      
      img.onerror = (err) => {
        console.error('截图图片加载失败', err)
      }

      img.src = base64Image
    },
    mute: function() {
      if (jessibucaPlayer[this._uid]) {
        jessibucaPlayer[this._uid].mute()
      }
    },
    cancelMute: function() {
      if (jessibucaPlayer[this._uid]) {
        jessibucaPlayer[this._uid].cancelMute()
      }
    },
    destroy: function() {
      if (jessibucaPlayer[this._uid]) {
        jessibucaPlayer[this._uid].destroy()
      }
      // if (document.getElementById('buttonsBox') === null && (typeof this.showButton === 'undefined' || this.showButton)) {
      //   this.$refs.container.appendChild(this.btnDom)
      // }
      jessibucaPlayer[this._uid] = null
      this.playing = false
      this.err = ''
      this.performance = ''
    },
    fullscreenSwich: function() {
      const isFull = this.isFullscreen()
      jessibucaPlayer[this._uid].setFullscreen(!isFull)
      this.fullscreen = !isFull
    },
    isFullscreen: function() {
      return document.fullscreenElement ||
        document.msFullscreenElement ||
        document.mozFullScreenElement ||
        document.webkitFullscreenElement || false
    },
    setPlaybackRate: function() {

    }
  }
}
</script>

<style>
.buttons-box {
  width: 100%;
  height: 28px;
  background-color: rgba(43, 51, 63, 0.7);
  position: absolute;
  display: -webkit-box;
  display: -ms-flexbox;
  display: flex;
  left: 0;
  bottom: 0;
  user-select: none;
  z-index: 10;
}

.jessibuca-btn {
  width: 20px;
  color: rgb(255, 255, 255);
  line-height: 27px;
  margin: 0px 10px;
  padding: 0px 2px;
  cursor: pointer;
  text-align: center;
  font-size: 0.8rem !important;
}

.buttons-box-right {
  position: absolute;
  right: 0;
}

.jessibuca-watermark-center {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  color: rgba(255, 204, 0, 0.25);
  font-size: 24px;
  font-weight: bold;
  text-shadow: 2px 2px 4px rgba(0, 0, 0, 0.25);
  pointer-events: none;
  z-index: 5;
}
</style>
