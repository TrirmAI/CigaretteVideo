package com.genersoft.iot.vmp.extension.cases.service;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvidence;
import java.util.List;

public interface CaseEvidenceService {
    CaseEvidence add(CaseEvidence evidence);
    int delete(String id);
    int update(CaseEvidence evidence);
    List<CaseEvidence> queryByCaseId(String caseId);
}