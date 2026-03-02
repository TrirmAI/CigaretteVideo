package com.genersoft.iot.vmp.extension.cases.service;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvent;
import java.util.List;

public interface CaseService {
    CaseEvent add(CaseEvent event);
    List<CaseEvent> queryAll();
    CaseEvent query(String id);
    int delete(String id);
    int update(CaseEvent event);
}
