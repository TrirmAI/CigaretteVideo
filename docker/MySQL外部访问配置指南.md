# MySQL外部访问配置指南

## 连接信息

- **服务器IP**：`172.31.127.47`
- **端口**：`3306`
- **数据库名**：`wvp`

### 用户账号

1. **root用户**：
   - 用户名：`root`
   - 密码：`root`
   - 权限：所有数据库的所有权限

2. **wvp_user用户**：
   - 用户名：`wvp_user`
   - 密码：`wvp_password`
   - 权限：wvp数据库的所有权限

## 连接方式

### 1. 命令行连接（MySQL客户端）

```bash
# 使用root用户连接
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 使用wvp_user用户连接
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

### 2. 使用MySQL Workbench

1. 打开MySQL Workbench
2. 点击"+"创建新连接
3. 配置连接：
   - **Connection Name**：WVP Remote
   - **Hostname**：`172.31.127.47`
   - **Port**：`3306`
   - **Username**：`root` 或 `wvp_user`
   - **Password**：点击"Store in Keychain"保存密码
4. 点击"Test Connection"测试连接
5. 点击"OK"保存并连接

### 3. 使用Navicat

1. 打开Navicat
2. 点击"连接" → "MySQL"
3. 配置连接：
   - **连接名**：WVP Remote
   - **主机**：`172.31.127.47`
   - **端口**：`3306`
   - **用户名**：`root` 或 `wvp_user`
   - **密码**：`root` 或 `wvp_password`
4. 点击"测试连接"
5. 点击"确定"保存并连接

### 4. 使用DBeaver

1. 打开DBeaver
2. 点击"新建连接" → "MySQL"
3. 配置连接：
   - **服务器主机**：`172.31.127.47`
   - **端口**：`3306`
   - **数据库**：`wvp`
   - **用户名**：`root` 或 `wvp_user`
   - **密码**：`root` 或 `wvp_password`
4. 点击"测试连接"
5. 点击"完成"保存并连接

### 5. 使用JDBC连接字符串

```java
// 使用root用户
jdbc:mysql://172.31.127.47:3306/wvp?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true
用户名：root
密码：root

// 使用wvp_user用户
jdbc:mysql://172.31.127.47:3306/wvp?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true
用户名：wvp_user
密码：wvp_password
```

### 6. 使用Python连接

```python
import pymysql

# 连接数据库
connection = pymysql.connect(
    host='172.31.127.47',
    port=3306,
    user='wvp_user',
    password='wvp_password',
    database='wvp',
    charset='utf8mb4'
)

# 执行查询
with connection.cursor() as cursor:
    cursor.execute("SELECT * FROM wvp_device LIMIT 10")
    results = cursor.fetchall()
    for row in results:
        print(row)

connection.close()
```

## 故障排查

### 如果连接被拒绝，请检查：

1. **防火墙规则**：
   ```bash
   firewall-cmd --list-ports | grep 3306
   ```
   应该显示：`3306/tcp`

2. **端口映射**：
   ```bash
   docker ps --filter 'name=polaris-mysql' --format '{{.Ports}}'
   ```
   应该显示：`0.0.0.0:3306->3306/tcp`

3. **端口监听**：
   ```bash
   ss -tlnp | grep 3306
   ```
   应该显示：`0.0.0.0:3306`

4. **MySQL用户权限**：
   ```bash
   docker exec polaris-mysql mysql -uroot -proot -e "SELECT User, Host FROM mysql.user WHERE User IN ('root', 'wvp_user');"
   ```
   应该显示包含 `%` 的记录（允许所有主机连接）

5. **云服务器安全组**：
   - 如果使用阿里云/腾讯云等云服务器，需要在安全组中开放3306端口
   - 登录云服务器控制台 → 安全组 → 添加规则 → 端口3306

## 安全建议

⚠️ **重要**：对外开放MySQL端口存在安全风险，建议：

1. **使用强密码**：修改默认密码
2. **限制访问IP**：只允许特定IP访问
3. **使用SSL连接**：配置MySQL SSL
4. **定期备份**：定期备份数据库
5. **监控访问日志**：监控异常访问

## 限制特定IP访问示例

如果需要限制只有特定IP可以访问：

```bash
# 删除允许所有IP的规则
firewall-cmd --permanent --remove-port=3306/tcp

# 只允许特定IP访问
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<允许的IP>" port port="3306" protocol="tcp" accept'

# 拒绝其他IP访问
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="3306" protocol="tcp" reject'

firewall-cmd --reload
```

