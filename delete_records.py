#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
删除WVP数据库中的所有录像记录
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

def delete_all_records():
    """删除所有录像记录"""
    try:
        # 连接数据库
        connection = pymysql.connect(**DB_CONFIG)
        cursor = connection.cursor()
        
        # 查询wvp_cloud_record表中的记录数
        cursor.execute("SELECT COUNT(*) FROM wvp_cloud_record")
        count_before = cursor.fetchone()[0]
        print(f"删除前 wvp_cloud_record 表记录数: {count_before}")
        
        if count_before > 0:
            # 显示前几条记录
            cursor.execute("SELECT id, app, stream, media_server_id, file_path FROM wvp_cloud_record LIMIT 5")
            records = cursor.fetchall()
            print("\n前5条记录:")
            for record in records:
                print(f"  - ID: {record[0]}, App: {record[1]}, Stream: {record[2]}, MediaServer: {record[3]}, Path: {record[4]}")
        
        # 删除所有记录
        cursor.execute("DELETE FROM wvp_cloud_record")
        deleted_count = cursor.rowcount
        connection.commit()
        print(f"\n✓ 删除了 {deleted_count} 条录像记录")
        
        # 验证删除结果
        cursor.execute("SELECT COUNT(*) FROM wvp_cloud_record")
        count_after = cursor.fetchone()[0]
        print(f"删除后 wvp_cloud_record 表记录数: {count_after}")
        
        cursor.close()
        connection.close()
        print("\n✓ 录像记录删除完成")
        return True
        
    except Exception as e:
        print(f"错误: {e}")
        import traceback
        traceback.print_exc()
        return False

if __name__ == '__main__':
    print("删除数据库中的所有录像记录...")
    print("=" * 50)
    delete_all_records()
