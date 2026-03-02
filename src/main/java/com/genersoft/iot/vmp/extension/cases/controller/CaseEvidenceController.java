package com.genersoft.iot.vmp.extension.cases.controller;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvidence;
import com.genersoft.iot.vmp.extension.cases.service.CaseEvidenceService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@Tag(name = "案事件证据管理")
@RestController
@RequestMapping("/api/ext/case/evidence")
public class CaseEvidenceController {

    @Autowired
    private CaseEvidenceService caseEvidenceService;

    @Operation(summary = "添加证据")
    @PostMapping("/add")
    public CaseEvidence add(@RequestBody CaseEvidence evidence) {
        return caseEvidenceService.add(evidence);
    }

    @Operation(summary = "删除证据")
    @DeleteMapping("/delete")
    public int delete(@RequestParam String id) {
        return caseEvidenceService.delete(id);
    }

    @Operation(summary = "更新证据(标注)")
    @PostMapping("/update")
    public int update(@RequestBody CaseEvidence evidence) {
        return caseEvidenceService.update(evidence);
    }

    @Operation(summary = "根据案件ID查询证据")
    @GetMapping("/list")
    public List<CaseEvidence> list(@RequestParam String caseId) {
        return caseEvidenceService.queryByCaseId(caseId);
    }
}