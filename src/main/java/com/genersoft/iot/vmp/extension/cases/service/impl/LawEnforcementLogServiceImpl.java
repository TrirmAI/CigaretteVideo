package com.genersoft.iot.vmp.extension.cases.service.impl;

import com.genersoft.iot.vmp.conf.security.SecurityUtils;
import com.genersoft.iot.vmp.conf.security.dto.LoginUser;
import com.genersoft.iot.vmp.extension.cases.bean.LawEnforcementLog;
import com.genersoft.iot.vmp.extension.cases.dao.LawEnforcementLogMapper;
import com.genersoft.iot.vmp.extension.cases.service.LawEnforcementLogService;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.util.Date;
import java.util.List;

import java.util.UUID;

@Service
public class LawEnforcementLogServiceImpl implements LawEnforcementLogService {

    @Autowired
    private LawEnforcementLogMapper logMapper;

    @Override
    public void addLog(String caseId, String operationType, String details) {
        String operator = "unknown";
        String ip = "unknown";
        
        // 获取当前用户
        try {
            LoginUser userInfo = SecurityUtils.getUserInfo();
            if (userInfo != null) {
                operator = userInfo.getUsername();
            } else {
                operator = "system";
            }
        } catch (Exception e) {
            // ignore
        }

        // 获取IP
        try {
            ServletRequestAttributes attributes = (ServletRequestAttributes) RequestContextHolder.getRequestAttributes();
            if (attributes != null) {
                ip = attributes.getRequest().getRemoteAddr();
            }
        } catch (Exception e) {
            // ignore
        }
        
        addLog(caseId, operationType, details, operator, ip);
    }

    @Override
    public void addLog(String caseId, String operationType, String details, String operator, String ip) {
        LawEnforcementLog log = new LawEnforcementLog();
        log.setId(UUID.randomUUID().toString());
        log.setCaseId(caseId);
        log.setOperationType(operationType);
        log.setDetails(details);
        log.setOperator(operator);
        log.setIpAddress(ip);
        log.setOperationTime(new Date());

        // 区块链存证逻辑
        LawEnforcementLog lastLog = logMapper.selectLastLog(caseId);
        String previousHash = (lastLog != null) ? lastLog.getBlockHash() : "0000000000000000000000000000000000000000000000000000000000000000";
        log.setPreviousHash(previousHash);
        
        String rawData = previousHash + caseId + operationType + log.getOperator() + log.getOperationTime().getTime() + details;
        log.setBlockHash(calculateSHA256(rawData));

        logMapper.insert(log);
    }

    @Override
    public List<LawEnforcementLog> getLogsByCaseId(String caseId) {
        return logMapper.selectByCaseId(caseId);
    }

    @Override
    public PageInfo<LawEnforcementLog> getLogs(int page, int count, String caseId, String query, String startTime, String endTime) {
        PageHelper.startPage(page, count);
        List<LawEnforcementLog> list = logMapper.selectLogs(caseId, query, startTime, endTime);
        return new PageInfo<>(list);
    }

    private String calculateSHA256(String data) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(data.getBytes(StandardCharsets.UTF_8));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (NoSuchAlgorithmException e) {
            throw new RuntimeException("SHA-256 algorithm not found", e);
        }
    }
}
