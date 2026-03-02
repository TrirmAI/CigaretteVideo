package com.genersoft.iot.vmp.extension.cases.service;

import com.genersoft.iot.vmp.extension.cases.bean.LawEnforcementLog;
import com.github.pagehelper.PageInfo;

import java.util.List;

public interface LawEnforcementLogService {

    void addLog(String caseId, String operationType, String details);

    void addLog(String caseId, String operationType, String details, String operator, String ip);

    List<LawEnforcementLog> getLogsByCaseId(String caseId);

    PageInfo<LawEnforcementLog> getLogs(int page, int count, String caseId, String query, String startTime, String endTime);
}
