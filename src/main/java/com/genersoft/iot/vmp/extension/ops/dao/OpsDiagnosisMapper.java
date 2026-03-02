package com.genersoft.iot.vmp.extension.ops.dao;

import com.genersoft.iot.vmp.extension.ops.bean.OpsDiagnosis;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper
public interface OpsDiagnosisMapper {

    @Select("SELECT * FROM wvp_ops_diagnosis ORDER BY time DESC LIMIT 20")
    List<OpsDiagnosis> queryLatest();
}
