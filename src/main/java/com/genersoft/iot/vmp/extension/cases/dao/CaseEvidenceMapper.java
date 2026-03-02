package com.genersoft.iot.vmp.extension.cases.dao;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvidence;
import org.apache.ibatis.annotations.*;
import java.util.List;

@Mapper
public interface CaseEvidenceMapper {

    @Insert("INSERT INTO wvp_case_evidence (id, case_id, record_id, type, description, create_time, update_time) " +
            "VALUES (#{id}, #{caseId}, #{recordId}, #{type}, #{description}, #{createTime}, #{updateTime})")
    int add(CaseEvidence evidence);

    @Delete("DELETE FROM wvp_case_evidence WHERE id = #{id}")
    int delete(String id);
    
    @Delete("DELETE FROM wvp_case_evidence WHERE case_id = #{caseId}")
    int deleteByCaseId(String caseId);

    @Update("UPDATE wvp_case_evidence SET description=#{description}, update_time=#{updateTime} WHERE id=#{id}")
    int update(CaseEvidence evidence);

    @Select("SELECT * FROM wvp_case_evidence WHERE case_id = #{caseId} ORDER BY create_time DESC")
    List<CaseEvidence> queryByCaseId(String caseId);
    
    @Select("SELECT * FROM wvp_case_evidence WHERE id = #{id}")
    CaseEvidence query(String id);

    @Select("SELECT COUNT(*) FROM wvp_case_evidence")
    int count();
}