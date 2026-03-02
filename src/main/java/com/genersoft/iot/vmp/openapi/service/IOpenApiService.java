package com.genersoft.iot.vmp.openapi.service;

import java.util.Map;

/**
 * OpenAPI 服务接口
 * 用于定义外部接口的业务逻辑
 *
 * @author wvp-pro
 */
public interface IOpenApiService {

    /**
     * 处理示例业务逻辑
     *
     * @param params 请求参数
     * @return 处理结果
     */
    Map<String, Object> processExample(Map<String, Object> params);
}

