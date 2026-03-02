package com.genersoft.iot.vmp.extension.cases.dao;

import com.genersoft.iot.vmp.extension.cases.bean.LawEnforcementLog;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.springframework.stereotype.Repository;

import java.util.List;

@Mapper
@Repository
public interface LawEnforcementLogMapper {

    @Insert("INSERT INTO wvp_law_enforcement_log (id, case_id, operation_type, operator, operation_time, ip_address, details, block_hash, previous_hash) " +
            "VALUES (#{id}, #{caseId}, #{operationType}, #{operator}, #{operationTime}, #{ipAddress}, #{details}, #{blockHash}, #{previousHash})")
    int insert(LawEnforcementLog log);

    @Select("<script>" +
            "SELECT * FROM wvp_law_enforcement_log WHERE 1=1 " +
            "<if test='caseId != null and caseId != \"\"'> AND case_id = #{caseId} </if>" +
            "<if test='query != null and query != \"\"'> AND (operator LIKE CONCAT('%', #{query}, '%') OR operation_type LIKE CONCAT('%', #{query}, '%')) </if>" +
            "<if test='startTime != null and startTime != \"\"'> AND operation_time &gt;= #{startTime} </if>" +
            "<if test='endTime != null and endTime != \"\"'> AND operation_time &lt;= #{endTime} </if>" +
            "ORDER BY operation_time DESC" +
            "</script>")
    List<LawEnforcementLog> selectLogs(String caseId, String query, String startTime, String endTime);

    @Select("SELECT * FROM wvp_law_enforcement_log WHERE case_id = #{caseId} ORDER BY operation_time DESC")
    List<LawEnforcementLog> selectByCaseId(String caseId);

    @Select("SELECT * FROM wvp_law_enforcement_log WHERE case_id = #{caseId} ORDER BY operation_time DESC LIMIT 1")
    LawEnforcementLog selectLastLog(String caseId);

    @Delete("DELETE FROM wvp_law_enforcement_log")
    void cleanLog();

    @Select("SELECT COUNT(*) FROM wvp_law_enforcement_log")
    int count();

    @Select("SELECT DATE_FORMAT(operation_time, '%m-%d') as date, COUNT(*) as count FROM wvp_law_enforcement_log WHERE operation_time >= DATE_SUB(NOW(), INTERVAL 7 DAY) GROUP BY DATE_FORMAT(operation_time, '%m-%d') ORDER BY date ASC")
    List<java.util.Map<String, Object>> countLast7Days();
}
