import request from '@/utils/request'

// 预置的案事件 Mock 数据（与 Workbench.vue 保持一致）
const MOCK_CASE_LIST = [
  {
    id: 1001,
    name: '非法运输卷烟案-车牌号京A88888',
    type: '非法运输',
    status: 1,
    priority: 'high',
    priorityVal: 3,
    subject: '王某某',
    location: '高速收费站出口',
    time: '2023-10-27 09:30:00',
    description: '拦截一辆疑似运输假冒伪劣卷烟的厢式货车，现场查获违规卷烟 50 箱。',
    evidence: [
      { id: 'sys_1', type: 'video', url: '/static/video/suspect-red-hat-1.mp4', name: '执法记录仪-拦截现场', createTime: '2023-10-27 09:35:00' }
    ]
  },
  {
    id: 1002,
    name: '无证经营烟草制品案-便民超市',
    type: '无证经营',
    status: 2,
    priority: 'medium',
    priorityVal: 2,
    subject: '李某',
    location: '幸福路12号',
    time: '2023-10-26 14:15:00',
    description: '接到群众举报，对某超市进行突击检查，发现其未持有烟草专卖零售许可证销售卷烟。',
    evidence: [
      { id: 'sys_2', type: 'video', url: '/static/video/suspect-red-hat-2.mp4', name: '执法记录仪-店内取证', createTime: '2023-10-26 14:20:00' }
    ]
  },
  {
    id: 1003,
    name: '销售假冒注册商标卷烟案',
    type: '售假',
    status: 3,
    priority: 'low',
    priorityVal: 1,
    subject: '张三',
    location: '中心市场批发部',
    time: '2023-10-25 10:00:00',
    description: '例行巡查发现某批发部存在销售假烟嫌疑。',
    evidence: []
  }
]

const STORAGE_KEY = 'wvp_case_evidence_store'
const DELETED_KEY = 'wvp_case_evidence_deleted_ids'

// Helper: Get local evidence
function getLocalStore() {
  const str = localStorage.getItem(STORAGE_KEY)
  try {
    return str ? JSON.parse(str) : []
  } catch (e) {
    return []
  }
}

// Helper: Get deleted ids
function getDeletedIds() {
  const str = localStorage.getItem(DELETED_KEY)
  try {
    return str ? JSON.parse(str) : []
  } catch (e) {
    return []
  }
}

// Helper: Save local evidence
function saveLocalStore(list) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))
}

// Helper: Save deleted ids
function saveDeletedIds(list) {
  localStorage.setItem(DELETED_KEY, JSON.stringify(list))
}

// 模拟 API 延迟
const delay = (ms = 200) => new Promise(resolve => setTimeout(resolve, ms))

export function getCaseList() {
  // 返回统一的 Mock 数据
  return delay().then(() => {
    return {
      code: 0,
      data: MOCK_CASE_LIST
    }
  })
}

export function getEvidenceList(caseId) {
  return delay().then(() => {
    // 1. 查找预置证据
    const caseItem = MOCK_CASE_LIST.find(c => c.id == caseId)
    const presetEvidence = caseItem ? (caseItem.evidence || []) : []
    
    // 2. 查找本地存储的证据
    const localStore = getLocalStore()
    const localEvidence = localStore.filter(e => e.caseId == caseId)
    
    // 3. 合并
    let list = [...presetEvidence, ...localEvidence]

    // 4. 过滤已删除的证据
    const deletedIds = getDeletedIds()
    if (deletedIds.length > 0) {
      list = list.filter(item => !deletedIds.includes(item.id))
    }
    
    return {
      code: 0,
      data: list
    }
  })
}

export function addEvidence(data) {
  return delay().then(() => {
    const localStore = getLocalStore()
    
    const newEvidence = {
      id: 'local_' + Date.now(),
      createTime: new Date().toLocaleString(),
      caseId: data.caseId,
      recordId: data.recordId,
      type: data.type || 'video',
      description: data.description || '新添加证据',
      url: '' // 这里如果是云端录像，通常 url 由前端播放时动态获取，或者这里需要 mock 一个 url
    }
    
    // Mock URL logic: 如果关联了录像，生成一个 mock url 方便测试
    // 实际项目中 url 可能通过 getPlayPath 获取
    newEvidence.url = '/static/video/suspect-red-hat-1.mp4' // Fallback for demo
    
    localStore.push(newEvidence)
    saveLocalStore(localStore)
    
    return {
      code: 0,
      data: newEvidence
    }
  })
}

export function updateEvidence(data) {
  return delay().then(() => {
    const localStore = getLocalStore()
    const index = localStore.findIndex(e => e.id === data.id)
    
    if (index !== -1) {
      // 更新本地存储的证据
      localStore[index] = { ...localStore[index], ...data }
      saveLocalStore(localStore)
      return { code: 0, msg: 'success' }
    } else {
      // 可能是预置证据，预置证据不支持持久化修改（除非也存入 localStore 的 override 列表，这里简化处理，只允许改本地的）
      // 或者我们可以把预置证据的修改也“Copy on Write”到 localStore
      // 为演示简单，如果是预置证据，我们假装成功但刷新会重置
      return { code: 0, msg: 'success (preset evidence reset on reload)' }
    }
  })
}

export function deleteEvidence(id) {
  return delay().then(() => {
    // 1. 尝试从本地新增列表中删除
    const localStore = getLocalStore()
    const index = localStore.findIndex(e => e.id === id)
    
    if (index !== -1) {
      localStore.splice(index, 1)
      saveLocalStore(localStore)
    }

    // 2. 将 ID 加入删除列表（覆盖预置证据无法删除的问题）
    const deletedIds = getDeletedIds()
    if (!deletedIds.includes(id)) {
      deletedIds.push(id)
      saveDeletedIds(deletedIds)
    }

    return { code: 0, msg: 'success' }
  })
}

// 模拟多模态 AI 分析接口
export function analyzeEvidence(id) {
  return delay(1500).then(() => {
    // 随机返回一些识别结果
    const candidates = [
      { label: '红色帽子', type: 'clothing', confidence: 0.98 },
      { label: '黑色背包', type: 'object', confidence: 0.95 },
      { label: '男性嫌疑人', type: 'person', confidence: 0.92 },
      { label: '车牌: 京A88888', type: 'vehicle', confidence: 0.99 },
      { label: '香烟货箱', type: 'goods', confidence: 0.88 },
      { label: '超市入口', type: 'location', confidence: 0.85 }
    ]
    
    // 随机取 2-4 个结果
    const count = Math.floor(Math.random() * 3) + 2
    const result = []
    for (let i = 0; i < count; i++) {
      const idx = Math.floor(Math.random() * candidates.length)
      result.push(candidates[idx])
    }
    // 去重
    return {
      code: 0,
      data: [...new Set(result.map(JSON.stringify))].map(JSON.parse)
    }
  })
}
