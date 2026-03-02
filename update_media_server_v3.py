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
            cursor.execute("SELECT id, ip, sdp_ip, stream_ip, hook_ip, http_port FROM wvp_media_server")
            results = cursor.fetchall()
            for row in results:
                print(f"Found: {row}")

            # Update all IPs to 192.168.1.101 as requested
            sql = """
            UPDATE wvp_media_server 
            SET ip = '192.168.1.101', 
                sdp_ip = '192.168.1.101', 
                stream_ip = '192.168.1.101',
                hook_ip = '192.168.1.101'
            WHERE id = 'polaris'
            """
            
            print(f"Executing update for id='polaris' to 192.168.1.101...")
            affected_rows = cursor.execute(sql)
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
