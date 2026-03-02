CREATE TABLE IF NOT EXISTS wvp_law_enforcement_log (
    id VARCHAR(50) PRIMARY KEY,
    case_id VARCHAR(50) NOT NULL,
    operation_type VARCHAR(50),
    operator VARCHAR(100),
    operation_time VARCHAR(50),
    ip_address VARCHAR(50),
    details TEXT,
    block_hash VARCHAR(255),
    previous_hash VARCHAR(255)
);
