package com.genersoft.iot.vmp.extension.ops.service;

import com.genersoft.iot.vmp.extension.ops.bean.OpsInspection;
import com.genersoft.iot.vmp.extension.ops.bean.OpsDiagnosis;
import java.util.List;
import java.util.Map;

public interface OpsService {
    List<OpsInspection> inspectAll();
    Map<String, Object> getDashboardData();
    List<OpsDiagnosis> getDiagnosisList();
}
