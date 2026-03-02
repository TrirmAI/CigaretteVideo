package com.genersoft.iot.vmp.extension.ai.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "AI模型")
public class AiModel {
    @Schema(description = "ID")
    private String id;
    @Schema(description = "模型名称")
    private String name;
    @Schema(description = "版本")
    private String version;
    @Schema(description = "状态")
    private String status;

    @Schema(description = "创建时间")
    private String createTime;
}
