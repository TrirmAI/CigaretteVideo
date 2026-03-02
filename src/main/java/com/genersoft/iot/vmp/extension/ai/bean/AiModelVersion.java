package com.genersoft.iot.vmp.extension.ai.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "AI模型版本")
public class AiModelVersion {
    @Schema(description = "ID")
    private String id;
    
    @Schema(description = "模型ID")
    private String modelId;
    
    @Schema(description = "版本号")
    private String version;
    
    @Schema(description = "状态: training/completed/failed")
    private String status;
    
    @Schema(description = "创建时间")
    private String createTime;
    
    @Schema(description = "完成时间")
    private String finishTime;
    
    @Schema(description = "准确率")
    private Double accuracy;
    
    @Schema(description = "损失率")
    private Double loss;
    
    @Schema(description = "模型文件路径")
    private String filePath;
}
