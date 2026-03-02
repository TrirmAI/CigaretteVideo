package com.genersoft.iot.vmp.extension.cases.controller;

import com.genersoft.iot.vmp.extension.cases.bean.LawEnforcementLog;
import com.genersoft.iot.vmp.extension.cases.service.LawEnforcementLogService;
import com.github.pagehelper.PageInfo;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@Tag(name = "执法操作日志")
@RestController
@RequestMapping("/api/ext/law-log")
public class LawEnforcementLogController {

    @Autowired
    private LawEnforcementLogService logService;

    @Operation(summary = "查询案件的操作日志")
    @GetMapping("/case-list")
    public List<LawEnforcementLog> list(@RequestParam String caseId) {
        return logService.getLogsByCaseId(caseId);
    }

    @Operation(summary = "分页查询执法日志")
    @GetMapping("/list")
    @Parameter(name = "query", description = "关键字(操作人/类型)", required = false)
    @Parameter(name = "caseId", description = "案件ID", required = false)
    @Parameter(name = "startTime", description = "开始时间(yyyy-MM-dd HH:mm:ss)", required = false)
    @Parameter(name = "endTime", description = "结束时间(yyyy-MM-dd HH:mm:ss)", required = false)
    @Parameter(name = "page", description = "当前页", required = true)
    @Parameter(name = "count", description = "每页数量", required = true)
    public PageInfo<LawEnforcementLog> getList(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) String caseId,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam int page,
            @RequestParam int count
    ) {
        return logService.getLogs(page, count, caseId, query, startTime, endTime);
    }
}
