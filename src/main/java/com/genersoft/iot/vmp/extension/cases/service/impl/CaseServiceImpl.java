package com.genersoft.iot.vmp.extension.cases.service.impl;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvent;
import com.genersoft.iot.vmp.extension.cases.bean.LawEnforcementLog;
import com.genersoft.iot.vmp.extension.cases.service.CaseService;
import com.genersoft.iot.vmp.extension.cases.service.LawEnforcementLogService;
import com.genersoft.iot.vmp.utils.DateUtil;
import com.genersoft.iot.vmp.conf.security.SecurityUtils;
import com.genersoft.iot.vmp.conf.security.dto.LoginUser;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.context.request.RequestContextHolder;
import org.springframework.web.context.request.ServletRequestAttributes;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class CaseServiceImpl implements CaseService {

    private final Map<String, CaseEvent> store = new ConcurrentHashMap<>();

    @Autowired
    private LawEnforcementLogService logService;

    @PostConstruct
    public void init() {
        // Mock Data - Align with frontend Workbench.vue IDs (1001, 1002, 1003)
        addMockCase("1001", "非法运输卷烟案-车牌号京A88888", "非法运输", "2023-10-27 09:30:00", "高速收费站出口", 1, "拦截一辆疑似运输假冒伪劣卷烟的厢式货车，现场查获违规卷烟 50 箱。");
        // 为 1001 添加更多详细模拟日志
        List<LawEnforcementLog> logs = logService.getLogsByCaseId("1001");
        if (logs.size() <= 1) {
            logService.addLog("1001", "现场取证", "上传现场照片 evidence_001.jpg", "police_li", "192.168.1.105");
            logService.addLog("1001", "笔录录入", "录入当事人王某口供", "police_li", "192.168.1.105");
        }
        
        addMockCase("1002", "无证经营烟草制品案-便民超市", "无证经营", "2023-10-26 14:15:00", "幸福路12号", 2, "接到群众举报，对某超市进行突击检查，发现其未持有烟草专卖零售许可证销售卷烟。");
        addMockCase("1003", "销售假冒注册商标卷烟案", "售假", "2023-10-25 10:00:00", "中心市场批发部", 3, "例行巡查发现某批发部存在销售假烟嫌疑。");
    }

    private void addMockCase(String id, String name, String type, String time, String location, int status, String desc) {
        CaseEvent event = new CaseEvent();
        event.setId(id);
        event.setName(name);
        event.setType(type);
        event.setTime(time);
        event.setLocation(location);
        event.setStatus(status);
        event.setDescription(desc);
        event.setCreateTime(DateUtil.getNow());
        event.setUpdateTime(DateUtil.getNow());
        store.put(id, event);
        
        // Mock Initial Log if not exists
        List<LawEnforcementLog> existingLogs = logService.getLogsByCaseId(id);
        if (existingLogs == null || existingLogs.isEmpty()) {
            logService.addLog(id, "案件创建", "自动接入案件：" + name, "system_monitor", "127.0.0.1");
            
            if (status >= 2) {
                 logService.addLog(id, "状态流转", "案件状态变更为：研判中", "dispatcher", "192.168.1.200");
            }
            if (status >= 3) {
                 logService.addLog(id, "案件处置", "下发处置指令", "commander", "192.168.1.201");
            }
        }
    }

    @Override
    public CaseEvent add(CaseEvent event) {
        if (event.getId() == null) {
            event.setId(UUID.randomUUID().toString());
        }
        event.setCreateTime(DateUtil.getNow());
        event.setUpdateTime(DateUtil.getNow());
        store.put(event.getId(), event);
        
        logService.addLog(event.getId(), "创建案件", "创建新案件：" + event.getName(), getOperator(), getIp());
        
        return event;
    }

    @Override
    public int delete(String id) {
        int result = store.remove(id) != null ? 1 : 0;
        if (result > 0) {
            logService.addLog(id, "删除案件", "删除案件ID：" + id, getOperator(), getIp());
        }
        return result;
    }

    @Override
    public int update(CaseEvent event) {
        if (store.containsKey(event.getId())) {
            event.setUpdateTime(DateUtil.getNow());
            store.put(event.getId(), event);
            
            logService.addLog(event.getId(), "更新案件", "更新案件信息", getOperator(), getIp());
            
            return 1;
        }
        return 0;
    }

    @Override
    public CaseEvent query(String id) {
        return store.get(id);
    }

    @Override
    public List<CaseEvent> queryAll() {
        return new ArrayList<>(store.values());
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
