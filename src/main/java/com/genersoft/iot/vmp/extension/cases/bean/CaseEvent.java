package com.genersoft.iot.vmp.extension.cases.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import lombok.Data;

@Data
@Schema(description = "案事件信息")
public class CaseEvent {
    @Schema(description = "ID")
    private String id;
    @Schema(description = "事件名称")
    private String name;
    @Schema(description = "事件类型")
    private String type;
    @Schema(description = "发生时间")
    private String time;
    @Schema(description = "发生地点")
    private String location;
    @Schema(description = "状态: 1-受理, 2-研判, 3-处置, 4-归档")
    private Integer status;
    @Schema(description = "描述")
    private String description;
    @Schema(description = "创建时间")
    private String createTime;
    @Schema(description = "更新时间")
    private String updateTime;
}
