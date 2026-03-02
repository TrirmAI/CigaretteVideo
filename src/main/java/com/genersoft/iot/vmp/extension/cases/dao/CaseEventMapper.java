package com.genersoft.iot.vmp.extension.cases.dao;

import com.genersoft.iot.vmp.extension.cases.bean.CaseEvent;
import org.apache.ibatis.annotations.*;
import java.util.List;

@Mapper
public interface CaseEventMapper {

    @Insert("INSERT INTO wvp_case_event (id, name, type, time, location, status, description, create_time, update_time) " +
            "VALUES (#{id}, #{name}, #{type}, #{time}, #{location}, #{status}, #{description}, #{createTime}, #{updateTime})")
    int add(CaseEvent caseEvent);

    @Delete("DELETE FROM wvp_case_event WHERE id = #{id}")
    int delete(String id);

    @Update("UPDATE wvp_case_event SET name=#{name}, type=#{type}, time=#{time}, location=#{location}, " +
            "status=#{status}, description=#{description}, update_time=#{updateTime} WHERE id=#{id}")
    int update(CaseEvent caseEvent);

    @Select("SELECT * FROM wvp_case_event WHERE id = #{id}")
    CaseEvent query(String id);

    @Select("SELECT * FROM wvp_case_event ORDER BY create_time DESC")
    List<CaseEvent> queryAll();

    @Select("SELECT COUNT(*) FROM wvp_case_event")
    int count();

    @Select("SELECT type, COUNT(*) as count FROM wvp_case_event GROUP BY type")
    List<java.util.Map<String, Object>> countGroupByType();
}