package com.genersoft.iot.vmp.vmanager.log;

import com.genersoft.iot.vmp.common.constant.LogConstants;
import com.genersoft.iot.vmp.common.enums.BusinessType;
import com.genersoft.iot.vmp.common.enums.OperatorType;
import com.genersoft.iot.vmp.extension.cases.bean.CaseEvent;
import com.genersoft.iot.vmp.extension.cases.service.CaseService;
import com.genersoft.iot.vmp.extension.cases.service.LawEnforcementLogService;
import com.genersoft.iot.vmp.service.ISysOperLogService;
import com.genersoft.iot.vmp.storager.dao.SysOperLogMapper;
import com.genersoft.iot.vmp.extension.cases.dao.LawEnforcementLogMapper;
import com.genersoft.iot.vmp.storager.dao.dto.SysOperLog;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.text.SimpleDateFormat;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Random;
import java.util.UUID;

@Tag(name = "日志模拟")
@RestController
@RequestMapping("/api/log/mock")
public class LogMockController {

    @Autowired
    private ISysOperLogService operLogService;
    
    @Autowired
    private LawEnforcementLogService lawLogService;

    @Autowired
    private CaseService caseService;

    @Autowired
    private SysOperLogMapper sysOperLogMapper;

    @Autowired
    private LawEnforcementLogMapper lawEnforcementLogMapper;

    @Operation(summary = "清空所有日志")
    @PostMapping("/clean")
    public String clean() {
        try {
            sysOperLogMapper.cleanLog();
            lawEnforcementLogMapper.cleanLog();
            return "All logs cleaned successfully.";
        } catch (Exception e) {
            throw new RuntimeException("Clean log failed: " + e.getMessage());
        }
    }

