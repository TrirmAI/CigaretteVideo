import requests
import hashlib
import os
import shutil

# Configuration
BASE_URL = "http://127.0.0.1:18080"
USERNAME = "admin"
PASSWORD = "admin"  # Assuming default password is admin, will need md5
SOURCE_FILE = "web/public/static/video/suspect-red-hat-1.mp4"
# Name format: Device_StartTime_EndTime.mp4
TARGET_FILENAME = "TestDevice_20230101120000_20230101130000.mp4"

def md5(text):
    return hashlib.md5(text.encode('utf-8')).hexdigest()

def test_api_upload():
    session = requests.Session()
    
    # 1. Login
    login_url = f"{BASE_URL}/api/user/login"
    # Password usually needs to be MD5 hashed for WVP
    password_md5 = md5(PASSWORD)
    
    print(f"Logging in to {login_url}...")
    try:
        # Try both form data and query params as WVP might support both
        # Changed to use params for GET request or data for POST if needed, but Controller uses @RequestParam which works with query params in GET
        # Using GET for simplicity as Controller supports both
        login_res = session.get(login_url, params={"username": USERNAME, "password": password_md5})
        
        if login_res.status_code != 200:
            print(f"Login failed: {login_res.status_code} - {login_res.text}")
            return
        
        login_data = login_res.json()
        print(f"Login Response Data: {login_data}")
        
        access_token = login_data.get('accessToken')
        if not access_token:
             # Try nested data structure
             data = login_data.get('data')
             if data and isinstance(data, dict):
                 access_token = data.get('accessToken')
        
        if not access_token:
             print("Login failed: No accessToken in response")
             return

        print(f"Login successful! Token: {access_token[:10]}...")
        
        # 2. Prepare File
        if not os.path.exists(SOURCE_FILE):
            print(f"Source file not found: {SOURCE_FILE}")
            return
            
        shutil.copy(SOURCE_FILE, TARGET_FILENAME)
        print(f"Prepared test file: {TARGET_FILENAME}")
        
        # 3. Upload
        upload_url = f"{BASE_URL}/api/recorder/upload"
        print(f"Uploading to {upload_url}...")
        
        headers = {'access-token': access_token}
        with open(TARGET_FILENAME, 'rb') as f:
            files = {'file': (TARGET_FILENAME, f, 'video/mp4')}
            upload_res = session.post(upload_url, files=files, headers=headers)
            
        print(f"Upload Response Code: {upload_res.status_code}")
        print(f"Upload Response Body: {upload_res.text}")
        
        if upload_res.status_code == 200:
            print("API Upload Test Passed!")
        else:
            print("API Upload Test Failed!")

    except Exception as e:
        print(f"Exception: {e}")
    finally:
        # Cleanup
        if os.path.exists(TARGET_FILENAME):
            os.remove(TARGET_FILENAME)

if __name__ == "__main__":
    test_api_upload()
