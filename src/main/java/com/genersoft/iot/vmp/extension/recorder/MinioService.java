package com.genersoft.iot.vmp.extension.recorder;

import io.minio.BucketExistsArgs;
import io.minio.MakeBucketArgs;
import io.minio.MinioClient;
import io.minio.PutObjectArgs;
import io.minio.SetBucketPolicyArgs;
import io.minio.RemoveObjectArgs;
import io.minio.UploadObjectArgs;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.io.File;
import java.io.FileInputStream;

@Slf4j
@Service
public class MinioService {

    @Autowired(required = false)
    private MinioClient minioClient;

    @Autowired
    private MinioConfig minioConfig;

    public MinioConfig getMinioConfig() {
        return minioConfig;
    }

    public boolean deleteFile(String fileUrl) {
        log.info("Deleting file from MinIO. URL: {}", fileUrl);
        // Initialize MinioClient manually if not injected
        if (minioClient == null) {
            if (!minioConfig.isEnabled()) {
                log.warn("MinIO is disabled in config");
                return false;
            }
             try {
                 minioClient = MinioClient.builder()
                        .endpoint(minioConfig.getUrl())
                        .credentials(minioConfig.getAccessKey(), minioConfig.getSecretKey())
                        .build();
             } catch (Exception e) {
                 log.error("Failed to initialize MinioClient", e);
                 return false;
             }
        }

        try {
            // Extract object name from URL
            // URL format: http://host:port/bucket/objectName
            
            String bucketPart = "/" + minioConfig.getBucket() + "/";
            int bucketIndex = fileUrl.indexOf(bucketPart);
            if (bucketIndex == -1) {
                log.warn("Invalid MinIO URL format (bucket not found): {}", fileUrl);
                return false;
            }
            
            String objectName = fileUrl.substring(bucketIndex + bucketPart.length());
            log.info("Deleting object: bucket={}, object={}", minioConfig.getBucket(), objectName);

            minioClient.removeObject(
                    RemoveObjectArgs.builder()
                            .bucket(minioConfig.getBucket())
                            .object(objectName)
                            .build());
            
            return true;
        } catch (Exception e) {
            log.error("Failed to delete file from MinIO: " + fileUrl, e);
            return false;
        }
    }

    public String uploadFile(File file, String objectName) {
        if (!minioConfig.isEnabled()) {
            log.warn("MinIO is disabled, skipping upload");
            return null;
        }
            
        // Initialize MinioClient manually if not injected
        if (minioClient == null) {
             try {
                 minioClient = MinioClient.builder()
                        .endpoint(minioConfig.getUrl())
                        .credentials(minioConfig.getAccessKey(), minioConfig.getSecretKey())
                        .build();
             } catch (Exception e) {
                 log.error("Failed to initialize MinioClient", e);
                 return null;
             }
        }

        String bucketName = minioConfig.getBucket();

        try {
            boolean found = minioClient.bucketExists(BucketExistsArgs.builder().bucket(bucketName).build());
            if (!found) {
                minioClient.makeBucket(MakeBucketArgs.builder().bucket(bucketName).build());
                // Set bucket policy to public read
                String policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"*\"]},\"Action\":[\"s3:GetObject\"],\"Resource\":[\"arn:aws:s3:::" + bucketName + "/*\"]}]}";
                minioClient.setBucketPolicy(SetBucketPolicyArgs.builder().bucket(bucketName).config(policy).build());
            } else {
                // Ensure policy is set even if bucket exists
                try {
                    String policy = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"AWS\":[\"*\"]},\"Action\":[\"s3:GetObject\"],\"Resource\":[\"arn:aws:s3:::" + bucketName + "/*\"]}]}";
                    minioClient.setBucketPolicy(SetBucketPolicyArgs.builder().bucket(bucketName).config(policy).build());
                } catch (Exception e) {
                    log.warn("Failed to update bucket policy/CORS, it might already be set or insufficient permissions: {}", e.getMessage());
                }
            }

            log.info("Starting upload to MinIO. Bucket: {}, Object: {}, File: {}", bucketName, objectName, file.getAbsolutePath());
            
            minioClient.uploadObject(
                    UploadObjectArgs.builder()
                            .bucket(bucketName)
                            .object(objectName)
                            .filename(file.getAbsolutePath())
                            .contentType("video/mp4")
                            .build());

            String fileUrl;
            String endpoint = minioConfig.getUrl();
            if (endpoint.endsWith("/")) {
                fileUrl = endpoint + bucketName + "/" + objectName;
            } else {
                fileUrl = endpoint + "/" + bucketName + "/" + objectName;
            }
            log.info("Uploaded file to MinIO successfully. URL: {}", fileUrl);
            return fileUrl;

        } catch (Exception e) {
            log.error("Error uploading file to MinIO. Bucket: " + bucketName + ", Object: " + objectName, e);
            throw new RuntimeException("MinIO Upload Failed", e);
        }
    }
}
