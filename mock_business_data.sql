-- 插入执法日志数据 (模拟近7天数据)
INSERT INTO wvp_law_enforcement_log (id, case_id, operation_type, operator, operation_time, ip_address, details) VALUES
(1001, 'CASE001', 'VIDEO_VIEW', 'admin', DATE_SUB(NOW(), INTERVAL 0 DAY), '192.168.1.10', '查看实时视频'),
(1002, 'CASE001', 'VIDEO_PLAYBACK', 'admin', DATE_SUB(NOW(), INTERVAL 0 DAY), '192.168.1.10', '回放录像'),
(1003, 'CASE002', 'EVIDENCE_UPLOAD', 'user1', DATE_SUB(NOW(), INTERVAL 1 DAY), '192.168.1.11', '上传证据视频'),
(1004, 'CASE003', 'CASE_CREATE', 'user2', DATE_SUB(NOW(), INTERVAL 1 DAY), '192.168.1.12', '创建新案件'),
(1005, 'CASE004', 'VIDEO_VIEW', 'admin', DATE_SUB(NOW(), INTERVAL 2 DAY), '192.168.1.10', '查看实时视频'),
(1006, 'CASE005', 'VIDEO_VIEW', 'user1', DATE_SUB(NOW(), INTERVAL 2 DAY), '192.168.1.11', '查看实时视频'),
(1007, 'CASE006', 'CASE_UPDATE', 'user2', DATE_SUB(NOW(), INTERVAL 3 DAY), '192.168.1.12', '更新案件状态'),
(1008, 'CASE007', 'VIDEO_PLAYBACK', 'admin', DATE_SUB(NOW(), INTERVAL 3 DAY), '192.168.1.10', '回放录像'),
(1009, 'CASE008', 'VIDEO_VIEW', 'user1', DATE_SUB(NOW(), INTERVAL 4 DAY), '192.168.1.11', '查看实时视频'),
(1010, 'CASE009', 'EVIDENCE_UPLOAD', 'user2', DATE_SUB(NOW(), INTERVAL 4 DAY), '192.168.1.12', '上传现场照片'),
(1011, 'CASE010', 'VIDEO_VIEW', 'admin', DATE_SUB(NOW(), INTERVAL 5 DAY), '192.168.1.10', '查看实时视频'),
(1012, 'CASE011', 'CASE_CLOSE', 'user1', DATE_SUB(NOW(), INTERVAL 5 DAY), '192.168.1.11', '结案归档'),
(1013, 'CASE012', 'VIDEO_VIEW', 'user2', DATE_SUB(NOW(), INTERVAL 6 DAY), '192.168.1.12', '查看实时视频'),
(1014, 'CASE013', 'VIDEO_PLAYBACK', 'admin', DATE_SUB(NOW(), INTERVAL 6 DAY), '192.168.1.10', '回放录像');

-- 插入案事件数据
INSERT INTO wvp_case_event (id, name, type, time, location, status, description, create_time, update_time) VALUES
('CASE001', '东门非法闯入事件', '非法入侵', NOW(), '东门入口', 1, '发现不明人员闯入', NOW(), NOW()),
('CASE002', '西侧围栏破坏', '非法入侵', DATE_SUB(NOW(), INTERVAL 1 DAY), '西侧围栏', 2, '围栏被人为破坏', NOW(), NOW()),
('CASE003', '消防通道违停', '车辆违停', DATE_SUB(NOW(), INTERVAL 2 DAY), '消防通道', 1, '车辆占用消防通道', NOW(), NOW()),
('CASE004', '广场人员非法聚集', '人员聚集', DATE_SUB(NOW(), INTERVAL 3 DAY), '中心广场', 3, '超过50人聚集', NOW(), NOW()),
('CASE005', '仓库吸烟检测', '烟火检测', DATE_SUB(NOW(), INTERVAL 4 DAY), '一号仓库', 1, '检测到明火', NOW(), NOW()),
('CASE006', '北门车辆违停', '车辆违停', DATE_SUB(NOW(), INTERVAL 5 DAY), '北门出口', 2, '车辆堵塞出口', NOW(), NOW()),
('CASE007', '办公楼非法入侵', '非法入侵', DATE_SUB(NOW(), INTERVAL 6 DAY), '办公楼大厅', 3, '非授权人员进入', NOW(), NOW()),
('CASE008', '停车场烟火报警', '烟火检测', NOW(), '地下停车场', 1, '烟感报警', NOW(), NOW());

-- 插入证据数据
INSERT INTO wvp_case_evidence (id, case_id, record_id, type, description, create_time, update_time) VALUES
('EVI001', 'CASE001', 101, 'video', '闯入现场视频', NOW(), NOW()),
('EVI002', 'CASE001', 102, 'image', '闯入者面部截图', NOW(), NOW()),
('EVI003', 'CASE003', 103, 'image', '违停车辆车牌', NOW(), NOW()),
('EVI004', 'CASE005', 104, 'video', '吸烟检测录像', NOW(), NOW()),
('EVI005', 'CASE008', 105, 'video', '烟感报警联动视频', NOW(), NOW());
