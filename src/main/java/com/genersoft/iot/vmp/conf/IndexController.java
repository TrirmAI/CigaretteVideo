package com.genersoft.iot.vmp.conf;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.FileSystemResource;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ResponseBody;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.time.Instant;

/**
 * 根路径控制器
 * 用于处理根路径"/"的请求，优先使用外部目录的index.html
 * Controller的优先级高于WelcomePageHandlerMapping，可以覆盖默认行为
 * 这样可以确保使用外部目录的前端文件，而不是JAR包内的文件
 *
 * @author system
 */
@Controller
@Slf4j
public class IndexController {

    @Value("${web.static.path:/opt/wvp/static}")
    private String staticPath;

    // #region agent log
    private void logDebug(String hypothesisId, String location, String message, Object data) {
        try {
            String logPath = "/Users/andyapple/Downloads/wvp-GB28181-pro/.cursor/debug.log";
            String logEntry = String.format("{\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"%s\",\"location\":\"%s\",\"message\":\"%s\",\"data\":%s,\"timestamp\":%d}\n",
                hypothesisId, location, message, data != null ? "\"" + data.toString().replace("\"", "\\\"") + "\"" : "null", Instant.now().toEpochMilli());
            try (FileWriter writer = new FileWriter(logPath, true)) {
                writer.write(logEntry);
            }
        } catch (IOException e) {
            // 忽略日志写入错误
        }
    }
    // #endregion agent log

    @GetMapping("/")
    @ResponseBody
    public ResponseEntity<Resource> index() {
        // #region agent log
        logDebug("C", "IndexController.index", "处理根路径请求", "staticPath=" + staticPath);
        // #endregion agent log
        // 优先查找外部目录的index.html
        File externalIndex = new File(staticPath, "index.html");
        
        if (externalIndex.exists() && externalIndex.isFile() && externalIndex.canRead()) {
            try {
                log.info("✓ IndexController: 使用外部目录的index.html: {} (大小: {} bytes)", 
                    externalIndex.getAbsolutePath(), externalIndex.length());
                
                Resource resource = new FileSystemResource(externalIndex);
                
                if (!resource.exists()) {
                    log.warn("Resource不存在，交由其他处理器处理");
                    return null; // 返回null让其他处理器处理
                }
                
                HttpHeaders headers = new HttpHeaders();
                headers.setContentType(MediaType.TEXT_HTML);
                headers.setContentLength(externalIndex.length());
                
                log.info("✓ IndexController: 成功返回外部目录文件");
                return new ResponseEntity<>(resource, headers, HttpStatus.OK);
            } catch (Exception e) {
                log.error("读取外部目录index.html失败: {}", e.getMessage(), e);
                // 返回null让其他处理器处理，而不是抛出异常（避免被GlobalResponseAdvice拦截）
                return null;
            }
        } else {
            log.debug("外部目录index.html不存在或不可读: {}, 交由其他处理器处理", externalIndex.getAbsolutePath());
            // 返回null让其他处理器处理（WelcomePageHandlerMapping或WebMvcConfig）
            return null;
        }
    }
}

