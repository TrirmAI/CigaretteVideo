package com.genersoft.iot.vmp.service.impl;

import com.alibaba.fastjson2.JSONArray;
import com.alibaba.fastjson2.JSONObject;
import com.genersoft.iot.vmp.common.StreamInfo;
import com.genersoft.iot.vmp.conf.UserSetting;
import com.genersoft.iot.vmp.conf.exception.ControllerException;
import com.genersoft.iot.vmp.extension.recorder.MinioService;
import com.genersoft.iot.vmp.media.bean.MediaServer;
import com.genersoft.iot.vmp.media.bean.RecordInfo;
import com.genersoft.iot.vmp.media.event.media.MediaRecordMp4Event;
import com.genersoft.iot.vmp.media.service.IMediaServerService;
import com.genersoft.iot.vmp.media.zlm.AssistRESTfulUtils;
import com.genersoft.iot.vmp.media.zlm.dto.StreamAuthorityInfo;
import com.genersoft.iot.vmp.service.ICloudRecordService;
import com.genersoft.iot.vmp.service.bean.CloudRecordItem;
import com.genersoft.iot.vmp.service.bean.DownloadFileInfo;
import com.genersoft.iot.vmp.service.bean.ErrorCallback;
import com.genersoft.iot.vmp.service.redisMsg.IRedisRpcPlayService;
import com.genersoft.iot.vmp.storager.IRedisCatchStorage;
import com.genersoft.iot.vmp.storager.dao.CloudRecordServiceMapper;
import com.genersoft.iot.vmp.utils.DateUtil;
import com.genersoft.iot.vmp.vmanager.bean.ErrorCode;
import com.genersoft.iot.vmp.vmanager.cloudRecord.bean.CloudRecordUrl;
import com.github.pagehelper.PageHelper;
import com.github.pagehelper.PageInfo;
import lombok.extern.slf4j.Slf4j;
import org.apache.commons.lang3.ObjectUtils;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.event.EventListener;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import org.springframework.util.Assert;

import java.io.File;
import java.time.LocalDate;
import java.time.ZoneOffset;
import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

@Slf4j
@Service
public class CloudRecordServiceImpl implements ICloudRecordService {

    @Autowired
    private CloudRecordServiceMapper cloudRecordServiceMapper;

    @Autowired
    private IMediaServerService mediaServerService;

    @Autowired
    private IRedisCatchStorage redisCatchStorage;

    @Autowired
    private AssistRESTfulUtils assistRESTfulUtils;

    @Autowired
    private UserSetting userSetting;

    @Autowired
    private IRedisRpcPlayService redisRpcPlayService;

    @Autowired
    private MinioService minioService;

