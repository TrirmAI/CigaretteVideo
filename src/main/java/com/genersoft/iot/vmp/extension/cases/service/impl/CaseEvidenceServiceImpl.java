package com.genersoft.iot.vmp.extension.cases.service.impl;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvidence;
import com.genersoft.iot.vmp.extension.cases.service.CaseEvidenceService;
import com.genersoft.iot.vmp.extension.cases.service.LawEnforcementLogService;
import com.genersoft.iot.vmp.utils.DateUtil;
import com.genersoft.iot.vmp.conf.security.SecurityUtils;
import com.genersoft.iot.vmp.conf.security.dto.LoginUser;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import java.util.stream.Collectors;

@Service
public class CaseEvidenceServiceImpl implements CaseEvidenceService {

    private final Map<String, CaseEvidence> store = new ConcurrentHashMap<>();

    @Autowired
    private LawEnforcementLogService logService;

    @Override
    public CaseEvidence add(CaseEvidence evidence) {
        if (evidence.getId() == null) {
            evidence.setId(UUID.randomUUID().toString());
        }
        evidence.setCreateTime(DateUtil.getNow());
        evidence.setUpdateTime(DateUtil.getNow());
        store.put(evidence.getId(), evidence);
        
        logService.addLog(evidence.getCaseId(), "上传证据", "上传证据ID：" + evidence.getId(), getOperator(), getIp());
        
        return evidence;
    }

    @Override
    public int delete(String id) {
        CaseEvidence evidence = store.get(id);
        int result = store.remove(id) != null ? 1 : 0;
        if (result > 0 && evidence != null) {
            logService.addLog(evidence.getCaseId(), "删除证据", "删除证据ID：" + id, getOperator(), getIp());
        }
        return result;
    }

    @Override
    public int update(CaseEvidence evidence) {
        if (store.containsKey(evidence.getId())) {
            CaseEvidence old = store.get(evidence.getId());
            // Update fields
            old.setDescription(evidence.getDescription());
            old.setUpdateTime(DateUtil.getNow());
            store.put(old.getId(), old);
            
            logService.addLog(old.getCaseId(), "更新证据", "更新证据描述", getOperator(), getIp());
            
            return 1;
        }
        return 0;
    }

    @Override
    public List<CaseEvidence> queryByCaseId(String caseId) {
        return store.values().stream()
                .filter(e -> caseId.equals(e.getCaseId()))
                .collect(Collectors.toList());
    }

    private String getIp() {
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                return attributes.getRequest().getRemoteAddr();
            }
        } catch (Exception e) {}
        return "127.0.0.1";
    }

    private String getOperator() {
        try {
            LoginUser user = SecurityUtils.getUserInfo();
            return user != null ? user.getUsername() : "admin";
        } catch (Exception e) {
            return "admin";
        }
    }
}
