# OpenAPI 外部接口说明

## 概述

本目录包含用于外部应用系统调用的 OpenAPI 接口。这些接口提供了标准化的 RESTful API，方便第三方系统集成。

## 目录结构

```
openapi/
├── controller/          # 控制器层
│   └── OpenApiController.java
├── dto/                 # 数据传输对象
│   └── ApiResponse.java
├── config/              # 配置类
│   └── OpenApiConfig.java
└── README.md           # 本文件
```

## API 路径

所有 OpenAPI 接口的基础路径为：`/openapi/v1`

## 认证方式

OpenAPI 接口支持两种认证方式：

1. **JWT Token 认证**（推荐）
   - 在请求头中添加：`Authorization: Bearer {token}`
   - Token 可通过登录接口获取

2. **API Key 认证**（可选）
   - 在请求头中添加：`X-API-Key: {api_key}`
   - API Key 需要在系统配置中生成

## 响应格式

所有接口统一使用 `WVPResult` 格式返回：

```json
{
  "code": 0,
  "msg": "成功",
  "data": {
    // 具体数据
  }
}
```

### 错误码说明

- `0`: 成功
- `100`: 失败
- `400`: 参数或方法错误
- `401`: 请登录后重新请求
- `403`: 无权限操作
- `404`: 资源未找到
- `408`: 请求超时
- `486`: 超时或无响应
- `500`: 系统异常

## 接口列表

### 1. 健康检查

**接口地址**: `GET /openapi/v1/health`

**描述**: 检查系统是否正常运行

**认证**: 不需要

**响应示例**:
```json
{
  "code": 0,
  "msg": "系统运行正常",
  "data": {
    "status": "UP",
    "timestamp": "2025-12-15T10:30:00",
    "service": "wvp-pro"
  }
}
```

### 2. 获取系统信息

**接口地址**: `GET /openapi/v1/system/info`

**描述**: 获取系统基本信息

**认证**: 不需要

**响应示例**:
```json
{
  "code": 0,
  "msg": "成功",
  "data": {
    "version": "2.7.4",
    "name": "wvp-pro",
    "description": "国标28181视频平台"
  }
}
```

### 3. 示例接口

**接口地址**: `POST /openapi/v1/example`

**描述**: 示例接口，需要认证

**认证**: 需要

**请求体**:
```json
{
  "param1": "value1",
  "param2": "value2"
}
```

**响应示例**:
```json
{
  "code": 0,
  "msg": "成功",
  "data": {
    "message": "请求成功",
    "data": {
      "param1": "value1",
      "param2": "value2"
    },
    "timestamp": 1702627800000
  }
}
```

## 使用示例

### cURL 示例

```bash
# 健康检查
curl -X GET http://localhost:18080/openapi/v1/health

# 获取系统信息
curl -X GET http://localhost:18080/openapi/v1/system/info

# 调用需要认证的接口
curl -X POST http://localhost:18080/openapi/v1/example \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"param1":"value1","param2":"value2"}'
```

### Java 示例

```java
// 使用 OkHttp
OkHttpClient client = new OkHttpClient();
Request request = new Request.Builder()
    .url("http://localhost:18080/openapi/v1/health")
    .get()
    .build();
Response response = client.newCall(request).execute();
```

### Python 示例

```python
import requests

# 健康检查
response = requests.get('http://localhost:18080/openapi/v1/health')
print(response.json())

# 需要认证的接口
headers = {
    'Authorization': 'Bearer YOUR_TOKEN',
    'Content-Type': 'application/json'
}
data = {'param1': 'value1', 'param2': 'value2'}
response = requests.post(
    'http://localhost:18080/openapi/v1/example',
    headers=headers,
    json=data
)
print(response.json())
```

## 扩展开发

### 添加新接口

1. 在 `controller` 目录下创建或修改控制器类
2. 使用 `@RequestMapping("/openapi/v1/xxx")` 定义路径
3. 使用 `@Operation` 注解添加接口文档说明
4. 返回 `WVPResult` 格式的数据

### 添加新的 DTO

1. 在 `dto` 目录下创建 DTO 类
2. 使用 `@Schema` 注解添加字段说明
3. 实现 `Serializable` 接口

## 注意事项

1. 所有接口都应该有适当的错误处理
2. 敏感操作必须进行认证和授权检查
3. 建议对接口进行限流处理
4. 生产环境建议使用 HTTPS
5. 定期更新 API 文档

## 版本管理

OpenAPI 接口使用版本号管理，当前版本为 `v1`。如果需要进行不兼容的更改，应该创建新版本（如 `v2`），并保持旧版本的兼容性。

## 支持与反馈

如有问题或建议，请联系开发团队。

