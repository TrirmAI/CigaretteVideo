CREATE TABLE IF NOT EXISTS wvp_case_event (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    type VARCHAR(50),
    time VARCHAR(50),
    location VARCHAR(255),
    status INT DEFAULT 1,
    description TEXT,
    create_time VARCHAR(50),
    update_time VARCHAR(50)
);

CREATE TABLE IF NOT EXISTS wvp_case_evidence (
    id VARCHAR(50) PRIMARY KEY,
    case_id VARCHAR(50) NOT NULL,
    record_id INT NOT NULL,
    type VARCHAR(20) DEFAULT 'video',
    description TEXT,
    create_time VARCHAR(50),
    update_time VARCHAR(50)
);
