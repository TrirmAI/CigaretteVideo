# MySQL外部访问完整指南

## 当前配置状态

✅ **已完成的配置**：
- MySQL容器端口映射：`0.0.0.0:3306->3306/tcp`
- 防火墙规则：`3306/tcp` 已开放
- MySQL用户权限：`root@%` 和 `wvp_user@%` 已配置
- MySQL bind_address：`*`（监听所有接口）

## 连接信息

### 服务器信息
- **IP地址**：`172.31.127.47`
- **端口**：`3306`
- **数据库名**：`wvp`

### 用户账号

#### 1. root用户（管理员）
- **用户名**：`root`
- **密码**：`root`
- **权限**：所有数据库的所有权限

#### 2. wvp_user用户（应用用户）
- **用户名**：`wvp_user`
- **密码**：`wvp_password`
- **权限**：wvp数据库的所有权限

## 连接方式

### 方式1：命令行连接（MySQL客户端）

#### macOS
```bash
# 安装MySQL客户端（如果未安装）
brew install mysql-client

# 使用root用户连接
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 使用wvp_user用户连接
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

#### Linux
```bash
# 安装MySQL客户端（如果未安装）
# Ubuntu/Debian
sudo apt-get install mysql-client

# CentOS/RHEL
sudo yum install mysql

# 使用root用户连接
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 使用wvp_user用户连接
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

#### Windows
```bash
# 下载MySQL客户端：https://dev.mysql.com/downloads/mysql/
# 或使用MySQL Workbench

# 使用root用户连接
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 使用wvp_user用户连接
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

### 方式2：MySQL Workbench

1. **下载安装**：https://www.mysql.com/products/workbench/
2. **创建连接**：
   - 点击"+"创建新连接
   - **Connection Name**：`WVP Remote`
   - **Hostname**：`172.31.127.47`
   - **Port**：`3306`
   - **Username**：`root` 或 `wvp_user`
   - **Password**：点击"Store in Keychain"保存密码
   - **Default Schema**：`wvp`（如果使用wvp_user）
3. **测试连接**：点击"Test Connection"
4. **连接**：点击"OK"保存并连接

### 方式3：Navicat

1. **打开Navicat**
2. **创建连接**：
   - 点击"连接" → "MySQL"
   - **连接名**：`WVP Remote`
   - **主机**：`172.31.127.47`
   - **端口**：`3306`
   - **用户名**：`root` 或 `wvp_user`
   - **密码**：`root` 或 `wvp_password`
   - **数据库**：`wvp`（如果使用wvp_user）
3. **测试连接**：点击"测试连接"
4. **确定**：点击"确定"保存并连接

### 方式4：DBeaver

1. **打开DBeaver**
2. **新建连接**：
   - 点击"新建连接" → "MySQL"
   - **服务器主机**：`172.31.127.47`
   - **端口**：`3306`
   - **数据库**：`wvp`
   - **用户名**：`root` 或 `wvp_user`
   - **密码**：`root` 或 `wvp_password`
3. **测试连接**：点击"测试连接"
4. **完成**：点击"完成"保存并连接

### 方式5：JDBC连接字符串

#### Java应用
```java
// 使用root用户
String url = "jdbc:mysql://172.31.127.47:3306/wvp?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true";
String username = "root";
String password = "root";

// 使用wvp_user用户
String url = "jdbc:mysql://172.31.127.47:3306/wvp?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true";
String username = "wvp_user";
String password = "wvp_password";
```

#### Python应用
```python
import pymysql

# 使用root用户
connection = pymysql.connect(
    host='172.31.127.47',
    port=3306,
    user='root',
    password='root',
    database='wvp',
    charset='utf8mb4'
)

# 使用wvp_user用户
connection = pymysql.connect(
    host='172.31.127.47',
    port=3306,
    user='wvp_user',
    password='wvp_password',
    database='wvp',
    charset='utf8mb4'
)
```

## 故障排查

### 如果连接被拒绝，请按以下步骤检查：

#### 步骤1：检查端口连通性

```bash
# 使用telnet测试
telnet 172.31.127.47 3306

