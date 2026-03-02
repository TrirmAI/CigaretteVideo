<template>
  <div class="video-tree-container">
    <el-tree
      ref="treeRef"
      :data="treeData"
      :props="treeProps"
      node-key="id"
      :default-expand-all="false"
      :expand-on-click-node="false"
      highlight-current
      @node-click="handleNodeClick"
    >
      <template #default="{ node, data }">
        <div class="tree-node">
          <el-icon v-if="data.type === 'device'" class="node-icon device-icon">
            <Monitor />
          </el-icon>
          <el-icon v-else-if="data.type === 'channel'" class="node-icon channel-icon">
            <VideoCamera />
          </el-icon>
          <span class="node-label">{{ node.label }}</span>
          <el-tag
            v-if="data.type === 'device'"
            :type="data.online ? 'success' : 'info'"
            size="small"
            class="status-tag"
          >
            {{ data.online ? '在线' : '离线' }}
          </el-tag>
          <el-tag
            v-else-if="data.type === 'channel'"
            :type="data.online ? 'success' : 'danger'"
            size="small"
            class="status-tag"
          >
            {{ data.online ? '在线' : '离线' }}
          </el-tag>
        </div>
      </template>
    </el-tree>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { Monitor, VideoCamera } from '@element-plus/icons-vue'

const props = defineProps({
  treeData: {
    type: Array,
    default: () => []
  },
  loading: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['node-click', 'load-channels'])

const treeRef = ref(null)
const treeProps = {
  children: 'children',
  label: 'label',
  isLeaf: 'leaf'
}

// 节点点击
const handleNodeClick = (data) => {
  emit('node-click', data)
}

// 暴露方法供父组件调用（保留接口兼容性）
defineExpose({
  loadChannelsForDevice: () => {}
})

// 监听 treeData 变化
// 注意：Element Plus 的 el-tree 组件通过 data prop 自动响应式更新，不需要手动调用 setData
// watch(() => props.treeData, (newData) => {
//   // el-tree 会自动响应 props.treeData 的变化，无需手动更新
// }, { deep: true })
</script>

<style scoped>
.video-tree-container {
  height: 100%;
  overflow-y: auto;
  padding: 10px;
}

.tree-node {
  display: flex;
  align-items: center;
  flex: 1;
  font-size: 14px;
}

.node-icon {
  margin-right: 8px;
  font-size: 16px;
}

.device-icon {
  color: #409eff;
}

.channel-icon {
  color: #67c23a;
}

.node-label {
  flex: 1;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.status-tag {
  margin-left: 8px;
}
</style>

