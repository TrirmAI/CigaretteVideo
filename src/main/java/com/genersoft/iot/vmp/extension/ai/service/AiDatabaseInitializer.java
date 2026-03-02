package com.genersoft.iot.vmp.extension.ai.service;

import com.genersoft.iot.vmp.extension.ai.bean.AiModel;
import com.genersoft.iot.vmp.extension.ai.bean.AiModelVersion;
import com.genersoft.iot.vmp.extension.ai.dao.AiModelMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

@Component
@Order(100)
public class AiDatabaseInitializer implements CommandLineRunner {

    @Autowired
    private AiModelMapper aiModelMapper;

    @Override
    public void run(String... args) throws Exception {
        // Drop tables first to ensure schema matches (for dev/demo purpose)
        aiModelMapper.dropModelTable();
        aiModelMapper.dropVersionTable();

        aiModelMapper.createModelTable();
        aiModelMapper.createVersionTable();
        
        // Always reset and re-seed default demo models to ensure data visibility
        String now = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String prev1 = LocalDateTime.now().minusDays(5).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));
        String prev2 = LocalDateTime.now().minusDays(10).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss"));

        // 1. 通用物体检测
        resetAndCreateModel("1", "通用物体检测", "v1.0", "ready", prev2, 
            new String[]{"v1.0"}, new String[]{prev2});

        // 2. 红色安全帽识别
        resetAndCreateModel("2", "红色安全帽识别", "v1.2", "ready", prev2, 
            new String[]{"v1.0", "v1.1", "v1.2"}, new String[]{prev2, prev1, now});

        // 3. 火焰烟雾检测
        resetAndCreateModel("3", "火焰烟雾检测", "v2.3", "ready", prev2, 
            new String[]{"v2.0", "v2.1", "v2.3"}, new String[]{prev2, prev1, now});
    }

    private void resetAndCreateModel(String id, String name, String version, String status, String createTime, String[] versions, String[] times) {
        // Clean up existing data for this ID
        aiModelMapper.deleteVersionsByModelId(id);
        aiModelMapper.deleteModelById(id);

        AiModel model = new AiModel();
        model.setId(id);
        model.setName(name);
        model.setVersion(version);
        model.setStatus(status);
        model.setCreateTime(createTime);
        aiModelMapper.insertModel(model);

        for (int i = 0; i < versions.length; i++) {
            AiModelVersion v = new AiModelVersion();
            v.setId(UUID.randomUUID().toString());
            v.setModelId(id);
            v.setVersion(versions[i]);
            v.setStatus("completed");
            v.setCreateTime(times[i]);
            v.setFinishTime(times[i]); // Simplification
            v.setAccuracy(0.85 + (i * 0.03)); // Increasing accuracy
            v.setLoss(0.2 - (i * 0.02));
            v.setFilePath("/models/" + name + "/" + versions[i] + ".pt");
            aiModelMapper.insertVersion(v);
        }
    }
}
