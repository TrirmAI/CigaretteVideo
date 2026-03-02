package com.genersoft.iot.vmp.extension.cases.bean;

import io.swagger.v3.oas.annotations.media.Schema;
import java.util.Date;

@Schema(description = "执法操作日志")
public class LawEnforcementLog {

    @Schema(description = "主键")
    private String id;

    @Schema(description = "关联案件ID")
    private String caseId;

    @Schema(description = "操作类型")
    private String operationType;

    @Schema(description = "操作人")
    private String operator;

    @Schema(description = "操作时间")
    private Date operationTime;

    @Schema(description = "IP地址")
    private String ipAddress;

    @Schema(description = "操作详情")
    private String details;

    @Schema(description = "当前区块哈希")
    private String blockHash;

    @Schema(description = "上一区块哈希")
    private String previousHash;

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getCaseId() {
        return caseId;
    }

    public void setCaseId(String caseId) {
        this.caseId = caseId;
    }

    public String getOperationType() {
        return operationType;
    }

    public void setOperationType(String operationType) {
        this.operationType = operationType;
    }

    public String getOperator() {
        return operator;
    }

    public void setOperator(String operator) {
        this.operator = operator;
    }

    public Date getOperationTime() {
        return operationTime;
    }

    public void setOperationTime(Date operationTime) {
        this.operationTime = operationTime;
    }

    public String getIpAddress() {
        return ipAddress;
    }

    public void setIpAddress(String ipAddress) {
        this.ipAddress = ipAddress;
    }

    public String getDetails() {
        return details;
    }

    public void setDetails(String details) {
        this.details = details;
    }

    public String getBlockHash() {
        return blockHash;
    }

    public void setBlockHash(String blockHash) {
        this.blockHash = blockHash;
    }

    public String getPreviousHash() {
        return previousHash;
    }

    public void setPreviousHash(String previousHash) {
        this.previousHash = previousHash;
    }
}
