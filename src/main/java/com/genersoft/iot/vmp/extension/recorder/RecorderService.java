package com.genersoft.iot.vmp.extension.recorder;

import com.genersoft.iot.vmp.conf.UserSetting;
import com.genersoft.iot.vmp.media.bean.MediaServer;
import com.genersoft.iot.vmp.media.service.IMediaServerService;
import com.genersoft.iot.vmp.service.ICloudRecordService;
import com.genersoft.iot.vmp.service.bean.CloudRecordItem;
import com.genersoft.iot.vmp.storager.dao.CloudRecordServiceMapper;
import com.genersoft.iot.vmp.streamPush.bean.StreamPush;
import com.genersoft.iot.vmp.streamPush.service.IStreamPushService;
import com.genersoft.iot.vmp.utils.DateUtil;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import java.io.BufferedReader;
import java.io.File;
import java.io.InputStreamReader;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.UUID;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Slf4j
@Service
public class RecorderService {

    @Autowired
    private MinioService minioService;

    @Autowired
    private CloudRecordServiceMapper cloudRecordServiceMapper;

    @Autowired
    private IStreamPushService streamPushService;

    @Autowired
    private IMediaServerService mediaServerService;

    @Autowired
    private UserSetting userSetting;

    // Regex for: Name_yyyyMMddHHmmss_yyyyMMddHHmmss.mp4
    private static final Pattern FILENAME_PATTERN = Pattern.compile("^(.*)_(\\d{14})_(\\d{14})\\.mp4$");
    private static final SimpleDateFormat DATE_FORMAT = new SimpleDateFormat("yyyyMMddHHmmss");

    public void handleUpload(MultipartFile file) throws Exception {
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null) {
            throw new IllegalArgumentException("Filename is null");
        }

        Matcher matcher = FILENAME_PATTERN.matcher(originalFilename);
        if (!matcher.matches()) {
            throw new IllegalArgumentException("Filename format error. Expected: Name_yyyyMMddHHmmss_yyyyMMddHHmmss.mp4");
        }

        String deviceName = matcher.group(1);
        String startTimeStr = matcher.group(2);
        String endTimeStr = matcher.group(3);

        Date startTime = DATE_FORMAT.parse(startTimeStr);
        Date endTime = DATE_FORMAT.parse(endTimeStr);

        // Save to temp file
        File tempFile = File.createTempFile("recorder_", ".mp4");
        file.transferTo(tempFile);

