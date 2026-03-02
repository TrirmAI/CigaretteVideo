package com.genersoft.iot.vmp.extension.cases.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "案事件证据")
public class CaseEvidence {
    @Schema(description = "ID")
    private String id;
    @Schema(description = "案件ID")
    private String caseId;
    @Schema(description = "录像ID")
    private Integer recordId;
    @Schema(description = "证据类型: video")
    private String type;
    @Schema(description = "证据描述/标注")
    private String description;
    @Schema(description = "创建时间")
    private String createTime;
    @Schema(description = "更新时间")
    private String updateTime;
}