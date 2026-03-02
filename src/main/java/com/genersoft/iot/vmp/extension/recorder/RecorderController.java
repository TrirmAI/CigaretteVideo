package com.genersoft.iot.vmp.extension.recorder;

import com.genersoft.iot.vmp.common.annotation.Log;
import com.genersoft.iot.vmp.common.enums.BusinessType;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.Parameter;
import io.swagger.v3.oas.annotations.tags.Tag;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

@Tag(name = "执法仪录像接口")
@Slf4j
@RestController
@RequestMapping("/api/recorder")
public class RecorderController {

    @Autowired
    private RecorderService recorderService;

    @PostMapping("/upload")
    @Operation(summary = "上传执法仪录像文件")
    @Parameter(name = "file", description = "录像文件 (命名格式: 名称_yyyyMMddHHmmss_yyyyMMddHHmmss.mp4)", required = true)
    @Log(title = "执法仪上传", businessType = BusinessType.INSERT)
    public String upload(@RequestParam("file") MultipartFile file) {
        log.info("Received recorder upload: {}", file.getOriginalFilename());
        try {
            recorderService.handleUpload(file);
            return "Upload successful. Processing started.";
        } catch (IllegalArgumentException e) {
            return "Error: " + e.getMessage();
        } catch (Exception e) {
            log.error("Upload failed", e);
            return "Internal Error: " + e.getMessage();
        }
    }
}
