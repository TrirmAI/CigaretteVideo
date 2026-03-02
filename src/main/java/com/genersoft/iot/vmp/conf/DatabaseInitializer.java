package com.genersoft.iot.vmp.conf;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import javax.sql.DataSource;
import java.sql.Connection;
import java.sql.Statement;

@Component
public class DatabaseInitializer {

    @Autowired
    private DataSource dataSource;

    @PostConstruct
    public void init() {
        try (Connection connection = dataSource.getConnection();
             Statement statement = connection.createStatement()) {
            
            String sql = "CREATE TABLE IF NOT EXISTS wvp_law_enforcement_log (" +
                    "    id VARCHAR(50) PRIMARY KEY," +
                    "    case_id VARCHAR(50) NOT NULL," +
                    "    operation_type VARCHAR(50)," +
                    "    operator VARCHAR(100)," +
                    "    operation_time VARCHAR(50)," +
                    "    ip_address VARCHAR(50)," +
                    "    details TEXT," +
                    "    block_hash VARCHAR(255)," +
                    "    previous_hash VARCHAR(255)" +
                    ")";
            
            statement.execute(sql);
            System.out.println("Table wvp_law_enforcement_log checked/created successfully.");
            
        } catch (Exception e) {
            e.printStackTrace();
        }
    }
}
