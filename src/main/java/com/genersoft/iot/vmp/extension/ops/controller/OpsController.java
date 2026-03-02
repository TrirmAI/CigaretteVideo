package com.genersoft.iot.vmp.extension.ops.controller;

import com.genersoft.iot.vmp.extension.ops.bean.OpsInspection;
import com.genersoft.iot.vmp.extension.ops.service.OpsService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@Tag(name = "运维监控")
@RestController
@RequestMapping("/api/ext/ops")
public class OpsController {

    @Autowired
    private OpsService opsService;

    @Operation(summary = "执行设备巡检")
    @PostMapping("/inspect")
    public List<OpsInspection> inspect() {
        return opsService.inspectAll();
    }

    @Operation(summary = "获取运维大盘数据")
    @GetMapping("/dashboard")
    public Map<String, Object> getDashboard() {
        return opsService.getDashboardData();
    }

    @Operation(summary = "获取视频质量诊断列表")
    @GetMapping("/diagnosis/list")
    public List<com.genersoft.iot.vmp.extension.ops.bean.OpsDiagnosis> getDiagnosisList() {
        return opsService.getDiagnosisList();
    }
}
