import request from '@/utils/request'

// Mock Data
const PRESET_MODELS = [
  {
    id: 'm_001',
    name: '人员检测模型 (YOLOv8)',
    version: 'v2.1',
    accuracy: '94.5%',
    status: 'ready',
    lastUpdate: '2023-10-25 14:30:00'
  },
  {
    id: 'm_002',
    name: '烟火检测模型 (专业版)',
    version: 'v1.0',
    accuracy: '88.2%',
    status: 'ready',
    lastUpdate: '2023-10-20 09:15:00'
  },
  {
    id: 'm_003',
    name: '安全帽检测模型',
    version: 'v1.0-beta',
    accuracy: '-',
    status: 'ready',
    lastUpdate: '2023-10-27 10:00:00'
  }
]

const PRESET_HISTORY = [
  {
    id: 'h_001',
    modelId: 'm_001',
    version: 'v2.1',
    createTime: '2023-10-25 10:00:00',
    finishTime: '2023-10-25 14:30:00',
    status: 'completed',
    accuracy: 0.945,
    loss: 0.0231,
    filePath: '/models/yolov8-person/v2.1.pt'
  },
  {
    id: 'h_002',
    modelId: 'm_001',
    version: 'v2.0',
    createTime: '2023-10-20 10:00:00',
    finishTime: '2023-10-20 15:00:00',
    status: 'completed',
    accuracy: 0.912,
    loss: 0.0451,
    filePath: '/models/yolov8-person/v2.0.pt'
  }
]

const STORAGE_KEY_MODELS = 'wvp_ai_models_store'
const STORAGE_KEY_HISTORY = 'wvp_ai_history_store'

// Helper
const delay = (ms = 300) => new Promise(resolve => setTimeout(resolve, ms))

function getLocal(key) {
  try {
    const str = localStorage.getItem(key)
    return str ? JSON.parse(str) : []
  } catch (e) { return [] }
}

function saveLocal(key, data) {
  localStorage.setItem(key, JSON.stringify(data))
}

// APIs

export function getModels() {
  return delay().then(() => {
    const local = getLocal(STORAGE_KEY_MODELS)
    // Merge preset and local (simple implementation: if local has items, use them + presets if distinct IDs)
    // For simplicity: just concat distinct ones or overwrite presets if ID matches
    
    // We will just append local models to presets for display
    const list = [...PRESET_MODELS, ...local]
    return list
  })
}

export function createModel(data) {
  return delay().then(() => {
    const newModel = {
      id: 'm_' + Date.now(),
      name: data.name,
      version: data.version || 'v1.0',
      accuracy: '-',
      status: 'ready',
      lastUpdate: new Date().toLocaleString()
    }
    const local = getLocal(STORAGE_KEY_MODELS)
    local.push(newModel)
    saveLocal(STORAGE_KEY_MODELS, local)
    return newModel
  })
}

export function trainModel(modelName) {
  return delay().then(() => {
    // In a real scenario, this would trigger a backend task
    // Here we just return success, the UI might handle the "Training" status visual change
    // or we could update the model status in local storage if we found it there
    
    // Let's try to update status if it's a local model
    const local = getLocal(STORAGE_KEY_MODELS)
    const idx = local.findIndex(m => m.name === modelName)
    if (idx !== -1) {
      local[idx].status = 'training'
      local[idx].lastUpdate = new Date().toLocaleString()
      saveLocal(STORAGE_KEY_MODELS, local)
    }
    
    return { msg: 'Training started' }
  })
}

export function getModelHistory(modelId) {
  return delay().then(() => {
    // Filter preset history
    const preset = PRESET_HISTORY.filter(h => h.modelId === modelId)
    // Filter local history (if we implemented saving history locally)
    const local = getLocal(STORAGE_KEY_HISTORY).filter(h => h.modelId === modelId)
    
    return [...preset, ...local]
  })
}
