import {
  getTreeList,
  update,
  add, deleteGroup, getPath, queryTree, sync
} from '@/api/group'

const actions = {
  update({ commit }, formData) {
    return new Promise((resolve, reject) => {
      update(formData).then(response => {
        const { data } = response
        resolve(data)
      }).catch(error => {
        reject(error)
      })
    })
  },
  add({ commit }, formData) {
    return new Promise((resolve, reject) => {
      add(formData).then(response => {
        const { data } = response
        resolve(data)
      }).catch(error => {
        reject(error)
      })
    })
  },
  getTreeList({ commit }, params) {
    return new Promise((resolve, reject) => {
      getTreeList(params).then(response => {
        const { data } = response
        if (data && Array.isArray(data)) {
          data.forEach(item => {
            if (item.name === '广百仓') {
              item.name = '人和基地'
            }
          })
        }
        resolve(data)
      }).catch(error => {
        reject(error)
      })
    })
  },
  deleteGroup({ commit }, id) {
    return new Promise((resolve, reject) => {
      deleteGroup(id).then(response => {
        const { data } = response
        resolve(data)
      }).catch(error => {
        reject(error)
      })
    })
  },
  getPath({ commit }, params) {
    return new Promise((resolve, reject) => {
      getPath(params).then(response => {
        const { data } = response
        resolve(data)
      }).catch(error => {
        reject(error)
      })
    })
  },
  queryTree({ commit }, param) {
    return new Promise((resolve, reject) => {
      queryTree(param).then(response => {
        const { data } = response
        resolve(data)
      }).catch(error => {
        reject(error)
      })
    })
  }
}

export default {
  namespaced: true,
  actions
}

