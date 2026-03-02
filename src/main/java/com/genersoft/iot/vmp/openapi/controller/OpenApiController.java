package com.genersoft.iot.vmp.openapi.controller;

import com.genersoft.iot.vmp.conf.security.JwtUtils;
import com.genersoft.iot.vmp.openapi.dto.ApiResponse;
import com.genersoft.iot.vmp.openapi.service.IOpenApiService;
import com.genersoft.iot.vmp.vmanager.bean.WVPResult;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

/**
 * OpenAPI 控制器
 * 用于外部应用系统调用
 *
 * @author wvp-pro
 */
@Tag(name = "OpenAPI - 外部接口")
@RestController
@Slf4j
@RequestMapping(value = "/openapi/v1")
public class OpenApiController {

    @Autowired
    private IOpenApiService openApiService;

    /**
     * 健康检查接口
     *
     * @return 系统状态
     */
    @Operation(summary = "健康检查", description = "检查系统是否正常运行")
    @GetMapping("/health")
    public WVPResult<Map<String, Object>> health() {
        Map<String, Object> data = new HashMap<>();
        data.put("status", "UP");
        data.put("timestamp", LocalDateTime.now());
        data.put("service", "wvp-pro");
        return WVPResult.success(data, "系统运行正常");
    }

    /**
     * 获取系统信息
     *
     * @return 系统信息
     */
    @Operation(summary = "获取系统信息", description = "获取系统基本信息")
    @GetMapping("/system/info")
    public WVPResult<Map<String, Object>> getSystemInfo() {
        Map<String, Object> data = new HashMap<>();
        data.put("version", "2.7.4");
        data.put("name", "wvp-pro");
        data.put("description", "国标28181视频平台");
        return WVPResult.success(data);
    }

    /**
     * 示例接口 - 需要认证
     *
     * @param param 参数
     * @return 响应结果
     */
    @Operation(
            summary = "示例接口",
            description = "这是一个需要认证的示例接口",
            security = @SecurityRequirement(name = JwtUtils.HEADER)
    )
    @PostMapping("/example")
    public WVPResult<ApiResponse> example(
            @Parameter(description = "请求参数", required = true)
            @RequestBody Map<String, Object> param) {
        // 调用服务层处理业务逻辑
        Map<String, Object> processedData = openApiService.processExample(param);
        
        ApiResponse response = new ApiResponse();
        response.setMessage("请求成功");
        response.setData(processedData);
        return WVPResult.success(response);
    }
}

