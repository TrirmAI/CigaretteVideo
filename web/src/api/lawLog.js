import request from '@/utils/request'

export function getLawLogs(query) {
  return request({
    url: '/api/ext/law-log/case-list',
    method: 'get',
    params: query
  })
}

export function getAllLawLogs(params) {
  return request({
    url: '/api/ext/law-log/list',
    method: 'get',
    params: params
  })
}
