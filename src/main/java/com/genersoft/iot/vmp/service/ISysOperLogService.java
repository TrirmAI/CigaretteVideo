package com.genersoft.iot.vmp.service;

import com.genersoft.iot.vmp.storager.dao.dto.SysOperLog;
import java.util.List;

/**
 * 操作日志记录 服务层
 */
public interface ISysOperLogService
{
    /**
     * 新增操作日志
     *
     * @param operLog 操作日志对象
     */
    public void insertOperLog(SysOperLog operLog);

    /**
     * 查询系统操作日志集合
     *
     * @param operLog 操作日志对象
     * @return 操作日志集合
     */
    public List<SysOperLog> selectOperLogList(SysOperLog operLog);
}
