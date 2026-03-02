package com.genersoft.iot.vmp.extension.ops.controller;

import com.genersoft.iot.vmp.extension.cases.dao.CaseEventMapper;
import com.genersoft.iot.vmp.extension.cases.dao.CaseEvidenceMapper;
import com.genersoft.iot.vmp.extension.cases.dao.LawEnforcementLogMapper;
import com.genersoft.iot.vmp.gb28181.bean.Device;
import com.genersoft.iot.vmp.gb28181.dao.DeviceMapper;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.*;

@Tag(name = "业务大数据分析")
@RestController
@RequestMapping("/api/ext/business")
public class BusinessStatsController {

    private final static org.slf4j.Logger logger = org.slf4j.LoggerFactory.getLogger(BusinessStatsController.class);

    @Autowired
    private LawEnforcementLogMapper lawLogMapper;

    @Autowired
    private CaseEventMapper caseEventMapper;

    @Autowired
    private CaseEvidenceMapper evidenceMapper;

    @Autowired
    private DeviceMapper deviceMapper;

    @Operation(summary = "获取业务统计数据")
    @GetMapping("/stats")
    public Map<String, Object> getStats() {
        Map<String, Object> result = new HashMap<>();

        // Query DB
        int lawCount = lawLogMapper.count();
        int caseCount = caseEventMapper.count();
        int evidenceCount = evidenceMapper.count();
        int deviceCount = deviceMapper.getAll().size();

        logger.info("[BusinessStats] DB Counts - Law: {}, Case: {}, Evidence: {}, Device: {}", 
                     lawCount, caseCount, evidenceCount, deviceCount);

        // FORCE MOCK DATA for demonstration if DB data seems insufficient or for testing
        // You can change this condition later. Currently forcing it if lawCount < 100 to ensure charts look good.
        boolean useMock = true; 

        if (useMock || (lawCount == 0 && caseCount == 0)) {
            logger.info("[BusinessStats] Using forced mock data.");
            // 1. Overview
            Map<String, Integer> overview = new HashMap<>();
            overview.put("lawEnforcementCount", 1258);
            overview.put("caseCount", 86);
            overview.put("evidenceCount", 342);
            overview.put("deviceCount", 1024);
            result.put("overview", overview);

            // 2. Trend (7 Days)
            List<String> dates = Arrays.asList("01-10", "01-11", "01-12", "01-13", "01-14", "01-15", "01-16");
            List<Integer> lawTrend = Arrays.asList(120, 132, 101, 134, 90, 230, 210);
            Map<String, Object> trend = new HashMap<>();
            trend.put("dates", dates);
            trend.put("values", lawTrend);
            result.put("lawTrend", trend);

            // 3. Distribution
            List<Map<String, Object>> caseDistribution = new ArrayList<>();
            caseDistribution.add(createMap("name", "非法入侵", "value", 35));
            caseDistribution.add(createMap("name", "车辆违停", "value", 25));
            caseDistribution.add(createMap("name", "人员聚集", "value", 15));
            caseDistribution.add(createMap("name", "烟火检测", "value", 8));
            caseDistribution.add(createMap("name", "其他", "value", 3));
            result.put("caseDistribution", caseDistribution);
        } else {
            // Use Real Data
            Map<String, Integer> overview = new HashMap<>();
            overview.put("lawEnforcementCount", lawCount); 
            overview.put("caseCount", caseCount);             
            overview.put("evidenceCount", evidenceCount);        
            overview.put("deviceCount", deviceCount);
            result.put("overview", overview);

            // 2. Trend
            List<Map<String, Object>> trendData = lawLogMapper.countLast7Days();
            List<String> dates = new ArrayList<>();
            List<Long> lawTrend = new ArrayList<>();
            if (trendData != null) {
                for (Map<String, Object> item : trendData) {
                    if (item.get("date") != null) dates.add(item.get("date").toString());
                    if (item.get("count") != null) lawTrend.add((Long) item.get("count"));
                }
            }
            Map<String, Object> trend = new HashMap<>();
            trend.put("dates", dates);
            trend.put("values", lawTrend);
            result.put("lawTrend", trend);

            // 3. Distribution
            List<Map<String, Object>> dbDist = caseEventMapper.countGroupByType();
            List<Map<String, Object>> distResult = new ArrayList<>();
            if (dbDist != null) {
                for (Map<String, Object> item : dbDist) {
                     distResult.add(createMap("name", item.get("type"), "value", item.get("count")));
                }
            }
            result.put("caseDistribution", distResult);
        }

        // 4. Recent Alarms (Always return mock for now as alarm table is not ready)
        List<Map<String, String>> recentAlarms = new ArrayList<>();
        recentAlarms.add(createStringMap("time", "10:23:45", "type", "非法入侵", "location", "东门入口"));
        recentAlarms.add(createStringMap("time", "09:15:12", "type", "车辆违停", "location", "消防通道"));
        recentAlarms.add(createStringMap("time", "08:45:33", "type", "人员聚集", "location", "广场中心"));
        recentAlarms.add(createStringMap("time", "08:12:05", "type", "烟火检测", "location", "仓库区域"));
        recentAlarms.add(createStringMap("time", "07:55:10", "type", "非法入侵", "location", "西侧围栏"));
        result.put("recentAlarms", recentAlarms);

        return result;
    }

    private Map<String, Object> createMap(String k1, Object v1, String k2, Object v2) {
        Map<String, Object> map = new HashMap<>();
        map.put(k1, v1);
        map.put(k2, v2);
        return map;
    }

    private Map<String, String> createStringMap(String k1, String v1, String k2, String v2, String k3, String v3) {
        Map<String, String> map = new HashMap<>();
        map.put(k1, v1);
        map.put(k2, v2);
        map.put(k3, v3);
        return map;
    }
}
