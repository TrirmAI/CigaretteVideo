#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
同步本地数据库业务分组信息到远程数据库
使用方法: python3 sync-common-group.py
"""

import pymysql
import sys
import os
from datetime import datetime

# 本地数据库配置
LOCAL_DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': '123456',
    'database': 'wvp',
    'charset': 'utf8mb4'
}

# 远程服务器配置
REMOTE_HOST = '172.31.127.47'
REMOTE_USER = 'root'
REMOTE_PASSWORD = 'Shenzhoulu9#'
REMOTE_DB_CONTAINER = 'polaris-mysql'
REMOTE_DB_CONFIG = {
    'host': 'polaris-mysql',  # 容器内使用容器名
    'port': 3306,
    'user': 'wvp_user',
    'password': 'wvp_password',
    'database': 'wvp',
    'charset': 'utf8mb4'
}

def print_colored(text, color='white'):
    """打印彩色文本"""
    colors = {
        'red': '\033[0;31m',
        'green': '\033[0;32m',
        'yellow': '\033[1;33m',
        'blue': '\033[0;34m',
        'white': '\033[0m'
    }
    print(f"{colors.get(color, '')}{text}\033[0m")

def connect_local_db():
    """连接本地数据库"""
    try:
        conn = pymysql.connect(**LOCAL_DB_CONFIG)
        print_colored("✓ 本地数据库连接成功", 'green')
        return conn
    except Exception as e:
        print_colored(f"✗ 本地数据库连接失败: {e}", 'red')
        return None

def query_local_data(conn):
    """查询本地业务分组数据"""
    try:
        cursor = conn.cursor(pymysql.cursors.DictCursor)
        cursor.execute("SELECT * FROM wvp_common_group ORDER BY id")
        data = cursor.fetchall()
        cursor.close()
        return data
    except Exception as e:
        print_colored(f"✗ 查询本地数据失败: {e}", 'red')
        return None

def generate_sql(data_list):
    """生成SQL插入语句"""
    if not data_list:
        return None
    
    sql_lines = [
        "-- 同步业务分组数据",
        "-- 生成时间: " + datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "",
        "SET NAMES utf8mb4;",
        "SET FOREIGN_KEY_CHECKS=0;",
        "",
        "-- 先删除现有数据（如果需要完全替换）",
        "DELETE FROM wvp_common_group;",
        ""
    ]
    
    for row in data_list:
        values = []
        for key in ['id', 'device_id', 'name', 'parent_id', 'parent_device_id', 
                    'business_group', 'create_time', 'update_time', 'civil_code', 'alias']:
            value = row.get(key)
            if value is None:
                values.append('NULL')
            elif isinstance(value, (int, float)):
                values.append(str(value))
            else:
                # 转义单引号，确保UTF-8编码
                value_str = str(value).replace("'", "''").replace("\\", "\\\\")
                values.append(f"'{value_str}'")
        
        sql = f"INSERT INTO wvp_common_group (id, device_id, name, parent_id, parent_device_id, business_group, create_time, update_time, civil_code, alias) VALUES ({', '.join(values)});"
        sql_lines.append(sql)
    
    sql_lines.extend([
        "",
        "SET FOREIGN_KEY_CHECKS=1;"
    ])
    
    return '\n'.join(sql_lines)

def sync_to_remote(sql_content):
    """同步数据到远程数据库"""
    import subprocess
    
    # 创建临时SQL文件
    temp_file = f"/tmp/wvp_common_group_sync_{datetime.now().strftime('%Y%m%d_%H%M%S')}.sql"
    try:
        with open(temp_file, 'w', encoding='utf-8') as f:
            f.write(sql_content)
        
        print_colored(f"✓ SQL文件已生成: {temp_file}", 'green')
        
        # 传输文件到远程服务器
        print_colored("传输文件到远程服务器...", 'blue')
        scp_cmd = [
            'scp', '-o', 'StrictHostKeyChecking=no',
            temp_file,
            f'{REMOTE_USER}@{REMOTE_HOST}:/tmp/'
        ]
        
        # 使用expect处理密码
        expect_script = f'''
spawn {" ".join(scp_cmd)}
expect {{
    "password:" {{
        send "{REMOTE_PASSWORD}\\r"
        exp_continue
    }}
    eof
}}
'''
        
        result = subprocess.run(['expect', '-c', expect_script], 
                              capture_output=True, text=True)
        
        if result.returncode != 0:
            print_colored(f"✗ 文件传输失败: {result.stderr}", 'red')
            return False
        
        remote_file = f"/tmp/{os.path.basename(temp_file)}"
        print_colored(f"✓ 文件已传输到远程服务器", 'green')
        
        # 执行SQL导入（使用utf8mb4字符集）
        print_colored("导入数据到远程数据库...", 'blue')
        import_cmd = f'docker exec -i {REMOTE_DB_CONTAINER} mysql -u{REMOTE_DB_CONFIG["user"]} -p{REMOTE_DB_CONFIG["password"]} --default-character-set=utf8mb4 {REMOTE_DB_CONFIG["database"]} < {remote_file}'
        
        ssh_script = f'''
spawn ssh -o StrictHostKeyChecking=no {REMOTE_USER}@{REMOTE_HOST} "{import_cmd}"
expect {{
    "password:" {{
        send "{REMOTE_PASSWORD}\\r"
        exp_continue
    }}
    eof
}}
'''
        
        result = subprocess.run(['expect', '-c', ssh_script],
                              capture_output=True, text=True)
        
        if result.returncode != 0:
            print_colored(f"✗ 数据导入失败: {result.stderr}", 'red')
            return False
        
        print_colored("✓ 数据导入成功", 'green')
        
        # 清理远程文件
        cleanup_cmd = f'rm -f {remote_file}'
        cleanup_script = f'''
spawn ssh -o StrictHostKeyChecking=no {REMOTE_USER}@{REMOTE_HOST} "{cleanup_cmd}"
expect {{
    "password:" {{
        send "{REMOTE_PASSWORD}\\r"
        exp_continue
    }}
    eof
}}
'''
        subprocess.run(['expect', '-c', cleanup_script], capture_output=True)
        
        # 清理本地文件
        os.remove(temp_file)
        
        return True
        
    except Exception as e:
        print_colored(f"✗ 同步过程出错: {e}", 'red')
        if os.path.exists(temp_file):
            os.remove(temp_file)
        return False

def verify_remote_data():
    """验证远程数据"""
    import subprocess
    
    cmd = f'docker exec {REMOTE_DB_CONTAINER} mysql -u{REMOTE_DB_CONFIG["user"]} -p{REMOTE_DB_CONFIG["password"]} -D{REMOTE_DB_CONFIG["database"]} -sN -e "SELECT COUNT(*) FROM wvp_common_group;"'
    
    ssh_script = f'''
spawn ssh -o StrictHostKeyChecking=no {REMOTE_USER}@{REMOTE_HOST} "{cmd}"
expect {{
    "password:" {{
        send "{REMOTE_PASSWORD}\\r"
        exp_continue
    }}
    eof
}}
'''
    
    result = subprocess.run(['expect', '-c', ssh_script],
                          capture_output=True, text=True)
    
    if result.returncode == 0:
        count = result.stdout.strip().split('\n')[-1]
        try:
            return int(count)
        except:
            return None
    return None

def main():
    print_colored("=" * 40, 'green')
    print_colored("同步业务分组数据到远程数据库", 'green')
    print_colored("=" * 40, 'green')
    print()
    
    # 连接本地数据库
    print_colored("1. 连接本地数据库...", 'blue')
    local_conn = connect_local_db()
    if not local_conn:
        sys.exit(1)
    
    # 查询本地数据
    print_colored("2. 查询本地业务分组数据...", 'blue')
    local_data = query_local_data(local_conn)
    if local_data is None:
        local_conn.close()
        sys.exit(1)
    
    if len(local_data) == 0:
        print_colored("⚠ 本地数据库中没有业务分组数据", 'yellow')
        local_conn.close()
        sys.exit(0)
    
    print_colored(f"✓ 找到 {len(local_data)} 条业务分组记录", 'green')
    print()
    
    # 显示数据预览
    print_colored("3. 数据预览（前3条）:", 'blue')
    for i, row in enumerate(local_data[:3], 1):
        print(f"   [{i}] ID: {row.get('id')}, 名称: {row.get('name')}, 业务分组: {row.get('business_group')}")
    print()
    
    # 生成SQL
    print_colored("4. 生成SQL语句...", 'blue')
    sql_content = generate_sql(local_data)
    if not sql_content:
        print_colored("✗ SQL生成失败", 'red')
        local_conn.close()
        sys.exit(1)
    print_colored("✓ SQL生成成功", 'green')
    print()
    
    # 同步到远程
    print_colored("5. 同步数据到远程数据库...", 'blue')
    if not sync_to_remote(sql_content):
        local_conn.close()
        sys.exit(1)
    print()
    
    # 验证结果
    print_colored("6. 验证同步结果...", 'blue')
    remote_count = verify_remote_data()
    if remote_count is not None:
        print_colored(f"✓ 远程数据库记录数: {remote_count}", 'green')
        print_colored(f"  本地数据库记录数: {len(local_data)}", 'blue')
    else:
        print_colored("⚠ 无法验证远程数据", 'yellow')
    
    local_conn.close()
    
    print()
    print_colored("=" * 40, 'green')
    print_colored("同步完成！", 'green')
    print_colored("=" * 40, 'green')

if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print_colored("\n操作已取消", 'yellow')
        sys.exit(1)
    except Exception as e:
        print_colored(f"\n✗ 发生错误: {e}", 'red')
        import traceback
        traceback.print_exc()
        sys.exit(1)

