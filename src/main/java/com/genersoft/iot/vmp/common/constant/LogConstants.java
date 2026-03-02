package com.genersoft.iot.vmp.common.constant;

import java.util.Arrays;
import java.util.List;

/**
 * 日志模块常量定义
 * 用于统一管理系统日志与视频日志的分类标准
 */
public class LogConstants {

    /**
     * 系统管理类模块
     */
    public static final List<String> SYSTEM_MODULES = Arrays.asList(
            "用户登录",
            "用户管理",
            "角色管理",
            "菜单管理",
            "部门管理",
            "系统配置",
            "字典管理",
            "定时任务",
            "服务监控"
    );

    /**
     * 视频/业务类模块
     */
    public static final List<String> VIDEO_MODULES = Arrays.asList(
            "视频点播",
            "录像回放",
            "云台控制",
            "设备查询",
            "流媒体分发",
            "设备录像下载",
            "语音对讲",
            "报警查询"
    );
}
