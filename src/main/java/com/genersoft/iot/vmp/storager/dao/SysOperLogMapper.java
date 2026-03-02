package com.genersoft.iot.vmp.storager.dao;

import com.genersoft.iot.vmp.storager.dao.dto.SysOperLog;
import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import org.springframework.stereotype.Repository;

import java.util.List;

/**
 * 操作日志记录 数据层
 */
@Mapper
@Repository
public interface SysOperLogMapper
{
    /**
     * 新增操作日志
     *
     * @param operLog 操作日志对象
     */
    @Insert("INSERT INTO sys_oper_log (title, business_type, method, request_method, operator_type, oper_name, oper_url, oper_ip, oper_location, oper_param, json_result, status, error_msg, oper_time) " +
            "VALUES (#{title}, #{businessType}, #{method}, #{requestMethod}, #{operatorType}, #{operName}, #{operUrl}, #{operIp}, #{operLocation}, #{operParam}, #{jsonResult}, #{status}, #{errorMsg}, #{operTime})")
    int insertOperLog(SysOperLog operLog);

    /**
     * 查询系统操作日志集合
     *
     * @param operLog 操作日志对象
     * @return 操作日志集合
     */
    @Select("<script>" +
            "SELECT * FROM sys_oper_log " +
            "WHERE 1=1 " +
            "<if test=\"params.query != null and params.query != ''\">" +
            "AND (title like concat('%', #{params.query}, '%') OR oper_name like concat('%', #{params.query}, '%'))" +
            "</if>" +
            "<if test=\"params.operationType != null and params.operationType != ''\">" +
            "AND title = #{params.operationType}" +
            "</if>" +
            "<if test=\"businessType != null\">AND business_type = #{businessType}</if>" +
            "<if test=\"status != null\">AND status = #{status}</if>" +
            "<if test=\"params.beginTime != null and params.beginTime != ''\"><!-- 开始时间检索 -->" +
            "AND oper_time &gt;= #{params.beginTime}" +
            "</if>" +
            "<if test=\"params.endTime != null and params.endTime != ''\"><!-- 结束时间检索 -->" +
            "AND oper_time &lt;= #{params.endTime}" +
            "</if>" +
            "<if test=\"params.category == 'video'\">" +
            "AND (" +
            "title IN " +
            "<foreach collection='params.videoModules' item='mod' open='(' separator=',' close=')'>" +
            "#{mod}" +
            "</foreach>" +
            ")" +
            "</if>" +
            "<if test=\"params.category == 'system'\">" +
            "AND title IN " +
            "<foreach collection='params.systemModules' item='mod' open='(' separator=',' close=')'>" +
            "#{mod}" +
            "</foreach>" +
            "</if>" +
            "ORDER BY oper_time DESC" +
            "</script>")
    List<SysOperLog> selectOperLogList(SysOperLog operLog);

    @Delete("DELETE FROM sys_oper_log")
    void cleanLog();
}
