DROP TABLE IF EXISTS sys_oper_log;
CREATE TABLE sys_oper_log (
  id bigint NOT NULL AUTO_INCREMENT COMMENT '日志主键',
  title varchar(50) DEFAULT '' COMMENT '模块标题',
  business_type int DEFAULT 0 COMMENT '业务类型（0其它 1新增 2修改 3删除 4授权 5导出 6导入 7强退 8生成代码 9清空数据）',
  method varchar(100) DEFAULT '' COMMENT '方法名称',
  request_method varchar(10) DEFAULT '' COMMENT '请求方式',
  operator_type int DEFAULT 0 COMMENT '操作类别（0其它 1后台用户 2手机端用户）',
  oper_name varchar(50) DEFAULT '' COMMENT '操作人员',
  oper_url varchar(255) DEFAULT '' COMMENT '请求URL',
  oper_ip varchar(128) DEFAULT '' COMMENT '主机地址',
  oper_location varchar(255) DEFAULT '' COMMENT '操作地点',
  oper_param text COMMENT '请求参数',
  json_result text COMMENT '返回参数',
  status int DEFAULT 0 COMMENT '操作状态（0正常 1异常）',
  error_msg varchar(2000) DEFAULT '' COMMENT '错误消息',
  oper_time datetime DEFAULT NULL COMMENT '操作时间',
  PRIMARY KEY (id)
) ENGINE=InnoDB AUTO_INCREMENT=100 DEFAULT CHARSET=utf8mb4 COMMENT='操作日志记录';
