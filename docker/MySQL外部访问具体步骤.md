# MySQL外部访问具体步骤

## ⚠️ 重要提示

如果外部无法访问MySQL，**最可能的原因是云服务器安全组未开放3306端口**。

服务器端配置已完成：
- ✅ MySQL容器端口映射：`0.0.0.0:3306->3306/tcp`
- ✅ 防火墙规则：`3306/tcp` 已开放
- ✅ MySQL用户权限：`root@%` 和 `wvp_user@%` 已配置

## 第一步：配置云服务器安全组（必须）

### 阿里云ECS配置步骤

1. **登录阿里云控制台**
   - 访问：https://ecs.console.aliyun.com/

2. **找到服务器实例**
   - 进入"云服务器ECS" → "实例"
   - 找到IP为 `172.31.127.47` 的实例

3. **配置安全组**
   - 点击实例ID进入详情页
   - 点击"安全组"标签页
   - 点击安全组ID进入安全组配置

4. **添加入站规则**
   - 点击"入方向" → "手动添加"
   - 配置如下：
     ```
     规则方向：入方向
     授权策略：允许
     优先级：1（默认）
     协议类型：MySQL(3306) 或 自定义TCP
     端口范围：3306/3306
     授权对象：0.0.0.0/0（允许所有IP）或 特定IP/32
     描述：MySQL数据库访问
     ```
   - 点击"保存"

### 腾讯云CVM配置步骤

1. **登录腾讯云控制台**
   - 访问：https://console.cloud.tencent.com/cvm

2. **找到服务器实例**
   - 进入"云服务器" → "实例"
   - 找到IP为 `172.31.127.47` 的实例

3. **配置安全组**
   - 点击实例ID进入详情页
   - 点击"安全组"标签页
   - 点击安全组名称进入配置

4. **添加入站规则**
   - 点击"入站规则" → "添加规则"
   - 配置如下：
     ```
     类型：自定义
     来源：0.0.0.0/0（允许所有IP）或 特定IP/32
     协议端口：TCP:3306
     策略：允许
     备注：MySQL数据库访问
     ```
   - 点击"完成"

### AWS EC2配置步骤

1. **登录AWS控制台**
   - 访问：https://console.aws.amazon.com/ec2/

2. **找到服务器实例**
   - 进入"EC2" → "实例"
   - 找到IP为 `172.31.127.47` 的实例

3. **配置安全组**
   - 选择实例，点击"安全"标签页
   - 点击安全组名称进入配置

4. **添加入站规则**
   - 点击"入站规则" → "编辑入站规则" → "添加规则"
   - 配置如下：
     ```
     类型：MySQL/Aurora
     协议：TCP
     端口范围：3306
     来源：0.0.0.0/0（允许所有IP）或 特定IP/32
     描述：MySQL数据库访问
     ```
   - 点击"保存规则"

## 第二步：测试连接

### 方法1：使用命令行测试（推荐）

#### macOS/Linux
```bash
# 安装MySQL客户端（如果未安装）
# macOS
brew install mysql-client

# Ubuntu/Debian
sudo apt-get install mysql-client

# CentOS/RHEL
sudo yum install mysql

# 测试连接（root用户）
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 测试连接（wvp_user用户）
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

#### Windows
```bash
# 下载MySQL客户端：https://dev.mysql.com/downloads/mysql/
# 或使用MySQL Workbench

# 测试连接（root用户）
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 测试连接（wvp_user用户）
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

### 方法2：使用telnet/nc测试端口连通性

```bash
# 使用telnet测试
telnet 172.31.127.47 3306

# 或使用nc测试
nc -zv 172.31.127.47 3306

# 如果连接成功，会显示：
# Connected to 172.31.127.47
# 或
# 172.31.127.47:3306 open
```

### 方法3：使用MySQL Workbench

1. **下载安装**：https://www.mysql.com/products/workbench/
2. **创建连接**：
   - 点击"+"创建新连接
   - **Connection Name**：`WVP Remote`
   - **Hostname**：`172.31.127.47`
   - **Port**：`3306`
   - **Username**：`root`
   - **Password**：点击"Store in Keychain"，输入 `root`
   - 点击"Test Connection"
   - 如果成功，点击"OK"保存并连接

### 方法4：使用Navicat

1. **打开Navicat**
2. **创建连接**：
   - 点击"连接" → "MySQL"
   - **连接名**：`WVP Remote`
   - **主机**：`172.31.127.47`
   - **端口**：`3306`
   - **用户名**：`root`
   - **密码**：`root`
   - 点击"测试连接"
   - 如果成功，点击"确定"保存并连接

## 连接信息总结

### 服务器信息
- **IP地址**：`172.31.127.47`
- **端口**：`3306`
- **数据库名**：`wvp`

### 用户账号

#### root用户（管理员）
```
用户名：root
密码：root
权限：所有数据库的所有权限
```

#### wvp_user用户（应用用户）
```
用户名：wvp_user
密码：wvp_password
权限：wvp数据库的所有权限
```

### 连接命令

#### 命令行连接
```bash
# root用户
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# wvp_user用户
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

#### JDBC连接字符串
```
jdbc:mysql://172.31.127.47:3306/wvp?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true
```

## 故障排查

### 如果仍然无法连接，请检查：

1. **云服务器安全组**（最重要）
   - 确保安全组已开放3306端口
   - 检查规则是否生效

2. **端口连通性**
   ```bash
   telnet 172.31.127.47 3306
   # 或
   nc -zv 172.31.127.47 3306
   ```

3. **服务器端配置**（已在服务器上验证正常）
   ```bash
   # 检查端口映射
   docker ps --filter 'name=polaris-mysql' --format '{{.Ports}}'
   
   # 检查防火墙规则
   firewall-cmd --list-ports | grep 3306
   
   # 检查MySQL用户权限
   docker exec polaris-mysql mysql -uroot -proot -e "SELECT User, Host FROM mysql.user WHERE User IN ('root', 'wvp_user');"
   ```

## 快速测试脚本

在本地执行：
```bash
cd /Users/andyapple/Downloads/wvp-GB28181-pro/docker
./test-mysql-connection.sh
```

## 常见错误

### 错误：`Can't connect to MySQL server`
**原因**：安全组未开放或端口不通
**解决**：配置云服务器安全组，开放3306端口

### 错误：`Access denied`
**原因**：用户名或密码错误
**解决**：使用正确的用户名和密码

### 错误：`Host 'xxx' is not allowed`
**原因**：MySQL用户权限限制（已配置为允许所有主机）
**解决**：已在服务器上配置，如仍有问题请检查MySQL用户权限

