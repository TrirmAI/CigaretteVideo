import request from '@/utils/request'

export function getPushList(params) {
  return request({
    url: '/api/push/list',
    method: 'get',
    params
  })
}

export function deletePush(id) {
  return request({
    url: '/api/push/remove',
    method: 'post',
    params: {
      id: id
    }
  })
}
