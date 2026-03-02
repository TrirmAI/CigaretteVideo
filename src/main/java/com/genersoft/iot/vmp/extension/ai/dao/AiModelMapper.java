package com.genersoft.iot.vmp.extension.ai.dao;

import com.genersoft.iot.vmp.extension.ai.bean.AiModel;
import com.genersoft.iot.vmp.extension.ai.bean.AiModelVersion;
import org.apache.ibatis.annotations.*;
import org.springframework.stereotype.Repository;

import java.util.List;

@Mapper
@Repository
public interface AiModelMapper {

    @Update("DROP TABLE IF EXISTS wvp_ai_model")
    void dropModelTable();

    @Update("DROP TABLE IF EXISTS wvp_ai_model_version")
    void dropVersionTable();

    @Update("CREATE TABLE IF NOT EXISTS wvp_ai_model (" +
            "id VARCHAR(50) PRIMARY KEY, " +
            "name VARCHAR(100), " +
            "version VARCHAR(50), " + // Current latest version
            "status VARCHAR(20), " + // Current status
            "create_time VARCHAR(20))")
    void createModelTable();

    @Update("CREATE TABLE IF NOT EXISTS wvp_ai_model_version (" +
            "id VARCHAR(50) PRIMARY KEY, " +
            "model_id VARCHAR(50), " +
            "version VARCHAR(50), " +
            "status VARCHAR(20), " +
            "create_time VARCHAR(20), " +
            "finish_time VARCHAR(20), " +
            "accuracy DOUBLE, " +
            "loss DOUBLE, " +
            "file_path VARCHAR(255))")
    void createVersionTable();

    @Insert("INSERT INTO wvp_ai_model (id, name, version, status, create_time) VALUES (#{id}, #{name}, #{version}, #{status}, #{createTime})")
    int insertModel(AiModel model);

    @Update("UPDATE wvp_ai_model SET version=#{version}, status=#{status} WHERE id=#{id}")
    int updateModelStatus(AiModel model);

    @Select("SELECT * FROM wvp_ai_model")
    List<AiModel> selectAllModels();

    @Select("SELECT * FROM wvp_ai_model WHERE id = #{id}")
    AiModel selectModelById(String id);
    
    @Select("SELECT * FROM wvp_ai_model WHERE name = #{name}")
    AiModel selectModelByName(String name);

    @Insert("INSERT INTO wvp_ai_model_version (id, model_id, version, status, create_time, finish_time, accuracy, loss, file_path) " +
            "VALUES (#{id}, #{modelId}, #{version}, #{status}, #{createTime}, #{finishTime}, #{accuracy}, #{loss}, #{filePath})")
    int insertVersion(AiModelVersion version);

    @Update("UPDATE wvp_ai_model_version SET status=#{status}, finish_time=#{finishTime}, accuracy=#{accuracy}, loss=#{loss}, file_path=#{filePath} WHERE id=#{id}")
    int updateVersion(AiModelVersion version);

    @Select("SELECT * FROM wvp_ai_model_version WHERE model_id = #{modelId} ORDER BY create_time DESC")
    List<AiModelVersion> selectVersionsByModelId(String modelId);

    @Delete("DELETE FROM wvp_ai_model WHERE id=#{id}")
    int deleteModelById(String id);

    @Delete("DELETE FROM wvp_ai_model_version WHERE model_id=#{modelId}")
    int deleteVersionsByModelId(String modelId);
}
