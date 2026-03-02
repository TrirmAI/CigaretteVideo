package com.genersoft.iot.vmp.openapi.config;

import io.swagger.v3.oas.annotations.OpenAPIDefinition;
import io.swagger.v3.oas.annotations.info.Contact;
import io.swagger.v3.oas.annotations.info.Info;
import io.swagger.v3.oas.annotations.info.License;
import io.swagger.v3.oas.annotations.servers.Server;
import org.springframework.context.annotation.Configuration;

/**
 * OpenAPI 配置类
 * 用于配置外部接口的文档信息
 *
 * @author wvp-pro
 */
@Configuration
@OpenAPIDefinition(
        info = @Info(
                title = "WVP-Pro OpenAPI",
                version = "1.0.0",
                description = "WVP-Pro 外部应用系统调用接口文档",
                contact = @Contact(
                        name = "WVP-Pro Support",
                        email = "support@wvp-pro.com"
                ),
                license = @License(
                        name = "Apache 2.0",
                        url = "https://www.apache.org/licenses/LICENSE-2.0"
                )
        ),
        servers = {
                @Server(
                        url = "http://localhost:18080",
                        description = "本地开发环境"
                ),
                @Server(
                        url = "https://api.example.com",
                        description = "生产环境"
                )
        }
)
public class OpenApiConfig {
    // OpenAPI 配置通过注解完成
}