    @Override
    public PageInfo<CloudRecordItem> getList(int page, int count, String query, String app, String stream, String startTime,
                                             String endTime, List<MediaServer> mediaServerItems, String callId, Boolean ascOrder) {
        // 开始时间和结束时间在数据库中都是以秒为单位的
        Long startTimeStamp = null;
        Long endTimeStamp = null;
        if (startTime != null ) {
            if (!DateUtil.verification(startTime, DateUtil.formatter)) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "开始时间格式错误，正确格式为： " + DateUtil.formatter);
            }
            startTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestampMs(startTime);

        }
        if (endTime != null ) {
            if (!DateUtil.verification(endTime, DateUtil.formatter)) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "结束时间格式错误，正确格式为： " + DateUtil.formatter);
            }
            endTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestampMs(endTime);

        }
        PageHelper.startPage(page, count);
        if (query != null) {
            query = query.replaceAll("/", "//")
                    .replaceAll("%", "/%")
                    .replaceAll("_", "/_");
        }
        List<CloudRecordItem> all = cloudRecordServiceMapper.getList(query, app, stream, startTimeStamp, endTimeStamp,
                callId, mediaServerItems, null, ascOrder);
        return new PageInfo<>(all);
    }

    @Override
    public List<String> getDateList(String app, String stream, int year, int month, List<MediaServer> mediaServerItems) {
        LocalDate startDate = LocalDate.of(year, month, 1);
        LocalDate endDate;
        if (month == 12) {
            endDate = LocalDate.of(year + 1, 1, 1);
        }else {
            endDate = LocalDate.of(year, month + 1, 1);
        }
        long startTimeStamp = startDate.atStartOfDay().toInstant(ZoneOffset.ofHours(8)).toEpochMilli();
        long endTimeStamp = endDate.atStartOfDay().toInstant(ZoneOffset.ofHours(8)).toEpochMilli();
        List<CloudRecordItem> cloudRecordItemList = cloudRecordServiceMapper.getList(null, app, stream, startTimeStamp,
                endTimeStamp, null, mediaServerItems, null, null);
        if (cloudRecordItemList.isEmpty()) {
            return new ArrayList<>();
        }
        Set<String> resultSet = new HashSet<>();
        cloudRecordItemList.stream().forEach(cloudRecordItem -> {
            String date = DateUtil.timestampTo_yyyy_MM_dd(cloudRecordItem.getStartTime());
            resultSet.add(date);
        });
        return new ArrayList<>(resultSet);
    }

    @Async("taskExecutor")
    @EventListener
    public void onApplicationEvent(MediaRecordMp4Event event) {
        CloudRecordItem cloudRecordItem = CloudRecordItem.getInstance(event);
        cloudRecordItem.setServerId(userSetting.getServerId());
        if (ObjectUtils.isEmpty(cloudRecordItem.getCallId())) {
            StreamAuthorityInfo streamAuthorityInfo = redisCatchStorage.getStreamAuthorityInfo(event.getApp(), event.getStream());
            if (streamAuthorityInfo != null) {
                cloudRecordItem.setCallId(streamAuthorityInfo.getCallId());
            }
        }
        log.info("[添加录像记录] {}/{}, callId: {}, 内容：{}", event.getApp(), event.getStream(), cloudRecordItem.getCallId(), event.getRecordInfo());
        cloudRecordServiceMapper.add(cloudRecordItem);
    }

    @Override
    public String addTask(String app, String stream, MediaServer mediaServerItem, String startTime, String endTime,
                          String callId, String remoteHost, boolean filterMediaServer) {
        // 参数校验
        Assert.notNull(app,"应用名为NULL");
        Assert.notNull(stream,"流ID为NULL");
        if (mediaServerItem.getRecordAssistPort() == 0) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "为配置Assist服务");
        }
        Long startTimeStamp = null;
        Long endTimeStamp = null;
        if (startTime != null) {
            startTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestamp(startTime);
        }
        if (endTime != null) {
            endTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestamp(endTime);
        }

        List<MediaServer> mediaServers = new ArrayList<>();
        mediaServers.add(mediaServerItem);
        // 检索相关的录像文件
        List<String> filePathList = cloudRecordServiceMapper.queryRecordFilePathList(app, stream, startTimeStamp,
                endTimeStamp, callId, filterMediaServer ? mediaServers : null);
        if (filePathList == null || filePathList.isEmpty()) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "未检索到视频文件");
        }
        JSONObject result =  assistRESTfulUtils.addTask(mediaServerItem, app, stream, startTime, endTime, callId, filePathList, remoteHost);
        if (result.getInteger("code") != 0) {
            throw new ControllerException(result.getInteger("code"), result.getString("msg"));
        }
        return result.getString("data");
    }

    @Override
    public JSONArray queryTask(String app, String stream, String callId, String taskId, String mediaServerId,
                               Boolean isEnd, String scheme) {
        MediaServer mediaServerItem = null;
        if (mediaServerId == null) {
            mediaServerItem = mediaServerService.getDefaultMediaServer();
        }else {
            mediaServerItem = mediaServerService.getOne(mediaServerId);
        }
        if (mediaServerItem == null) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "未找到可用的流媒体");
        }

        JSONObject result =  assistRESTfulUtils.queryTaskList(mediaServerItem, app, stream, callId, taskId, isEnd, scheme);
        if (result == null || result.getInteger("code") != 0) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), result == null ? "查询任务列表失败" : result.getString("msg"));
        }
        return result.getJSONArray("data");
    }

    @Override
    public int changeCollect(boolean result, String app, String stream, String mediaServerId, String startTime, String endTime, String callId) {
        // 开始时间和结束时间在数据库中都是以秒为单位的
        Long startTimeStamp = null;
        Long endTimeStamp = null;
        if (startTime != null ) {
            if (!DateUtil.verification(startTime, DateUtil.formatter)) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "开始时间格式错误，正确格式为： " + DateUtil.formatter);
            }
            startTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestamp(startTime);

        }
        if (endTime != null ) {
            if (!DateUtil.verification(endTime, DateUtil.formatter)) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "结束时间格式错误，正确格式为： " + DateUtil.formatter);
            }
            endTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestamp(endTime);

        }

        List<MediaServer> mediaServerItems;
        if (!ObjectUtils.isEmpty(mediaServerId)) {
            mediaServerItems = new ArrayList<>();
            MediaServer mediaServerItem = mediaServerService.getOne(mediaServerId);
            if (mediaServerItem == null) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "未找到流媒体: " + mediaServerId);
            }
            mediaServerItems.add(mediaServerItem);
        } else {
            mediaServerItems = null;
        }

        List<CloudRecordItem> all = cloudRecordServiceMapper.getList(null, app, stream, startTimeStamp, endTimeStamp,
                callId, mediaServerItems, null, null);
        if (all.isEmpty()) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "未找到待收藏的视频");
        }
        int limitCount = 50;
        int resultCount = 0;
        if (all.size() > limitCount) {
            for (int i = 0; i < all.size(); i += limitCount) {
                int toIndex = i + limitCount;
                if (i + limitCount > all.size()) {
                    toIndex = all.size();
                }
                resultCount += cloudRecordServiceMapper.updateCollectList(result, all.subList(i, toIndex));

            }
        }else {
            resultCount = cloudRecordServiceMapper.updateCollectList(result, all);
        }
        return resultCount;
    }

    @Override
    public int changeCollectById(Integer recordId, boolean result) {
       return cloudRecordServiceMapper.changeCollectById(result, recordId);
    }

    @Override
    public DownloadFileInfo getPlayUrlPath(Integer recordId) {
        CloudRecordItem recordItem = cloudRecordServiceMapper.queryOne(recordId);
        if (recordItem == null) {
            throw new ControllerException(ErrorCode.ERROR400.getCode(), "资源不存在");
        }
        
        // Check for MinIO/S3 path
        // It could be a full URL (http...) or an absolute path (/bucket/...)
        String filePath = recordItem.getFilePath();
        if (filePath != null) {
             if (filePath.startsWith("http://") || filePath.startsWith("https://")) {
                DownloadFileInfo downloadFileInfo = new DownloadFileInfo();
                downloadFileInfo.setHttpPath(filePath);
                downloadFileInfo.setHttpsPath(filePath);
                return downloadFileInfo;
             }
             
             // Check if it matches MinIO bucket pattern
             // Assuming filePath starts with /bucketName/ if it's stored as absolute path
             String bucketName = minioService.getMinioConfig().getBucket();
             if (bucketName != null && filePath.startsWith("/" + bucketName + "/")) {
                 String endpoint = minioService.getMinioConfig().getUrl();
                 // Remove trailing slash from endpoint if present
                 if (endpoint.endsWith("/")) {
                     endpoint = endpoint.substring(0, endpoint.length() - 1);
                 }
                 String fullUrl = endpoint + filePath;
                 
                 DownloadFileInfo downloadFileInfo = new DownloadFileInfo();
                 downloadFileInfo.setHttpPath(fullUrl);
                 downloadFileInfo.setHttpsPath(fullUrl);
                 return downloadFileInfo;
             }
        }

        if (!userSetting.getServerId().equals(recordItem.getServerId())) {
            return redisRpcPlayService.getRecordPlayUrl(recordItem.getServerId(), recordId);
        }

        MediaServer mediaServer = mediaServerService.getOne(recordItem.getMediaServerId());

        return mediaServerService.getDownloadFilePath(mediaServer, RecordInfo.getInstance(recordItem));
    }

    @Override
    public List<CloudRecordItem> getAllList(String query, String app, String stream, String startTime, String endTime, List<MediaServer> mediaServerItems, String callId, List<Integer> ids) {
        // 开始时间和结束时间在数据库中都是以秒为单位的
        Long startTimeStamp = null;
        Long endTimeStamp = null;
        if (startTime != null ) {
            if (!DateUtil.verification(startTime, DateUtil.formatter)) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "开始时间格式错误，正确格式为： " + DateUtil.formatter);
            }
            startTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestampMs(startTime);

        }
        if (endTime != null ) {
            if (!DateUtil.verification(endTime, DateUtil.formatter)) {
                throw new ControllerException(ErrorCode.ERROR100.getCode(), "结束时间格式错误，正确格式为： " + DateUtil.formatter);
            }
            endTimeStamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestampMs(endTime);

        }
        return cloudRecordServiceMapper.getList(query, app, stream, startTimeStamp, endTimeStamp,
                callId, mediaServerItems, ids, null);
    }

    @Override
    public void loadMP4File(String app, String stream, int cloudRecordId, ErrorCallback<StreamInfo> callback) {

        CloudRecordItem recordItem = cloudRecordServiceMapper.queryOne(cloudRecordId);
        if (recordItem == null) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "无录像");
        }
        String mediaServerId = recordItem.getMediaServerId();
        MediaServer mediaServer = mediaServerService.getOne(mediaServerId);
        if (mediaServer == null) {
            log.warn("[云端录像] 播放 未找到录制的流媒体，将自动选择低负载流媒体使用");
            mediaServer = mediaServerService.getMediaServerForMinimumLoad(null);
        }
        if (mediaServer == null) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "无可用流媒体");
        }
        String fileName = recordItem.getFileName().substring(0 , recordItem.getFileName().indexOf("."));
        String filePath = recordItem.getFilePath();