    @Operation(summary = "生成模拟数据")
    @PostMapping("/generate")
    public String generate() {
        // 清空现有数据
        try {
            sysOperLogMapper.cleanLog();
            lawEnforcementLogMapper.cleanLog();
        } catch (Exception e) {
             throw new RuntimeException("Clean log failed: " + e.getMessage());
        }

        Random random = new Random();
        String[] users = {"admin", "police_01", "police_02", "dispatcher", "viewer", "manager", "operator"};
        String[] ips = {"192.168.1.10", "192.168.1.11", "10.0.0.5", "127.0.0.1", "192.168.0.100", "172.16.0.1"};

        // 1. 生成系统日志
        List<String> sysTitles = LogConstants.SYSTEM_MODULES;
        String[] sysMethods = {"com.genersoft.iot.vmp.vmanager.user.UserController.login", "com.genersoft.iot.vmp.vmanager.user.UserController.add", "com.genersoft.iot.vmp.vmanager.role.RoleController.update"};
        
        for (int i = 0; i < 30; i++) {
            SysOperLog log = new SysOperLog();
            log.setTitle(sysTitles.get(random.nextInt(sysTitles.size())));
            log.setBusinessType(random.nextInt(BusinessType.values().length));
            log.setMethod(sysMethods[random.nextInt(sysMethods.length)]);
            log.setRequestMethod(random.nextBoolean() ? "POST" : "GET");
            log.setOperatorType(OperatorType.MANAGE.ordinal());
            log.setOperName(users[random.nextInt(users.length)]);
            log.setOperUrl("/api/sys/" + i);
            log.setOperIp(ips[random.nextInt(ips.length)]);
            log.setOperLocation("Internal Network");
            log.setOperParam("{\"id\": " + i + "}");
            
            // 模拟部分失败
            if (random.nextInt(100) < 5) {
                log.setStatus(1);
                log.setErrorMsg("模拟系统异常: 连接超时");
                log.setJsonResult(null);
            } else {
                log.setStatus(0);
                log.setJsonResult("{\"code\": 0, \"msg\": \"success\"}");
            }
            
            log.setOperTime(new Date(System.currentTimeMillis() - random.nextInt(86400000 * 7))); // 最近7天
            operLogService.insertOperLog(log);
        }

        // 2. 生成视频日志 (确保覆盖所有类型)
        List<String> videoTitles = LogConstants.VIDEO_MODULES;
        String[] videoMethods = {"com.genersoft.iot.vmp.gb28181.controller.PlayController.play", "com.genersoft.iot.vmp.gb28181.controller.DeviceControlController.ptz", "com.genersoft.iot.vmp.gb28181.controller.DeviceQueryController.query"};
        
        // 遍历每种视频操作类型，每种生成 5-8 条数据
        for (String title : videoTitles) {
            int count = 5 + random.nextInt(4); // 5-8条
            for (int i = 0; i < count; i++) {
                SysOperLog log = new SysOperLog();
                log.setTitle(title);
                log.setBusinessType(random.nextInt(BusinessType.values().length));
                log.setMethod(videoMethods[random.nextInt(videoMethods.length)]);
                log.setRequestMethod("POST");
                log.setOperatorType(OperatorType.MANAGE.ordinal());
                log.setOperName(users[random.nextInt(users.length)]);
                log.setOperUrl("/api/video/" + UUID.randomUUID().toString().substring(0, 8));
                log.setOperIp(ips[random.nextInt(ips.length)]);
                log.setOperLocation("Internal Network");
                
                // 根据类型生成简单的模拟参数
                if (title.contains("云台")) {
                    log.setOperParam("{\"deviceId\": \"34020000001320000001\", \"cmd\": \"left\", \"speed\": 128}");
                } else if (title.contains("回放")) {
                    log.setOperParam("{\"deviceId\": \"34020000001320000001\", \"startTime\": \"2023-10-01 12:00:00\"}");
                } else {
                    log.setOperParam("{\"deviceId\": \"34020000001320000001\"}");
                }
                
                 // 模拟部分失败
                if (random.nextInt(100) < 5) {
                    log.setStatus(1);
                    log.setErrorMsg("设备离线或网络不可达");
                    log.setJsonResult(null);
                } else {
                    log.setStatus(0);
                    log.setJsonResult("{\"code\": 0, \"msg\": \"success\"}");
                }
                
                log.setOperTime(new Date(System.currentTimeMillis() - random.nextInt(86400000 * 7)));
                operLogService.insertOperLog(log);
            }
        }

        // 3. 生成案件并生成执法日志
        List<String> caseIds = new ArrayList<>();
        List<CaseEvent> existingCases = caseService.queryAll();
        if (existingCases != null && !existingCases.isEmpty()) {
            for (CaseEvent c : existingCases) {
                caseIds.add(c.getId());
            }
        } else {
            // 生成模拟案件
            String[] caseTypes = {"盗窃案", "交通肇事", "寻衅滋事", "网络诈骗"};
            SimpleDateFormat sdf = new SimpleDateFormat("yyyy-MM-dd HH:mm:ss");
            for (int i = 0; i < 5; i++) {
                CaseEvent event = new CaseEvent();
                event.setId("CASE_" + System.currentTimeMillis() + "_" + i);
                event.setName("模拟" + caseTypes[random.nextInt(caseTypes.length)] + "_" + i);
                event.setType(caseTypes[random.nextInt(caseTypes.length)]);
                event.setTime(sdf.format(new Date()));
                event.setLocation("模拟地点_" + i);
                event.setStatus(1);
                event.setDescription("系统自动生成的模拟案件");
                caseService.add(event);
                caseIds.add(event.getId());
            }
        }

        // 针对这些案件生成日志
        String[] lawOps = {"上传现场照片", "笔录录入", "视频分析", "轨迹追踪", "出警记录", "执法仪视频关联", "结案报告", "卷宗封存"};
        
        for (int i = 0; i < 30; i++) {
            String caseId = caseIds.get(random.nextInt(caseIds.size()));
            String opType = lawOps[random.nextInt(lawOps.length)];
            String details = "用户 " + users[random.nextInt(users.length)] + " 对案件 " + caseId + " 执行了 " + opType + " 操作";
            String operator = users[random.nextInt(users.length)];
            String ip = ips[random.nextInt(ips.length)];
            
            lawLogService.addLog(caseId, opType, details, operator, ip);
        }
        
        return "Generated mock logs based on LogConstants: 30 System, 30 Video, 30 Law Enforcement.";
    }
}
