# MySQL端口对外开放配置说明

## 配置内容

### 1. 修改启动脚本
在 `start-remote-docker.sh` 中为MySQL容器添加端口映射：
```bash
-p 3306:3306/tcp
```

### 2. 配置防火墙规则
使用firewalld开放3306端口：
```bash
firewall-cmd --permanent --add-port=3306/tcp
firewall-cmd --reload
```

## 验证方法

1. **检查端口映射**：
   ```bash
   docker ps --filter 'name=polaris-mysql' --format '{{.Ports}}'
   ```
   应该显示：`0.0.0.0:3306->3306/tcp`

2. **检查端口监听**：
   ```bash
   ss -tlnp | grep 3306
   ```
   应该显示：`0.0.0.0:3306`

3. **测试外部连接**：
   ```bash
   mysql -h 172.31.127.47 -P 3306 -u wvp_user -pwvp_password
   ```

## 安全建议

⚠️ **重要**：对外开放MySQL端口存在安全风险，建议：

1. **使用强密码**：确保MySQL用户密码足够复杂
2. **限制访问IP**：使用防火墙规则限制特定IP访问
3. **使用SSL连接**：配置MySQL SSL连接
4. **定期更新**：保持MySQL版本更新

## 限制特定IP访问示例

如果需要限制只有特定IP可以访问：
```bash
# 允许特定IP访问3306端口
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" source address="<允许的IP>" port port="3306" protocol="tcp" accept'

# 拒绝其他IP访问
firewall-cmd --permanent --add-rich-rule='rule family="ipv4" port port="3306" protocol="tcp" reject'

firewall-cmd --reload
```

