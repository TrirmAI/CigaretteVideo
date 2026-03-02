package com.genersoft.iot.vmp.openapi.dto;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

import java.io.Serializable;

/**
 * API 响应数据传输对象
 *
 * @author wvp-pro
 */
@Data
@Schema(description = "API响应数据")
public class ApiResponse implements Serializable {

    private static final long serialVersionUID = 1L;

    @Schema(description = "响应消息")
    private String message;

    @Schema(description = "响应数据")
    private Object data;

    @Schema(description = "时间戳")
    private Long timestamp;

    public ApiResponse() {
        this.timestamp = System.currentTimeMillis();
    }

    public ApiResponse(String message, Object data) {
        this.message = message;
        this.data = data;
        this.timestamp = System.currentTimeMillis();
    }
}

