package com.genersoft.iot.vmp.service.impl;

import com.genersoft.iot.vmp.service.ISysOperLogService;
import com.genersoft.iot.vmp.storager.dao.SysOperLogMapper;
import com.genersoft.iot.vmp.storager.dao.dto.SysOperLog;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * 操作日志记录 服务层实现
 */
@Service
public class SysOperLogServiceImpl implements ISysOperLogService
{
    @Autowired
    private SysOperLogMapper operLogMapper;

    /**
     * 新增操作日志
     *
     * @param operLog 操作日志对象
     */
    @Override
    public void insertOperLog(SysOperLog operLog)
    {
        operLogMapper.insertOperLog(operLog);
    }

    /**
     * 查询系统操作日志集合
     *
     * @param operLog 操作日志对象
     * @return 操作日志集合
     */
    @Override
    public List<SysOperLog> selectOperLogList(SysOperLog operLog)
    {
        return operLogMapper.selectOperLogList(operLog);
    }
}