//        if (filePath != null) {
//            fileName = filePath.substring(0, filePath.lastIndexOf("/"));
//        }
        mediaServerService.loadMP4File(mediaServer, app, stream, filePath, fileName, ((code, msg, streamInfo) -> {
            if (code == ErrorCode.SUCCESS.getCode()) {
                streamInfo.setDuration(recordItem.getTimeLen());
            }
            callback.run(code, msg, streamInfo);
        }));
    }

    @Override
    public void loadMP4FileForDate(String app, String stream, String date, ErrorCallback<StreamInfo> callback) {
        long startTimestamp = DateUtil.yyyy_MM_dd_HH_mm_ssToTimestampMs(date + " 00:00:00");
        long endTimestamp = startTimestamp + 24 * 60 * 60 * 1000;

        List<CloudRecordItem> recordItemList = cloudRecordServiceMapper.getList(null, app, stream, startTimestamp, endTimestamp, null, null, null, false);
        if (recordItemList.isEmpty()) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "此时间无录像");
        }
        String mediaServerId = recordItemList.get(0).getMediaServerId();
        MediaServer mediaServer = mediaServerService.getOne(mediaServerId);
        if (mediaServer == null) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "媒体节点不存在： " + mediaServerId);
        }
        String dateDir = null;
        String filePath = recordItemList.get(0).getFilePath();
        if (filePath != null) {
            dateDir = filePath.substring(0, filePath.lastIndexOf("/"));
        }
        mediaServerService.loadMP4FileForDate(mediaServer, app, stream, date, dateDir, callback);

    }

    @Override
    public void seekRecord(String mediaServerId,String app, String stream, Double seek, String schema) {
        MediaServer mediaServer = mediaServerService.getOne(mediaServerId);
        if (mediaServer == null) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "媒体节点不存在： " + mediaServerId);
        }
        mediaServerService.seekRecordStamp(mediaServer, app, stream, seek, schema);
    }

    @Override
    public void setRecordSpeed(String mediaServerId, String app, String stream, Integer speed, String schema) {
        MediaServer mediaServer = mediaServerService.getOne(mediaServerId);
        if (mediaServer == null) {
            throw new ControllerException(ErrorCode.ERROR100.getCode(), "媒体节点不存在： " + mediaServerId);
        }
        mediaServerService.setRecordSpeed(mediaServer, app, stream, speed, schema);
    }

    @Override
    public void deleteFileByIds(Set<Integer> ids) {
        log.info("[删除录像文件] ids: {}", ids.toArray());
        List<CloudRecordItem> cloudRecordItemList = cloudRecordServiceMapper.queryRecordByIds(ids);
        if (cloudRecordItemList.isEmpty()) {
            return;
        }
        List<CloudRecordItem> cloudRecordItemIdListForDelete = new ArrayList<>();
        StringBuilder stringBuilder = new StringBuilder();
        String bucketName = minioService.getMinioConfig().getBucket();
        for (CloudRecordItem cloudRecordItem : cloudRecordItemList) {
            // Check if it is a cloud storage file (MinIO/S3)
            boolean isCloudFile = false;
            String filePath = cloudRecordItem.getFilePath();
            if (filePath != null) {
                if (filePath.startsWith("http")) {
                    isCloudFile = true;
                } else if (bucketName != null && filePath.startsWith("/" + bucketName + "/")) {
                    isCloudFile = true;
                    // MinioService expects a full URL-like structure or handles the bucket extraction logic
                    // If we only have path /bucket/object, MinioService.deleteFile logic:
                    // int bucketIndex = fileUrl.indexOf(bucketPart);
                    // It needs the bucketPart ("/" + bucket + "/") to be present.
                    // So passing the absolute path directly should work with current MinioService logic
                    // BUT to be safe and mimic a URL structure if needed, or ensuring it's treated correctly.
                    // Let's verify MinioService logic again:
                    // String bucketPart = "/" + minioConfig.getBucket() + "/";
                    // int bucketIndex = fileUrl.indexOf(bucketPart);
                    // If fileUrl is "/wvppro/live/...", bucketPart is "/wvppro/", index is 0.
                    // objectName = substring(0 + length) -> works.
                }
            }

            if (isCloudFile) {
                boolean deleteResult = minioService.deleteFile(filePath);
                if (deleteResult) {
                    log.warn("[录像文件] 删除云端文件成功： {}", filePath);
                } else {
                    log.warn("[录像文件] 删除云端文件失败（可能文件不存在）： {}", filePath);
                }
                // Always delete DB record for cloud storage items to ensure consistency
                cloudRecordItemIdListForDelete.add(cloudRecordItem);
                continue;
            }

            String date = new File(cloudRecordItem.getFilePath()).getParentFile().getName();
            MediaServer mediaServer = mediaServerService.getOne(cloudRecordItem.getMediaServerId());
            try {
                if (mediaServer == null) {
                     // If media server is gone, we can't delete local file, but we should probably delete DB record
                     log.warn("[录像文件] 流媒体节点不存在，无法删除本地文件，仅删除数据库记录： {}", cloudRecordItem.getFilePath());
                     cloudRecordItemIdListForDelete.add(cloudRecordItem);
                     continue;
                }
                
                boolean deleteResult = mediaServerService.deleteRecordDirectory(mediaServer, cloudRecordItem.getApp(),
                        cloudRecordItem.getStream(), date, cloudRecordItem.getFileName());
                if (deleteResult) {
                    log.warn("[录像文件] 删除磁盘文件成功： {}", cloudRecordItem.getFilePath());
                } else {
                    log.warn("[录像文件] 删除磁盘文件失败（可能文件不存在），仅删除数据库记录： {}", cloudRecordItem.getFilePath());
                }
                // Always delete DB record even if file deletion failed (e.g. file missing)
                cloudRecordItemIdListForDelete.add(cloudRecordItem);
            }catch (ControllerException e) {
                log.warn("[录像文件] 删除磁盘文件异常： {}， 仍将删除数据库记录", cloudRecordItem.getFilePath(), e);
                // Don't block DB deletion on error
                cloudRecordItemIdListForDelete.add(cloudRecordItem);
            }

        }
        if (!cloudRecordItemIdListForDelete.isEmpty()) {
            cloudRecordServiceMapper.deleteList(cloudRecordItemIdListForDelete);
        }
        // Removed the exception throwing logic to allow "force delete" behavior from UI
        if (stringBuilder.length() > 0) {
            log.warn("[录像文件] 部分文件删除遇到问题: {}", stringBuilder.toString());
        }
    }

    @Override
    public List<CloudRecordUrl> getUrlListByIds(List<Integer> ids) {
        List<CloudRecordItem> cloudRecordItems = cloudRecordServiceMapper.queryRecordByIds(ids);
        if (cloudRecordItems.isEmpty()) {
            return List.of();
        }
        return getCloudRecordUrl(cloudRecordItems);
    }

    @Override
    public List<CloudRecordUrl> getUrlList(String app, String stream, String callId) {
        List<CloudRecordItem> cloudRecordItems = cloudRecordServiceMapper.queryRecordByAppStreamAndCallId(app, stream, callId);
        if (cloudRecordItems.isEmpty()) {
            return List.of();
        }
        return getCloudRecordUrl(cloudRecordItems);
    }

    private List<CloudRecordUrl> getCloudRecordUrl(List<CloudRecordItem> cloudRecordItems) {
        if (cloudRecordItems.isEmpty()) {
            return List.of();
        }
        List<CloudRecordUrl> resultList = new ArrayList<>();
        for (CloudRecordItem cloudRecordItem : cloudRecordItems) {
            CloudRecordUrl cloudRecordUrl = new CloudRecordUrl();
            cloudRecordUrl.setId(cloudRecordItem.getId());
            cloudRecordUrl.setFileName(cloudRecordItem.getStartTime() + ".mp4");
            cloudRecordUrl.setFilePath(cloudRecordItem.getFilePath());
            
            // Check for MinIO/S3 path logic
            boolean isMinio = false;
            String filePath = cloudRecordItem.getFilePath();
            if (filePath != null) {
                if (filePath.startsWith("http://") || filePath.startsWith("https://")) {
                    cloudRecordUrl.setDownloadUrl(filePath);
                    cloudRecordUrl.setPlayUrl(filePath);
                    isMinio = true;
                } else {
                     // Check if it matches MinIO bucket pattern
                     String bucketName = minioService.getMinioConfig().getBucket();
                     if (bucketName != null && filePath.startsWith("/" + bucketName + "/")) {
                         String endpoint = minioService.getMinioConfig().getUrl();
                         if (endpoint.endsWith("/")) {
                             endpoint = endpoint.substring(0, endpoint.length() - 1);
                         }
                         String fullUrl = endpoint + filePath;
                         cloudRecordUrl.setDownloadUrl(fullUrl);
                         cloudRecordUrl.setPlayUrl(fullUrl);
                         isMinio = true;
                     }
                }
            }

            if (!isMinio) {
                if (!userSetting.getServerId().equals(cloudRecordItem.getServerId())) {
                    cloudRecordUrl.setDownloadUrl(redisRpcPlayService.getRecordPlayUrl(cloudRecordItem.getServerId(), cloudRecordItem.getId()).getHttpPath());
                }else {
                    MediaServer mediaServer = mediaServerService.getOne(cloudRecordItem.getMediaServerId());
                    if (mediaServer != null) {
                         mediaServer.setStreamIp(mediaServer.getIp());
                         DownloadFileInfo downloadFilePath = mediaServerService.getDownloadFilePath(mediaServer, RecordInfo.getInstance(cloudRecordItem));
                         cloudRecordUrl.setDownloadUrl(downloadFilePath.getHttpPath());
                    }
                }
            }
            resultList.add(cloudRecordUrl);
        }

        return resultList;
    }
}
