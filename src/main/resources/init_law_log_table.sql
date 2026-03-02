DROP TABLE IF EXISTS law_enforcement_log;
CREATE TABLE law_enforcement_log (
  id bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
  case_id varchar(64) DEFAULT NULL COMMENT '关联案件ID',
  operation_type varchar(50) DEFAULT NULL COMMENT '操作类型',
  operator varchar(50) DEFAULT NULL COMMENT '操作人',
  operation_time datetime DEFAULT NULL COMMENT '操作时间',
  ip_address varchar(50) DEFAULT NULL COMMENT 'IP地址',
  details text COMMENT '操作详情',
  block_hash varchar(64) DEFAULT NULL COMMENT '当前区块哈希',
  previous_hash varchar(64) DEFAULT NULL COMMENT '上一区块哈希',
  PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='执法操作日志';
