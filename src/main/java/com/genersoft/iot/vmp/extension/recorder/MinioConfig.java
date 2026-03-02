package com.genersoft.iot.vmp.extension.recorder;

import io.minio.MinioClient;
import lombok.Data;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Data
@Configuration
public class MinioConfig {

    @Value("${record.s3.enabled:true}")
    private boolean enabled;
    
    @Value("${record.s3.url:http://127.0.0.1:9000}")
    private String url;
    
    @Value("${record.s3.access-key:admin}")
    private String accessKey;
    
    @Value("${record.s3.secret-key:wvp_minio_123456}")
    private String secretKey;
    
    @Value("${record.s3.bucket:wvppro}")
    private String bucket;
    
    @Value("${record.s3.public-url:true}")
    private boolean publicUrl;

    @Bean
    public MinioClient minioClient() {
        if (!enabled) {
            return null;
        }
        return MinioClient.builder()
                .endpoint(url)
                .credentials(accessKey, secretKey)
                .build();
    }
}
