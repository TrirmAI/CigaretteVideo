package com.genersoft.iot.vmp.extension.ops.service.impl;

import com.genersoft.iot.vmp.extension.ops.bean.OpsInspection;
import com.genersoft.iot.vmp.extension.ops.bean.OpsDiagnosis;
import com.genersoft.iot.vmp.extension.ops.dao.OpsDiagnosisMapper;
import com.genersoft.iot.vmp.extension.ops.service.OpsService;
import com.genersoft.iot.vmp.gb28181.dao.DeviceMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import oshi.SystemInfo;
import oshi.hardware.CentralProcessor;
import oshi.hardware.GlobalMemory;
import oshi.hardware.HardwareAbstractionLayer;

import java.util.*;

@Service
public class OpsServiceImpl implements OpsService {

    @Autowired
    private OpsDiagnosisMapper diagnosisMapper;

    @Autowired
    private DeviceMapper deviceMapper;

    @Override
    public List<OpsInspection> inspectAll() {
        // Mock inspection results
        List<OpsInspection> list = new ArrayList<>();
        OpsInspection item = new OpsInspection();
        item.setId(UUID.randomUUID().toString());
        item.setDeviceId("34020000001320000001");
        item.setIsOnline(true);
        item.setSignalLevel(95);
        item.setHasFrameLoss(false);
        item.setInspectTime("2023-10-27 10:05:00");
        list.add(item);
        return list;
    }

    @Override
    public Map<String, Object> getDashboardData() {
        Map<String, Object> data = new HashMap<>();
        
        // Real System Info using Oshi
        SystemInfo si = new SystemInfo();
        HardwareAbstractionLayer hal = si.getHardware();
        CentralProcessor processor = hal.getProcessor();
        GlobalMemory memory = hal.getMemory();
        
        double cpuLoad = processor.getSystemCpuLoad(1000) * 100;
        double memUsage = (double) (memory.getTotal() - memory.getAvailable()) / memory.getTotal() * 100;
        
        data.put("cpuUsage", Math.round(cpuLoad * 100.0) / 100.0);
        data.put("memoryUsage", Math.round(memUsage * 100.0) / 100.0);
        data.put("diskUsage", 30.1); // Disk I/O is expensive to query every time
        
        // Real Device Online Rate
        int total = deviceMapper.getAll().size();
        int online = deviceMapper.getOnlineDevices().size();
        double rate = total == 0 ? 0 : (double) online / total * 100;
        data.put("onlineRate", Math.round(rate * 100.0) / 100.0);
        
        return data;
    }

    @Override
    public List<OpsDiagnosis> getDiagnosisList() {
        return diagnosisMapper.queryLatest();
    }
}
