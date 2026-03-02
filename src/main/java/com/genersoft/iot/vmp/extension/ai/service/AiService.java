package com.genersoft.iot.vmp.extension.ai.service;

import com.genersoft.iot.vmp.extension.ai.bean.AiAlert;
import com.genersoft.iot.vmp.extension.ai.bean.AiModel;
import com.genersoft.iot.vmp.extension.ai.bean.AiModelVersion;
import java.util.List;

public interface AiService {
    String chat(String message);
    List<AiAlert> getAlerts();
    List<AiModel> getModels();
    void train(String modelName);
    List<AiModelVersion> getHistory(String modelId);
    void addModel(AiModel model);
}
