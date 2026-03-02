package com.genersoft.iot.vmp.vmanager.log;

import com.genersoft.iot.vmp.common.constant.LogConstants;
import com.genersoft.iot.vmp.conf.exception.ControllerException;
import com.genersoft.iot.vmp.conf.security.JwtUtils;
import com.genersoft.iot.vmp.service.ILogService;
import com.genersoft.iot.vmp.service.bean.LogFileInfo;
import com.genersoft.iot.vmp.vmanager.bean.ErrorCode;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.compress.utils.IOUtils;
import org.apache.commons.lang3.ObjectUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.ServletOutputStream;
import jakarta.servlet.http.HttpServletResponse;
import java.io.File;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.util.List;

import com.genersoft.iot.vmp.service.ISysOperLogService;
import com.genersoft.iot.vmp.storager.dao.dto.SysOperLog;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;

@SuppressWarnings("rawtypes")
@Tag(name = "日志文件查询接口")
@Slf4j
@RestController
@RequestMapping("/api/log")
public class LogController {

    @Autowired
    private ILogService logService;

    @Autowired
    private ISysOperLogService sysOperLogService;


    @ResponseBody
    @GetMapping("/all")
    @Operation(summary = "分页查询业务操作日志", security = @SecurityRequirement(name = JwtUtils.HEADER))
    @Parameter(name = "query", description = "关键字(标题/操作人)", required = false)
    @Parameter(name = "type", description = "业务类型", required = false)
    @Parameter(name = "operationType", description = "操作类型(精确匹配)", required = false)
    @Parameter(name = "category", description = "分类(system/video)", required = false)
    @Parameter(name = "startTime", description = "开始时间(yyyy-MM-dd HH:mm:ss)", required = false)
    @Parameter(name = "endTime", description = "结束时间(yyyy-MM-dd HH:mm:ss)", required = false)
    @Parameter(name = "page", description = "当前页", required = true)
    @Parameter(name = "count", description = "每页数量", required = true)
    public PageInfo<SysOperLog> getAllLogs(
            @RequestParam(required = false) String query,
            @RequestParam(required = false) Integer type,
            @RequestParam(required = false) String operationType,
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime,
            @RequestParam int page,
            @RequestParam int count
    ) {
        SysOperLog operLog = new SysOperLog();
        if (!ObjectUtils.isEmpty(query)) {
            // 将 query 放入 params 中，由 Mapper 自行决定是匹配 title 还是 operName
            operLog.getParams().put("query", query);
        }
        if (type != null) {
            operLog.setBusinessType(type);
        }
        if (!ObjectUtils.isEmpty(operationType)) {
            operLog.getParams().put("operationType", operationType);
        }
        
        // 处理分类逻辑：将 LogConstants 中的模块列表传递给 Mapper
        if (!ObjectUtils.isEmpty(category)) {
            operLog.getParams().put("category", category);
            if ("video".equals(category)) {
                // 如果用户已经指定了精确的操作类型 (operationType)，则不需要再传 videoModules 列表
                // 因为 operationType 本身就是 videoModules 中的一个子集，传了反而增加 SQL 复杂度（虽然逻辑正确）
                // 更重要的是，如果 operationType 存在，SQL 已经是 title = #{operationType}
                // 再加上 title IN (...) 是多余的。
                // 但是，为了安全起见（防止有人传 operationType='非视频操作' 但 category='video'），
                // 还是保留 IN 列表校验比较好？
                // 不过用户反馈说“现在筛选视频日志时显示了所有视频日志”，这意味着筛选条件失效了？
                // 检查 Mapper XML:
                // AND title = #{params.operationType}
                // AND (title IN (...))
                // 如果这两个条件都生效，结果应该是交集（即只有该类型的日志）。
                // 为什么会显示“所有”？
                // 难道 params.operationType 为空？
                // 前端传参：operationType: this.logCategory === 'video' ? this.videoOpType : undefined
                // 如果没选下拉框，this.videoOpType 是 '' (空字符串) 吗？
                // 前端定义：videoOpType: ''
                // 如果是空字符串，Controller 中 !ObjectUtils.isEmpty(operationType) 会判为 false 吗？
                // ObjectUtils.isEmpty("") -> true.
                // 所以如果没选，params.operationType 不会设置。
                // 此时 SQL: AND (title IN (...)) -> 显示所有视频日志。这是正确的。
                
                // 用户说“筛选视频日志时显示了所有视频日志”，意思应该是：他选了“报警查询”，但结果列表里依然有“流媒体分发”、“语音对讲”等。
                // 这说明 AND title = #{params.operationType} 没有生效，或者被忽略了。
                
                // 检查 Mapper XML 中的 <if> 标签：
                // <if test="params.operationType != null and params.operationType != ''">
                // 这里的 params 是 operLog.getParams()。
                // Controller 中：operLog.getParams().put("operationType", operationType);
                // 只有当 operationType 非空时才 put。
                
                // 难道是前端传递问题？前端传的是 query param，还是 body？是 GET 请求 query param。
                // @RequestParam(required = false) String operationType
                
                // 让我们看看用户截图（如果有的话），或者推测：
                // 如果用户选了“报警查询”，前端发出的请求 URL 应该是 ...&operationType=报警查询
                // 如果后端收到了，就会加上 AND title = '报警查询'。
                // 结果肯定只有报警查询。
                
                // 唯一一种显示“所有”的情况是：operationType 参数丢失，或者为空。
                // 或者，Mapper 中的 SQL 逻辑有 OR 关系导致短路？
                // WHERE 1=1
                // <if query> ... </if>
                // <if operationType> AND title = ... </if>
                // <if category='video'> AND (title IN (...)) </if>
                // 全是 AND。
                
                // 除非... operationType 根本没传进来。
                
                // 另一种可能：前端代码中，videoOpType 的值绑定有问题？
                // <el-select v-model="videoOpType" ...>
                //   <el-option label="报警查询" value="报警查询" />
                // handleSearch: operationType: this.logCategory === 'video' ? this.videoOpType : undefined
                
                // 还有一种可能：MyBatis 的缓存？不应该。
                
                // 让我们再仔细看一眼 Mapper XML。
                // 
                
                operLog.getParams().put("videoModules", LogConstants.VIDEO_MODULES);
            } else if ("system".equals(category)) {
                operLog.getParams().put("systemModules", LogConstants.SYSTEM_MODULES);
            }
        }

        if (!ObjectUtils.isEmpty(startTime)) {
            operLog.getParams().put("beginTime", startTime);
        }
        if (!ObjectUtils.isEmpty(endTime)) {
            operLog.getParams().put("endTime", endTime);
        }

        PageHelper.startPage(page, count);
        List<SysOperLog> list = sysOperLogService.selectOperLogList(operLog);
        return new PageInfo<>(list);
    }


