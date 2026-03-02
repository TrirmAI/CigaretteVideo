import Vue from 'vue'
import Router from 'vue-router'

Vue.use(Router)

/* Layout */
import Layout from '@/layout'

/**
 * Note: sub-menu only appear when route children.length >= 1
 * Detail see: https://panjiachen.github.io/vue-element-admin-site/guide/essentials/router-and-nav.html
 */

export const constantRoutes = [
  {
    path: '/login',
    component: () => import('@/views/login/index'),
    hidden: true
  },

  {
    path: '/404',
    component: () => import('@/views/404'),
    hidden: true
  },

  {
    path: '/',
    component: Layout,
    redirect: '/dashboard',
    children: [{
      path: 'dashboard',
      name: 'Dashboard',
      component: () => import('@/views/dashboard/index'),
      meta: { title: '综合态势', icon: 'dashboard', affix: true }
    }]
  },

  // 视频监控中心
  {
    path: '/video',
    component: Layout,
    redirect: '/video/preview',
    name: 'VideoCenter',
    meta: { title: '视频监控中心', icon: 'el-icon-video-camera' },
    children: [
      {
        path: 'preview',
        name: 'VideoPreview',
        component: () => import('@/views/live/index'),
        meta: { title: '多画面预览', icon: 'el-icon-view' }
      },
      {
        path: 'device',
        name: 'DeviceList',
        component: () => import('@/views/device/index'),
        meta: { title: '国标设备', icon: 'el-icon-monitor' }
      },
      {
        path: 'push',
        name: 'PushList',
        component: () => import('@/views/streamPush/index'),
        meta: { title: '推流列表', icon: 'el-icon-upload2' }
      },
      {
        path: 'streamProxy',
        name: 'StreamProxyManage',
        component: () => import('@/views/streamProxy/index'),
        meta: { title: '拉流代理', icon: 'el-icon-video-play' }
      },
      {
        path: 'cloudRecord',
        name: 'CloudRecordManage',
        component: () => import('@/views/cloudRecord/index'),
        meta: { title: '云端录像', icon: 'el-icon-cloudy' }
      },
      {
        path: 'map',
        name: 'Map',
        component: () => import('@/views/map/index'),
        meta: { title: '电子地图', icon: 'el-icon-map-location' }
      }
    ]
  },

  // 智能应用中心
  {
    path: '/ai',
    component: Layout,
    redirect: '/ai/chat',
    name: 'AICenter',
    meta: { title: '智能应用中心', icon: 'el-icon-cpu' },
    children: [
      {
        path: 'chat',
        name: 'AIChat',
        component: () => import('@/views/ai/ChatCenter'),
        meta: { title: '自然语言交互', icon: 'el-icon-chat-dot-round' }
      },
      {
        path: 'alerts',
        name: 'AIAlerts',
        component: () => import('@/views/ai/Alerts'),
        meta: { title: '智能告警', icon: 'el-icon-bell' }
      },
      {
        path: 'models',
        name: 'AIModels',
        component: () => import('@/views/ai/Models'),
        meta: { title: '模型训练', icon: 'el-icon-s-operation' }
      }
    ]
  },

  // 案事件中心
  {
    path: '/cases',
    component: Layout,
    redirect: '/cases/workbench',
    name: 'CaseCenter',
    meta: { title: '案事件中心', icon: 'el-icon-document' },
    children: [
      {
        path: 'workbench',
        name: 'CaseWorkbench',
        component: () => import('@/views/cases/Workbench'),
        meta: { title: '案事件库', icon: 'el-icon-files' }
      },
      {
        path: 'evidence',
        name: 'CaseEvidence',
        component: () => import('@/views/cases/Evidence'),
        meta: { title: '证据管理', icon: 'el-icon-folder-opened' }
      },
      {
        path: 'recorder',
        name: 'RecorderList',
        component: () => import('@/views/recorder/List'),
        meta: { title: '执法仪管理', icon: 'el-icon-user-solid' }
      }
    ]
  },

  // 运维管理中心
  {
    path: '/ops',
    component: Layout,
    redirect: '/ops/dashboard',
    name: 'OpsCenter',
    meta: { title: '运维管理中心', icon: 'el-icon-s-tools' },
    children: [
      {
        path: 'dashboard',
        name: 'OpsDashboard',
        component: () => import('@/views/ops-new/Dashboard'),
        meta: { title: '运维大盘', icon: 'el-icon-data-line' }
      },
      {
        path: 'media',
        name: 'MediaServer',
        component: () => import('@/views/mediaServer/index'),
        meta: { title: '媒体节点', icon: 'mediaServerList' }
      },
      {
        path: 'logs',
        name: 'OpsLogs',
        component: () => import('@/views/operations/historyLog'),
        meta: { title: '系统日志', icon: 'el-icon-notebook-2' }
      }
    ]
  },

  {
    path: '/play/wasm/:url',
    name: 'wasmPlayer',
    hidden: true,
    component: () => import('@/views/common/jessibuca.vue')
  },
  {
    path: '/play/rtc/:url',
    name: 'rtcPlayer',
    component: () => import('@/views/common/rtcPlayer.vue')
  },

  // 系统配置中心
  {
    path: '/config',
    component: Layout,
    redirect: '/config/user',
    name: 'ConfigCenter',
    meta: { title: '系统配置中心', icon: 'el-icon-setting' },
    children: [
      {
        path: 'user',
        name: 'UserManage',
        component: () => import('@/views/user/index'),
        meta: { title: '用户管理', icon: 'el-icon-user' }
      },
      {
        path: 'platform',
        name: 'PlatformManage',
        component: () => import('@/views/platform/index'),
        meta: { title: '国标级联', icon: 'el-icon-connection' }
      },
      {
        path: 'recordPlan',
        name: 'RecordPlanManage',
        component: () => import('@/views/recordPlan/index'),
        meta: { title: '录像计划', icon: 'el-icon-date' }
      },
      {
        path: 'group',
        name: 'GroupManage',
        component: () => import('@/views/channel/group/index'),
        meta: { title: '业务分组', icon: 'el-icon-files' }
      },
      {
        path: 'region',
        name: 'RegionManage',
        component: () => import('@/views/channel/region/index'),
        meta: { title: '行政区划', icon: 'el-icon-office-building' }
      }
    ]
  },
  
  // 404 page must be placed at the end !!!
  { path: '*', redirect: '/404', hidden: true }
]

const createRouter = () => new Router({
  // mode: 'history', // require service support
  scrollBehavior: () => ({ y: 0 }),
  routes: constantRoutes
})

const router = createRouter()

// Detail see: https://github.com/vuejs/vue-router/issues/1234#issuecomment-357941465
export function resetRouter() {
  const newRouter = createRouter()
  router.matcher = newRouter.matcher // reset router
}

export default router
