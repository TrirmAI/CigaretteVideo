# 字符集修复完成报告

## 修复内容

### 1. 数据库字符集修复
- 数据库 `wvp` 字符集已设置为: `utf8mb4`
- 所有表字符集已转换为: `utf8mb4_general_ci`

### 2. 数据重新同步
- 使用正确的UTF-8编码重新同步了业务分组数据
- 共同步 54 条记录

### 3. WVP应用配置更新
- 更新了 `application-docker.yml` 中的数据库连接URL
- 添加了 `characterEncoding=utf8mb4` 和 `connectionCollation=utf8mb4_general_ci` 参数

## 验证方法

### 方法1: 直接查询数据库
```bash
ssh root@172.31.127.47
cd /home/wvp/docker
docker exec polaris-mysql mysql -uwvp_user -pwvp_password --default-character-set=utf8mb4 -Dwvp -e "SET NAMES utf8mb4; SELECT id, name FROM wvp_common_group LIMIT 10;"
```

### 方法2: 通过WVP Web界面
访问 http://172.31.127.47:18978，查看业务分组管理页面，中文应正常显示。

## 注意事项

1. **查询数据库时**必须使用 `--default-character-set=utf8mb4` 参数
2. **WVP应用**已配置正确的字符集，重启后会自动使用UTF-8连接
3. **如果仍有乱码**，请检查：
   - 浏览器编码设置（应使用UTF-8）
   - 终端编码设置（应使用UTF-8）
   - WVP服务日志中是否有字符集相关错误

## 已修复的文件

- `/home/wvp/docker/wvp/wvp/application-docker.yml` - WVP数据库连接配置
- `/home/wvp/docker/fix-charset.sql` - 字符集修复SQL脚本

## 相关脚本

- `sync-common-group.py` - 数据同步脚本（已更新支持UTF-8）
- `fix-database-charset.sh` - 字符集修复脚本

