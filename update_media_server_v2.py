import pymysql

# Database config
config = {
    'host': '127.0.0.1',
    'port': 3306,
    'user': 'root',
    'password': 'root',
    'database': 'wvp',
    'charset': 'utf8mb4',
    'cursorclass': pymysql.cursors.DictCursor
}

def update_media_server():
    try:
        connection = pymysql.connect(**config)
        with connection.cursor() as cursor:
            # Check current state
            print("Checking current media server config...")
            cursor.execute("SELECT id, ip, sdp_ip, stream_ip, http_port FROM wvp_media_server")
            results = cursor.fetchall()
            for row in results:
                print(f"Found: {row}")

            # Update
            # ip: WVP连接ZLM的IP (保持内网IP 172.31.127.42 或 127.0.0.1，这里用127.0.0.1确保稳定)
            # sdp_ip: 摄像头推流的目标IP (外部IP 192.168.1.101)
            # stream_ip: 前端播放的流地址IP (外部IP 192.168.1.101)
            sql = """
            UPDATE wvp_media_server 
            SET ip = '127.0.0.1', 
                sdp_ip = '192.168.1.101', 
                stream_ip = '192.168.1.101',
                hook_ip = '192.168.1.101'
            WHERE id = 'polaris'
            """
            # 注意：hook_ip 是 ZLM 回调 WVP 的 IP。如果 ZLM 和 WVP 在同一台机器，也可以是 127.0.0.1。
            # 但如果 ZLM 在容器里，WVP 在宿主机，或者反过来，需要确保 ZLM 能访问到 WVP。
            # 假设都在本机，用 127.0.0.1 或 172.31.127.42 比较安全。
            # 不过根据之前的日志，ZLM 试图回调时可能会用到这个 IP。
            # 既然都在本机，hook_ip 设为 127.0.0.1 最稳妥。
            
            sql_safe = """
            UPDATE wvp_media_server 
            SET ip = '127.0.0.1', 
                sdp_ip = '192.168.1.101', 
                stream_ip = '192.168.1.101',
                hook_ip = '127.0.0.1'
            WHERE id = 'polaris'
            """
            
            print(f"Executing update for id='polaris'...")
            affected_rows = cursor.execute(sql_safe)
            print(f"Updated {affected_rows} rows.")
            
            connection.commit()
            
            # Verify update
            cursor.execute("SELECT id, ip, sdp_ip, stream_ip, hook_ip, http_port FROM wvp_media_server WHERE id = 'polaris'")
            result = cursor.fetchone()
            print(f"New Config: {result}")

    except Exception as e:
        print(f"Error: {e}")
    finally:
        if 'connection' in locals() and connection.open:
            connection.close()

if __name__ == "__main__":
    update_media_server()
