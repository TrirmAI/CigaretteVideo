package com.genersoft.iot.vmp.extension.ai.service.impl;

import com.genersoft.iot.vmp.extension.ai.bean.AiAlert;
import com.genersoft.iot.vmp.extension.ai.bean.AiModel;
import com.genersoft.iot.vmp.extension.ai.bean.AiModelVersion;
import com.genersoft.iot.vmp.extension.ai.dao.AiModelMapper;
import com.genersoft.iot.vmp.extension.ai.service.AiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;

@Service
public class AiServiceImpl implements AiService {

    @Autowired
    private AiModelMapper aiModelMapper;

    @Override
    public String chat(String message) {
        return "收到您的指令: " + message + "。正在解析并执行...";
    }

    @Override
    public List<AiAlert> getAlerts() {
        List<AiAlert> alerts = new ArrayList<>();
        
        // 1. 人员聚集 (ryjj01.jpg)
        AiAlert alert1 = new AiAlert();
        alert1.setId("1");
        alert1.setType("人员聚集");
        alert1.setConfidence(0.95);
        alert1.setTime("2023-10-27 10:23:12");
        alert1.setSnapshotUrl("/demo/ryjj01.jpg");
        alert1.setDeviceId("东门广场-CAM01");
        alert1.setGbId("34020000001320000001");
        alert1.setVideoUrl("/demo/ryjj01.mp4");
        alerts.add(alert1);

        // 2. 烟火检测 (yhjc01.jpg)
        AiAlert alert2 = new AiAlert();
        alert2.setId("2");
        alert2.setType("烟火检测");
        alert2.setConfidence(0.98);
        alert2.setTime("2023-10-27 10:15:00");
        alert2.setSnapshotUrl("/demo/yhjc01.jpg");
        alert2.setDeviceId("仓库区-CAM03");
        alert2.setGbId("34020000001320000003");
        alert2.setVideoUrl("/demo/yhjc01.mp4");
        alerts.add(alert2);

        // 3. 打电话 (ddh01.jpeg)
        AiAlert alert3 = new AiAlert();
        alert3.setId("3");
        alert3.setType("打电话");
        alert3.setConfidence(0.89);
        alert3.setTime("2023-10-27 09:45:30");
        alert3.setSnapshotUrl("/demo/ddh01.jpeg");
        alert3.setDeviceId("办公楼大厅-CAM02");
        alert3.setGbId("34020000001320000002");
        alert3.setVideoUrl("/demo/ddh01.mp4");
        alerts.add(alert3);

        // 4. 徘徊检测 (phjc01.jpg) - 假设对应第四张图，原图名 phjc01.jpg
        AiAlert alert4 = new AiAlert();
        alert4.setId("4");
        alert4.setType("徘徊检测");
        alert4.setConfidence(0.92);
        alert4.setTime("2023-10-27 09:30:11");
        alert4.setSnapshotUrl("/demo/phjc01.jpg");
        alert4.setDeviceId("停车场入口-CAM05");
        alert4.setGbId("34020000001320000005");
        alert4.setVideoUrl("/demo/phjc01.mp4");
        alerts.add(alert4);

        return alerts;
    }

    @Override
    public List<AiModel> getModels() {
        return aiModelMapper.selectAllModels();
    }

    @Override
    public List<AiModelVersion> getHistory(String modelId) {
        return aiModelMapper.selectVersionsByModelId(modelId);
    }

    @Override
    public void addModel(AiModel model) {
        if (model.getId() == null) {
            model.setId(UUID.randomUUID().toString());
        }
        if (model.getVersion() == null) {
            model.setVersion("v1.0");
        }
        if (model.getStatus() == null) {
            model.setStatus("ready");
        }
        if (model.getCreateTime() == null) {
            model.setCreateTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        }
        aiModelMapper.insertModel(model);
    }

    @Override
    public void train(String modelName) {
        AiModel model = aiModelMapper.selectModelByName(modelName);
        if (model == null) {
            return;
        }

        // Create new version
        String newVersion = "v" + (System.currentTimeMillis() / 1000);
        AiModelVersion version = new AiModelVersion();
        version.setId(UUID.randomUUID().toString());
        version.setModelId(model.getId());
        version.setVersion(newVersion);
        version.setStatus("training");
        version.setCreateTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
        version.setAccuracy(0.0);
        version.setLoss(0.0);
        version.setFilePath("");
        
        aiModelMapper.insertVersion(version);

        // Update model status
        model.setStatus("training");
        aiModelMapper.updateModelStatus(model);

        // Async simulation
        CompletableFuture.runAsync(() -> {
            try {
                Thread.sleep(5000); // Simulate 5s training
                
                // Finish
                version.setStatus("completed");
                version.setFinishTime(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss")));
                version.setAccuracy(0.85 + Math.random() * 0.1); // Random 0.85-0.95
                version.setLoss(0.1 + Math.random() * 0.05);
                version.setFilePath("/models/" + modelName + "/" + newVersion + ".pt");
                
                aiModelMapper.updateVersion(version);
                
                // Update model status
                model.setVersion(newVersion);
                model.setStatus("ready");
                aiModelMapper.updateModelStatus(model);
                
            } catch (InterruptedException e) {
                e.printStackTrace();
            }
        });
    }
}
