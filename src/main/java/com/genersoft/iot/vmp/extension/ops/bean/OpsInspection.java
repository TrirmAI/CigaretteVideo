package com.genersoft.iot.vmp.extension.ops.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "设备巡检记录")
public class OpsInspection {
    @Schema(description = "ID")
    private String id;
    @Schema(description = "设备ID")
    private String deviceId;
    @Schema(description = "在线状态")
    private Boolean isOnline;
    @Schema(description = "信号强度")
    private Integer signalLevel;
    @Schema(description = "是否有丢帧")
    private Boolean hasFrameLoss;
    @Schema(description = "巡检时间")
    private String inspectTime;
}