        try {
            // 1. Process Logic
            String streamId = deviceName; // Default to device name
            String app = "live";
            
            // Look up GB ID from StreamPush
            StreamPush streamPush = streamPushService.getPush(app, deviceName);
            if (streamPush != null && streamPush.getGbDeviceId() != null) {
                streamId = streamPush.getGbDeviceId();
                log.info("Using GB Device ID as stream ID: {}", streamId);
            }
            
            log.info("Processing upload for app={}, stream={}, start={}, end={}", app, streamId, startTime, endTime);

            // 2. Register/Update StreamPush (Virtual Device)
            if (streamPush == null) {
                streamPush = new StreamPush();
                streamPush.setApp(app);
                streamPush.setStream(deviceName); // Push stream ID remains deviceName
                streamPush.setGbName(deviceName);
                streamPush.setGbDeviceId(null); // Or generate a fake ID
                streamPush.setMediaServerId(mediaServerService.getDefaultMediaServer().getId());
                streamPush.setServerId(userSetting.getServerId());
                streamPushService.add(streamPush);
                log.info("Registered new recorder stream: {}", deviceName);
            } else {
                // Update name if needed
                if (!deviceName.equals(streamPush.getGbName())) {
                    streamPush.setGbName(deviceName);
                    streamPushService.update(streamPush);
                }
            }

            // 3. Upload to MinIO & Save Record (Sync)
            uploadAndSaveRecord(tempFile, app, streamId, startTime, endTime, originalFilename);

            // 4. Start RTMP Push (Async)
            // pushStream(tempFile, app, streamId);

        } catch (Exception e) {
            log.error("Error processing recorder file", e);
            throw e;
        } finally {
            // Temp file deletion is handled in pushStream
        }
    }

    public void uploadAndSaveRecord(File file, String app, String stream, Date startTime, Date endTime, String originalFilename) throws Exception {
        try {
            // Upload to MinIO
            // Structure: app/stream/date/filename
            String dateFolder = DateUtil.getNow(); // Or use startTime date
            String objectName = String.format("%s/%s/%s/%s", app, stream, new SimpleDateFormat("yyyy-MM-dd").format(startTime), originalFilename);
            
            String fileUrl = minioService.uploadFile(file, objectName);
            if (fileUrl != null) {
                // Extract absolute path: /bucket/objectName
                // fileUrl format is typically http://host:port/bucket/objectName
                // We want to store /bucket/objectName to be independent of host/port
                String filePath = fileUrl;
                try {
                    java.net.URL url = new java.net.URL(fileUrl);
                    filePath = url.getPath(); // Returns /bucket/objectName
                } catch (java.net.MalformedURLException e) {
                    log.warn("Failed to parse MinIO URL, using original URL: {}", fileUrl);
                }

                // Insert into Cloud Record
                CloudRecordItem item = new CloudRecordItem();
                item.setApp(app);
                item.setStream(stream);
                item.setStartTime(startTime.getTime());
                item.setEndTime(endTime.getTime());
                item.setTimeLen(endTime.getTime() - startTime.getTime());
                item.setFileName(originalFilename);
                item.setFolder(new SimpleDateFormat("yyyy-MM-dd").format(startTime));
                item.setFilePath(filePath); // Absolute path in bucket
                item.setFileSize(file.length());
                
                MediaServer defaultMediaServer = mediaServerService.getDefaultMediaServer();
                if (defaultMediaServer != null) {
                    item.setMediaServerId(defaultMediaServer.getId());
                } else {
                    log.warn("No default media server found, using 'unknown' for cloud record");
                    item.setMediaServerId("unknown");
                }
                
                item.setServerId(userSetting.getServerId());
                // Generate a callId for compatibility
                item.setCallId(UUID.randomUUID().toString().replace("-", ""));
                
                log.info("Attempting to save cloud record: app={}, stream={}, callId={}, path={}", app, stream, item.getCallId(), fileUrl);
                
                try {
                    int result = cloudRecordServiceMapper.add(item);
                    if (result > 0) {
                        log.info("Successfully saved cloud record for {}", originalFilename);
                    } else {
                        String errMsg = String.format("Failed to save cloud record to database (result=0) for %s", originalFilename);
                        log.error(errMsg);
                        throw new RuntimeException(errMsg);
                    }
                } catch (Exception dbEx) {
                    log.error("Database error saving cloud record", dbEx);
                    throw dbEx;
                }
            } else {
                String errMsg = String.format("MinIO upload returned null URL for %s", originalFilename);
                log.error(errMsg);
                throw new RuntimeException(errMsg);
            }
        } catch (Exception e) {
            log.error("Failed to upload/save record", e);
            throw e;
        }
    }

    @Async
    public void pushStream(File file, String app, String stream) {
        try {
            MediaServer mediaServer = mediaServerService.getDefaultMediaServer();
            String zlmIp = "127.0.0.1"; // Local push usually
            // If ZLM is in docker, 127.0.0.1 refers to container. WVP in container?
            // Assuming WVP and ZLM are co-located or WVP can reach ZLM.
            // Use mediaServer.getIp() if configured correctly.
            
            // Build RTMP URL
            // rtmp://ip:port/app/stream
            // Port: We need to find RTMP port. It's not in MediaServer bean directly? 
            // Usually standard 1935. Or checked in config.
            // For now, I'll assume 1935 or check config. 
            // Let's assume 1935 for simplicity or read from config if possible.
            // Wait, MediaServer has httpPort but maybe not rtmpPort in standard fields?
            // Checking MediaServer bean...
            
            int rtmpPort = 1935; // Default
            
            String rtmpUrl = String.format("rtmp://%s:%d/%s/%s", mediaServer.getIp(), rtmpPort, app, stream);
            
            log.info("Starting push to {}", rtmpUrl);
            
            ProcessBuilder pb = new ProcessBuilder(
                "ffmpeg", "-re", "-i", file.getAbsolutePath(), 
                "-c", "copy", "-f", "flv", rtmpUrl
            );
            
            pb.redirectErrorStream(true);
            Process process = pb.start();
            
            // Consume output to prevent buffer blocking
            try (BufferedReader reader = new BufferedReader(new InputStreamReader(process.getInputStream()))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    // log.debug("FFmpeg: {}", line);
                }
            }
            
            int exitCode = process.waitFor();
            log.info("Push finished with exit code {}", exitCode);
            
            // Delete temp file after push is done (and upload is likely done)
            if (file.exists()) {
                file.delete();
            }
            
        } catch (Exception e) {
            log.error("FFmpeg push failed", e);
        }
    }
}