    @ResponseBody
    @GetMapping("/list")
    @Operation(summary = "分页查询日志文件", security = @SecurityRequirement(name = JwtUtils.HEADER))
    @Parameter(name = "query", description = "检索内容", required = false)
    @Parameter(name = "startTime", description = "开始时间(yyyy-MM-dd HH:mm:ss)", required = false)
    @Parameter(name = "endTime", description = "结束时间(yyyy-MM-dd HH:mm:ss)", required = false)
    public List<LogFileInfo> queryList(@RequestParam(required = false) String query, @RequestParam(required = false) String startTime, @RequestParam(required = false) String endTime

    ) {
        if (ObjectUtils.isEmpty(query)) {
            query = null;
        }
        if (ObjectUtils.isEmpty(startTime)) {
            startTime = null;
        }
        if (ObjectUtils.isEmpty(endTime)) {
            endTime = null;
        }
        return logService.queryList(query, startTime, endTime);
    }

    /**
     * 下载指定日志文件
     */
    @ResponseBody
    @GetMapping("/file/{fileName}")
    public void downloadFile(HttpServletResponse response, @PathVariable  String fileName) {
        try {
            File file = logService.getFileByName(fileName);
            if (file == null || !file.exists() || !file.isFile()) {
                throw new ControllerException(ErrorCode.ERROR400);
            }
            final InputStream in = Files.newInputStream(file.toPath());
            response.setContentType(MediaType.TEXT_PLAIN_VALUE);
            ServletOutputStream outputStream = response.getOutputStream();
            IOUtils.copy(in, response.getOutputStream());
            in.close();
            outputStream.close();
        } catch (IOException e) {
            response.setStatus(HttpServletResponse.SC_NO_CONTENT);
        }
    }

}
