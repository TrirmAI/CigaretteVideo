package com.genersoft.iot.vmp.conf;

import com.genersoft.iot.vmp.conf.exception.ControllerException;
import com.genersoft.iot.vmp.vmanager.bean.ErrorCode;
import com.genersoft.iot.vmp.vmanager.bean.WVPResult;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.BadCredentialsException;
import org.springframework.web.HttpRequestMethodNotSupportedException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.resource.NoResourceFoundException;

import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

/**
 * 全局异常处理
 */
@Slf4j
@RestControllerAdvice
public class GlobalExceptionHandler {

    // #region agent log
    private void logDebug(String hypothesisId, String location, String message, Object data) {
        try {
            String logPath = "/Users/andyapple/Downloads/wvp-GB28181-pro/.cursor/debug.log";
            String logEntry = String.format("{\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"%s\",\"location\":\"%s\",\"message\":\"%s\",\"data\":%s,\"timestamp\":%d}\n",
                hypothesisId, location, message, data != null ? "\"" + data.toString() + "\"" : "null", Instant.now().toEpochMilli());
            try (FileWriter writer = new FileWriter(logPath, true)) {
                writer.write(logEntry);
            }
        } catch (IOException e) {
            // 忽略日志写入错误
        }
    }
    // #endregion agent log

    /**
     * 处理静态资源未找到异常
     * 对于静态资源路径（/static/、/js/、/favicon.ico等），不应该返回JSON格式，应该让Spring返回正常的404响应
     * 对于API路径，返回JSON格式的错误响应
     * @param e 异常
     */
    @ExceptionHandler(NoResourceFoundException.class)
    public ResponseEntity<?> handleNoResourceFoundException(NoResourceFoundException e) {
        String resourcePath = e.getResourcePath();
        // #region agent log
        logDebug("B", "GlobalExceptionHandler.handleNoResourceFoundException", "静态资源未找到异常", resourcePath);
        // #endregion agent log
        
        // 如果是静态资源路径，返回null让Spring返回默认的404响应（HTML格式）
        // 这样浏览器可以正确处理静态资源请求失败的情况
        // 注意：resourcePath可能包含api前缀（如api/static/js/xxx.js），需要检查
        if (resourcePath != null) {
            String normalizedPath = resourcePath.startsWith("api/") ? resourcePath.substring(4) : resourcePath;
            if (normalizedPath.startsWith("/static/") || 
                normalizedPath.startsWith("/js/") || 
                normalizedPath.equals("/favicon.ico") ||
                resourcePath.endsWith(".js") ||
                resourcePath.endsWith(".css") ||
                resourcePath.endsWith(".png") ||
                resourcePath.endsWith(".jpg") ||
                resourcePath.endsWith(".ico") ||
                resourcePath.endsWith(".svg")) {
                // #region agent log
                logDebug("A", "GlobalExceptionHandler.handleNoResourceFoundException", "检测到静态资源请求路径错误", "原始路径=" + resourcePath + ", 规范化路径=" + normalizedPath);
                // #endregion agent log
                log.warn("[静态资源未找到]：{} (可能是路径错误，应该是{}而不是{})", resourcePath, normalizedPath, resourcePath);
                // 返回null，让Spring返回默认的404响应
                return null;
            }
        }
        
        // 对于API路径，返回JSON格式的错误响应
        log.warn("[资源未找到]：{}", resourcePath);
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
            .body(WVPResult.fail(ErrorCode.ERROR404));
    }

    /**
     * 默认异常处理
     * @param e 异常
     * @return 统一返回结果
     */
    @ExceptionHandler(Exception.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public WVPResult<String> exceptionHandler(Exception e) {
        // #region agent log
        logDebug("A", "GlobalExceptionHandler.exceptionHandler", "捕获到异常", e.getClass().getName() + ": " + e.getMessage());
        // #endregion agent log
        // 排除NoResourceFoundException，因为它已经被上面的方法处理了
        if (e instanceof NoResourceFoundException) {
            handleNoResourceFoundException((NoResourceFoundException) e);
            return null;
        }
        log.error("[全局异常]： ", e);
        return WVPResult.fail(ErrorCode.ERROR500.getCode(), e.getMessage());
    }

    /**
     * 默认异常处理
     * @param e 异常
     * @return 统一返回结果
     */
    @ExceptionHandler(IllegalStateException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public WVPResult<String> exceptionHandler(IllegalStateException e) {
        return WVPResult.fail(ErrorCode.ERROR400);
    }

    /**
     * 默认异常处理
     * @param e 异常
     * @return 统一返回结果
     */
    @ExceptionHandler(HttpRequestMethodNotSupportedException.class)
    @ResponseStatus(HttpStatus.BAD_REQUEST)
    public WVPResult<String> exceptionHandler(HttpRequestMethodNotSupportedException e) {
        return WVPResult.fail(ErrorCode.ERROR400);
    }
    /**
     * 断言异常处理
     * @param e 异常
     * @return 统一返回结果
     */
    @ExceptionHandler(IllegalArgumentException.class)
    @ResponseStatus(HttpStatus.OK)
    public WVPResult<String> exceptionHandler(IllegalArgumentException e) {
        return WVPResult.fail(ErrorCode.ERROR100.getCode(), e.getMessage());
    }


    /**
     * 自定义异常处理， 处理controller中返回的错误
     * @param e 异常
     * @return 统一返回结果
     */
    @ExceptionHandler(ControllerException.class)
    @ResponseStatus(HttpStatus.OK)
    public ResponseEntity<WVPResult<String>> exceptionHandler(ControllerException e) {
        return new ResponseEntity<>(WVPResult.fail(e.getCode(), e.getMsg()), HttpStatus.OK);
    }

    /**
     * 登陆失败
     * @param e 异常
     * @return 统一返回结果
     */
    @ExceptionHandler(BadCredentialsException.class)
    @ResponseStatus(HttpStatus.INTERNAL_SERVER_ERROR)
    public ResponseEntity<WVPResult<String>> exceptionHandler(BadCredentialsException e) {
        return new ResponseEntity<>(WVPResult.fail(ErrorCode.ERROR100.getCode(), e.getMessage()), HttpStatus.OK);
    }
}
