package com.genersoft.iot.vmp.conf;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.annotation.Order;
import org.springframework.lang.NonNull;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.time.Instant;

/**
 * Web MVC配置
 * 配置静态资源路径，支持从外部目录读取前端文件
 *
 * @author system
 */
@Configuration
@Order(0)
@Slf4j
public class WebMvcConfig implements WebMvcConfigurer {

    /**
     * 外部静态资源目录路径（通过环境变量配置）
     * 如果设置了此路径，优先使用外部目录，否则使用JAR包内的资源
     */
    @Value("${web.static.path:}")
    private String externalStaticPath;

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

    @Override
    public void addResourceHandlers(@NonNull ResourceHandlerRegistry registry) {
        // #region agent log
        logDebug("D", "WebMvcConfig.addResourceHandlers", "配置静态资源处理器", "externalStaticPath=" + externalStaticPath);
        // #endregion agent log
        // 默认路径：/opt/wvp/static（容器内路径，对应宿主机：/home/wvp/static）
        String defaultPath = "/opt/wvp/static";
        
        // 如果配置了外部静态资源路径，使用配置的路径
        String staticPath = externalStaticPath != null && !externalStaticPath.isEmpty() 
            ? externalStaticPath 
            : defaultPath;
        
        // #region agent log
        logDebug("D", "WebMvcConfig.addResourceHandlers", "计算后的静态资源路径", "staticPath=" + staticPath);
        // #endregion agent log
        
        File externalDir = new File(staticPath);
        if (externalDir.exists() && externalDir.isDirectory()) {
            // 确保路径以/结尾
            String resourcePath = staticPath.endsWith("/") ? staticPath : staticPath + "/";
            log.info("✓ WebMvcConfig: 使用外部静态资源目录: {} (更新文件后无需重启容器，立即生效)", resourcePath);
            
            // 配置静态资源处理器，优先使用外部目录（file:协议）
            // 注意：资源路径需要包含static子目录，因为前端构建输出在static目录下
            // 访问 /static/css/app.css 时，会在 /opt/wvp/static/static/css/app.css 查找
            // 先注册更具体的路径，确保优先级
            registry.addResourceHandler("/static/**")
                    .addResourceLocations("file:" + resourcePath + "static/")
                    .resourceChain(false);
            
            // 配置根路径下的静态资源（如favicon.ico）
            registry.addResourceHandler("/favicon.ico")
                    .addResourceLocations("file:" + resourcePath)
                    .resourceChain(false);
            
            // 配置其他静态资源（如js目录下的文件）
            registry.addResourceHandler("/js/**")
                    .addResourceLocations("file:" + resourcePath + "static/js/")
                    .resourceChain(false);
            
            // 同时保留JAR包内的资源作为后备（最后注册，优先级最低）
            registry.addResourceHandler("/**")
                    .addResourceLocations("classpath:/static/")
                    .resourceChain(false);
        } else {
            log.warn("外部静态资源目录不存在: {}，将使用JAR包内的资源", staticPath);
            // 默认使用JAR包内的静态资源
            registry.addResourceHandler("/**")
                    .addResourceLocations("classpath:/static/")
                    .resourceChain(false);
        }
    }
}

