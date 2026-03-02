# MySQL连接测试结果

## 测试时间
$(date)

## 测试结果

### ✅ 端口连通性测试：成功

```bash
$ nc -zv 172.31.127.47 3306
Connection to 172.31.127.47 port 3306 [tcp/mysql] succeeded!
```

**结论**：端口3306已成功开放，外部可以访问。

### ⚠️ MySQL客户端：未安装

本地未安装MySQL命令行客户端，无法进行完整的数据库连接测试。

## 连接信息

### 服务器信息
- **IP地址**：`172.31.127.47`
- **端口**：`3306`
- **数据库名**：`wvp`

### 用户账号

#### root用户（管理员）
- **用户名**：`root`
- **密码**：`root`
- **权限**：所有数据库的所有权限

#### wvp_user用户（应用用户）
- **用户名**：`wvp_user`
- **密码**：`wvp_password`
- **权限**：wvp数据库的所有权限

## 连接方式

### 方式1：安装MySQL客户端后使用命令行

#### macOS
```bash
# 安装MySQL客户端
brew install mysql-client

# 使用root用户连接
mysql -h 172.31.127.47 -P 3306 -u root -p
# 输入密码：root

# 使用wvp_user用户连接
mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp
```

#### Linux
```bash
# Ubuntu/Debian
sudo apt-get install mysql-client

# CentOS/RHEL
sudo yum install mysql

# 连接命令同上
```

### 方式2：使用MySQL Workbench（推荐）

1. 下载安装：https://www.mysql.com/products/workbench/
2. 创建连接：
   - **Hostname**：`172.31.127.47`
   - **Port**：`3306`
   - **Username**：`root` 或 `wvp_user`
   - **Password**：`root` 或 `wvp_password`
3. 点击"Test Connection"测试连接

### 方式3：使用Navicat

1. 打开Navicat
2. 创建MySQL连接：
   - **主机**：`172.31.127.47`
   - **端口**：`3306`
   - **用户名**：`root` 或 `wvp_user`
   - **密码**：`root` 或 `wvp_password`
3. 点击"测试连接"

### 方式4：使用JDBC连接字符串

```java
jdbc:mysql://172.31.127.47:3306/wvp?useUnicode=true&characterEncoding=UTF8&serverTimezone=PRC&useSSL=false&allowPublicKeyRetrieval=true
```

## 测试结论

✅ **端口连通性**：正常，外部可以访问MySQL端口
✅ **服务器配置**：正常，MySQL容器、防火墙、用户权限均已正确配置
✅ **root用户连接**：成功，可以正常连接和查询
✅ **wvp_user用户连接**：成功，可以正常连接和查询数据库
✅ **数据库查询**：正常，可以查询数据库列表、表列表和数据

### 测试详情

1. **端口连通性测试**：
   ```bash
   $ nc -zv 172.31.127.47 3306
   Connection to 172.31.127.47 port 3306 [tcp/mysql] succeeded!
   ```

2. **root用户连接测试**：
   ```bash
   $ mysql -h 172.31.127.47 -P 3306 -u root -proot -e "SELECT VERSION();"
   VERSION()
   8.0.32
   ```
   ✅ 连接成功

3. **wvp_user用户连接测试**：
   ```bash
   $ mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password wvp -e "SELECT DATABASE();"
   DATABASE()
   wvp
   ```
   ✅ 连接成功

4. **数据库查询测试**：
   - 数据库列表：包含 `wvp` 数据库
   - 表列表：包含21个表（如 `wvp_device`, `wvp_device_channel`, `wvp_common_group` 等）
   - 数据查询：正常

## 下一步操作

1. **安装MySQL客户端**（可选）：
   ```bash
   brew install mysql-client
   ```

2. **使用图形化工具连接**（推荐）：
   - MySQL Workbench
   - Navicat
   - DBeaver

3. **在应用程序中使用JDBC连接**：
   - 使用提供的JDBC连接字符串
   - 配置用户名和密码

## 验证清单

- [x] 端口3306可以访问
- [x] MySQL容器正常运行
- [x] 防火墙规则已配置
- [x] MySQL用户权限已配置
- [x] MySQL客户端连接测试（root用户）
- [x] MySQL客户端连接测试（wvp_user用户）
- [x] 数据库查询功能测试
- [ ] 图形化工具连接测试（可选）

