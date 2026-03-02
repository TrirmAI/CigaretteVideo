package com.genersoft.iot.vmp.extension.cases.controller;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvent;
import com.genersoft.iot.vmp.extension.cases.service.CaseService;
import com.genersoft.iot.vmp.common.annotation.Log;
import com.genersoft.iot.vmp.common.enums.BusinessType;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Tag(name = "案事件管理")
@RestController
@RequestMapping("/api/ext/case")
public class CaseController {

    @Autowired
    private CaseService caseService;

    @Operation(summary = "新增案事件")
    @PostMapping("/add")
    @Log(title = "案事件管理", businessType = BusinessType.INSERT)
    public CaseEvent add(@RequestBody CaseEvent event) {
        return caseService.add(event);
    }

    @Operation(summary = "获取案事件列表")
    @GetMapping("/list")
    public List<CaseEvent> list() {
        return caseService.queryAll();
    }

    @Operation(summary = "更新案事件")
    @PostMapping("/update")
    public int update(@RequestBody CaseEvent event) {
        return caseService.update(event);
    }

    @Operation(summary = "删除案事件")
    @DeleteMapping("/delete")
    @Log(title = "案事件管理", businessType = BusinessType.DELETE)
    public int delete(@RequestParam String id) {
        return caseService.delete(id);
    }
}
