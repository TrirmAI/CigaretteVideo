package com.genersoft.iot.vmp.openapi.controller;

import com.genersoft.iot.vmp.conf.security.JwtUtils;
import com.genersoft.iot.vmp.gb28181.bean.Device;
import com.genersoft.iot.vmp.gb28181.bean.DeviceChannel;
import com.genersoft.iot.vmp.gb28181.controller.DeviceQuery;
import com.genersoft.iot.vmp.gb28181.controller.PlayController;
import com.genersoft.iot.vmp.vmanager.bean.StreamContent;
import com.genersoft.iot.vmp.vmanager.bean.WVPResult;
import com.github.pagehelper.PageInfo;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.context.request.async.DeferredResult;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * OpenAPI 视频接口控制器
 * 用于外部应用系统调用视频相关功能
 *
 * @author wvp-pro
 */
@Tag(name = "OpenAPI - 视频接口")
@RestController
@Slf4j
@RequestMapping(value = "/openapi/v1/video")
public class OpenApiVideoController {

    @Autowired
    private DeviceQuery deviceQuery;

    @Autowired
    private PlayController playController;

    /**
     * 获取设备列表
     *
     * @param page 页码
     * @param count 每页数量
     * @param query 搜索关键词
     * @param status 设备状态（true在线，false离线，null全部）
     * @return 设备列表
     */
    @Operation(
            summary = "获取设备列表",
            description = "分页查询国标设备列表",
            security = @SecurityRequirement(name = JwtUtils.HEADER)
    )
    @GetMapping("/devices")
    public WVPResult<PageInfo<Device>> getDevices(
            @Parameter(description = "当前页", required = true) @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页数量", required = true) @RequestParam(defaultValue = "20") int count,
            @Parameter(description = "搜索关键词") @RequestParam(required = false) String query,
            @Parameter(description = "设备状态") @RequestParam(required = false) Boolean status) {
        PageInfo<Device> devices = deviceQuery.devices(page, count, query, status);
        return WVPResult.success(devices);
    }

    /**
     * 获取设备通道列表
     *
     * @param deviceId 设备ID
     * @param page 页码
     * @param count 每页数量
     * @param query 搜索关键词
     * @param online 是否在线
     * @param channelType 通道类型（false设备，true子目录）
     * @return 通道列表
     */
    @Operation(
            summary = "获取设备通道列表",
            description = "分页查询指定设备的通道列表",
            security = @SecurityRequirement(name = JwtUtils.HEADER)
    )
    @GetMapping("/devices/{deviceId}/channels")
    public WVPResult<PageInfo<DeviceChannel>> getChannels(
            @Parameter(description = "设备国标编号", required = true) @PathVariable String deviceId,
            @Parameter(description = "当前页", required = true) @RequestParam(defaultValue = "1") int page,
            @Parameter(description = "每页数量", required = true) @RequestParam(defaultValue = "100") int count,
            @Parameter(description = "搜索关键词") @RequestParam(required = false) String query,
            @Parameter(description = "是否在线") @RequestParam(required = false) Boolean online,
            @Parameter(description = "通道类型") @RequestParam(required = false) Boolean channelType) {
        PageInfo<DeviceChannel> channels = deviceQuery.channels(deviceId, page, count, query, online, channelType);
        return WVPResult.success(channels);
    }

    /**
     * 获取设备树形结构
     *
     * @param query 搜索关键词
     * @param status 设备状态
     * @return 设备树形结构
     */
    @Operation(
            summary = "获取设备树形结构",
            description = "获取包含设备和通道的树形结构，用于目录树展示。通道数据需要调用 /devices/{deviceId}/channels 接口加载",
            security = @SecurityRequirement(name = JwtUtils.HEADER)
    )
    @GetMapping("/tree")
    public WVPResult<List<Map<String, Object>>> getDeviceTree(
            @Parameter(description = "搜索关键词") @RequestParam(required = false) String query,
            @Parameter(description = "设备状态") @RequestParam(required = false) Boolean status) {
        // 获取所有设备
        PageInfo<Device> devicesPage = deviceQuery.devices(1, 1000, query, status);
        List<Device> devices = devicesPage.getList();

        // 构建树形结构（不包含通道，通道通过懒加载获取）
        List<Map<String, Object>> tree = devices.stream().map(device -> {
            Map<String, Object> deviceNode = new HashMap<>();
            deviceNode.put("id", device.getDeviceId());
            deviceNode.put("label", device.getName() + " (" + device.getDeviceId() + ")");
            deviceNode.put("type", "device");
            deviceNode.put("online", device.isOnLine());
            deviceNode.put("deviceId", device.getDeviceId());
            deviceNode.put("children", null); // null 表示需要懒加载
            deviceNode.put("leaf", false);
            return deviceNode;
        }).toList();

        return WVPResult.success(tree);
    }

    /**
     * 开始播放视频
     *
     * @param request HTTP请求
     * @param deviceId 设备ID
     * @param channelId 通道ID
     * @return 流信息
     */
    @Operation(
            summary = "开始播放视频",
            description = "开始点播指定设备的通道视频流",
            security = @SecurityRequirement(name = JwtUtils.HEADER)
    )
    @GetMapping("/play/{deviceId}/{channelId}")
    public DeferredResult<WVPResult<StreamContent>> play(
            HttpServletRequest request,
            @Parameter(description = "设备国标编号", required = true) @PathVariable String deviceId,
            @Parameter(description = "通道国标编号", required = true) @PathVariable String channelId) {
        return playController.play(request, deviceId, channelId);
    }

    /**
     * 停止播放视频
     *
     * @param deviceId 设备ID
     * @param channelId 通道ID
     * @return 操作结果
     */
    @Operation(
            summary = "停止播放视频",
            description = "停止指定设备的通道视频流",
            security = @SecurityRequirement(name = JwtUtils.HEADER)
    )
    @GetMapping("/stop/{deviceId}/{channelId}")
    public WVPResult<String> stop(
            @Parameter(description = "设备国标编号", required = true) @PathVariable String deviceId,
            @Parameter(description = "通道国标编号", required = true) @PathVariable String channelId) {
        try {
            playController.playStop(deviceId, channelId);
            return WVPResult.success("停止播放成功");
        } catch (Exception e) {
            log.error("停止播放失败", e);
            return WVPResult.fail(500, "停止播放失败: " + e.getMessage());
        }
    }
}

