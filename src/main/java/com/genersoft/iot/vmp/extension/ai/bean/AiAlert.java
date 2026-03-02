package com.genersoft.iot.vmp.extension.ai.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "智能告警")
public class AiAlert {
    @Schema(description = "ID")
    private String id;
    @Schema(description = "告警类型")
    private String type;
    @Schema(description = "置信度")
    private Double confidence;
    @Schema(description = "时间")
    private String time;
    @Schema(description = "快照URL")
    private String snapshotUrl;
    @Schema(description = "关联设备ID")
    private String deviceId;
    @Schema(description = "国标编码")
    private String gbId;
    @Schema(description = "视频地址")
    private String videoUrl;
}
