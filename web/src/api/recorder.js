import request from '@/utils/request'

export function uploadRecorderFile(data) {
  return request({
    url: '/api/recorder/upload',
    method: 'post',
    data: data,
    headers: {
      'Content-Type': 'multipart/form-data'
    }
  })
}