# 或使用nc测试
nc -zv 172.31.127.47 3306

# 或使用curl测试
curl -v telnet://172.31.127.47:3306
```

**如果端口不通**，可能是：
1. **云服务器安全组未开放**（最常见原因）
   - 登录云服务器控制台（阿里云/腾讯云/AWS等）
   - 找到安全组配置
   - 添加入站规则：端口3306，协议TCP，源地址0.0.0.0/0（或特定IP）

2. **服务器防火墙规则**
   - 已在服务器上配置firewalld规则
   - 如果仍不通，检查是否有其他防火墙（iptables等）

#### 步骤2：检查MySQL配置

在服务器上执行：
```bash
# 检查端口映射
docker ps --filter 'name=polaris-mysql' --format '{{.Ports}}'
# 应该显示：0.0.0.0:3306->3306/tcp

# 检查端口监听
ss -tlnp | grep 3306
# 应该显示：0.0.0.0:3306

# 检查防火墙规则
firewall-cmd --list-ports | grep 3306
# 应该显示：3306/tcp

# 检查MySQL用户权限
docker exec polaris-mysql mysql -uroot -proot -e "SELECT User, Host FROM mysql.user WHERE User IN ('root', 'wvp_user');"
# 应该显示包含 % 的记录
```

#### 步骤3：云服务器安全组配置

**阿里云ECS**：
1. 登录阿里云控制台
2. 进入"云服务器ECS" → "实例"
3. 找到服务器实例，点击"安全组"
4. 点击"配置规则" → "入方向" → "添加安全组规则"
5. 配置：
   - **规则方向**：入方向
   - **授权策略**：允许
   - **协议类型**：MySQL(3306)
   - **端口范围**：3306/3306
   - **授权对象**：0.0.0.0/0（或特定IP）
6. 点击"保存"

**腾讯云CVM**：
1. 登录腾讯云控制台
2. 进入"云服务器" → "实例"
3. 找到服务器实例，点击"安全组"
4. 点击"修改规则" → "入站规则" → "添加规则"
5. 配置：
   - **类型**：自定义
   - **来源**：0.0.0.0/0（或特定IP）
   - **协议端口**：TCP:3306
   - **策略**：允许
6. 点击"完成"

**AWS EC2**：
1. 登录AWS控制台
2. 进入"EC2" → "实例"
3. 选择实例，点击"安全"标签页
4. 点击安全组名称
5. 点击"入站规则" → "编辑入站规则" → "添加规则"
6. 配置：
   - **类型**：MySQL/Aurora
   - **协议**：TCP
   - **端口范围**：3306
   - **来源**：0.0.0.0/0（或特定IP）
7. 点击"保存规则"

## 快速测试脚本

在本地执行测试脚本：
```bash
cd /Users/andyapple/Downloads/wvp-GB28181-pro/docker
./test-mysql-connection.sh
```

## 常见错误及解决方案

### 错误1：`Can't connect to MySQL server on '172.31.127.47' (61)`
**原因**：端口未开放或安全组未配置
**解决**：检查云服务器安全组配置

### 错误2：`Access denied for user 'root'@'xxx.xxx.xxx.xxx'`
**原因**：用户权限未配置或密码错误
**解决**：检查MySQL用户权限配置

### 错误3：`Host 'xxx.xxx.xxx.xxx' is not allowed to connect to this MySQL server`
**原因**：MySQL用户Host限制
**解决**：确保用户有`%`权限（已配置）

## 安全建议

⚠️ **重要**：对外开放MySQL端口存在安全风险，强烈建议：

1. **修改默认密码**：使用强密码
2. **限制访问IP**：只允许特定IP访问
3. **使用SSL连接**：配置MySQL SSL
4. **定期备份**：定期备份数据库
5. **监控访问日志**：监控异常访问
6. **使用VPN**：通过VPN访问数据库

