#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除WVP数据库中重复的媒体服务器记录
"""
import pymysql

# 数据库配置
DB_CONFIG = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': '123456',
    'database': 'wvp',
    'charset': 'utf8mb4'
}

def delete_media_server(server_id):
    """删除指定ID的媒体服务器记录"""
    try:
        # 连接数据库
        connection = pymysql.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        # 查询记录
        cursor.execute("SELECT id, ip, http_port FROM wvp_media_server WHERE id=%s", (server_id,))
        result = cursor.fetchone()
        
        if result:
            print(f"找到记录: ID={result[0]}, IP={result[1]}, Port={result[2]}")
            # 删除记录
            cursor.execute("DELETE FROM wvp_media_server WHERE id=%s", (server_id,))
            connection.commit()
            print(f"✓ 记录已删除: {server_id}")
        else:
            print(f"记录不存在: {server_id}")
        
        # 查询所有媒体服务器
        cursor.execute("SELECT id, ip, http_port FROM wvp_media_server")
        all_servers = cursor.fetchall()
        print(f"\n当前数据库中的媒体服务器 ({len(all_servers)}个):")
        for server in all_servers:
            print(f"  - ID: {server[0]}, IP: {server[1]}, Port: {server[2]}")
        
        cursor.close()
        connection.close()
        return True
        
    except Exception as e:
        print(f"错误: {e}")
        return False

if __name__ == '__main__':
    print("删除重复的媒体服务器记录...")
    delete_media_server('zlmediakit-local')
