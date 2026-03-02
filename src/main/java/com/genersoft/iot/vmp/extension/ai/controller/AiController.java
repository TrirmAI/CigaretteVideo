package com.genersoft.iot.vmp.extension.ai.controller;

import com.genersoft.iot.vmp.extension.ai.bean.AiAlert;
import com.genersoft.iot.vmp.extension.ai.bean.AiModel;
import com.genersoft.iot.vmp.extension.ai.service.AiService;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

import com.genersoft.iot.vmp.extension.ai.bean.AiModelVersion;

@Tag(name = "AI大模型集成")
@RestController
@RequestMapping("/api/ext/ai")
public class AiController {

    @Autowired
    private AiService aiService;

    @Operation(summary = "自然语言交互")
    @PostMapping("/chat")
    public String chat(@RequestParam String message) {
        return aiService.chat(message);
    }

    @Operation(summary = "获取告警")
    @GetMapping("/alerts")
    public List<AiAlert> getAlerts() {
        return aiService.getAlerts();
    }

    @Operation(summary = "获取模型列表")
    @GetMapping("/models")
    public List<AiModel> getModels() {
        return aiService.getModels();
    }

    @Operation(summary = "创建模型")
    @PostMapping("/models")
    public String createModel(@RequestBody AiModel model) {
        aiService.addModel(model);
        return "success";
    }

    @Operation(summary = "获取模型历史版本")
    @GetMapping("/models/{modelId}/history")
    public List<AiModelVersion> getModelHistory(@PathVariable String modelId) {
        return aiService.getHistory(modelId);
    }

    @Operation(summary = "提交训练任务")
    @PostMapping("/train")
    public String train(@RequestParam String modelName) {
        aiService.train(modelName);
        return "训练任务已提交";
    }
}
